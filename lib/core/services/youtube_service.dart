import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';
import 'cache_service.dart';
import 'network_service.dart';

/// YouTube API Service
/// 
/// Handles all YouTube Data API v3 interactions including video fetching,
/// channel statistics, quota management, and response caching.
class YouTubeService extends GetxService {
  static YouTubeService get instance => Get.find<YouTubeService>();
  
  // Services
  late final CacheService _cacheService;
  late final NetworkService _networkService;
  late final Dio _dio;
  
  // API Quota tracking
  final RxInt _dailyQuotaUsed = 0.obs;
  final RxBool _quotaExceeded = false.obs;
  
  // Getters
  int get dailyQuotaUsed => _dailyQuotaUsed.value;
  bool get quotaExceeded => _quotaExceeded.value;
  int get remainingQuota => AppConfig.dailyQuotaLimit - _dailyQuotaUsed.value;
  
  @override
  Future<YouTubeService> init() async {
    try {
      AppLogger.info('Initializing YouTube Service');
      
      _cacheService = CacheService.instance;
      _networkService = NetworkService.instance;
      _setupDio();
      _loadQuotaUsage();
      
      AppLogger.info('YouTube Service initialized successfully');
      return this;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to initialize YouTube Service', error, stackTrace);
      rethrow;
    }
  }
  
  /// Set up Dio HTTP client
  void _setupDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.youtubeApiBaseUrl,
      connectTimeout: Duration(seconds: AppConfig.apiRequestTimeoutSeconds),
      receiveTimeout: Duration(seconds: AppConfig.apiRequestTimeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Add interceptors
    _dio.interceptors.add(LogInterceptor(
      requestBody: AppConfig.isDebug,
      responseBody: AppConfig.isDebug,
      logPrint: (object) => AppLogger.debug(object.toString()),
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        AppLogger.apiRequest(options.method, options.uri.toString(), options.data);
        handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.apiResponse(response.requestOptions.uri.toString(), response.statusCode ?? 0, response.data);
        handler.next(response);
      },
      onError: (error, handler) {
        AppLogger.error('YouTube API Error: ${error.message}', error);
        handler.next(error);
      },
    ));
  }
  
  /// Load quota usage from cache
  void _loadQuotaUsage() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    _dailyQuotaUsed.value = _cacheService.getUserPref<int>('quota_used_$today', 0);
    _quotaExceeded.value = _dailyQuotaUsed.value >= AppConfig.dailyQuotaLimit;
  }
  
  /// Update quota usage
  void _updateQuotaUsage(int quotaCost) {
    _dailyQuotaUsed.value += quotaCost;
    _quotaExceeded.value = _dailyQuotaUsed.value >= AppConfig.dailyQuotaLimit;
    
    final today = DateTime.now().toIso8601String().split('T')[0];
    _cacheService.setUserPref('quota_used_$today', _dailyQuotaUsed.value);
    
    AppLogger.info('Quota updated: ${_dailyQuotaUsed.value}/${AppConfig.dailyQuotaLimit}');
  }
  
  /// Check if we can make an API request
  bool _canMakeRequest(int quotaCost) {
    if (!_networkService.isConnected) {
      AppLogger.warning('No internet connection for YouTube API request');
      return false;
    }
    
    if (_dailyQuotaUsed.value + quotaCost > AppConfig.dailyQuotaLimit) {
      AppLogger.warning('YouTube API quota would be exceeded');
      _quotaExceeded.value = true;
      return false;
    }
    
    return true;
  }
  
  /// Get channel videos
  Future<YouTubeVideoListResponse> getChannelVideos({
    String? pageToken,
    int maxResults = 20,
    bool excludeShorts = true,
  }) async {
    try {
      final cacheKey = 'channel_videos_${pageToken ?? 'first'}_$maxResults';
      
      // Try to get from cache first
      final cachedData = _cacheService.getCachedVideoList(cacheKey);
      if (cachedData != null) {
        AppLogger.cache('Get channel videos from cache', cacheKey, true);
        return YouTubeVideoListResponse.fromCachedData(cachedData);
      }
      
      // Check quota before making request
      if (!_canMakeRequest(AppConfig.quotaPerSearchRequest)) {
        throw YouTubeApiException('API quota exceeded or no internet connection');
      }
      
      // Search for videos in the channel
      final searchResponse = await _dio.get('/search', queryParameters: {
        'key': AppConfig.youtubeApiKey,
        'channelId': AppConfig.channelId,
        'part': 'id,snippet',
        'type': 'video',
        'order': 'date',
        'maxResults': maxResults,
        if (pageToken != null) 'pageToken': pageToken,
      });
      
      _updateQuotaUsage(AppConfig.quotaPerSearchRequest);
      
      final searchData = searchResponse.data;
      final videoIds = <String>[];
      
      for (final item in searchData['items']) {
        final videoId = item['id']['videoId'];
        if (excludeShorts && await _isYouTubeShort(videoId)) {
          continue; // Skip YouTube Shorts
        }
        videoIds.add(videoId);
      }
      
      if (videoIds.isEmpty) {
        return YouTubeVideoListResponse(
          videos: [],
          nextPageToken: searchData['nextPageToken'],
          totalResults: searchData['pageInfo']['totalResults'],
        );
      }
      
      // Get detailed video information
      final videosResponse = await _dio.get('/videos', queryParameters: {
        'key': AppConfig.youtubeApiKey,
        'id': videoIds.join(','),
        'part': 'id,snippet,statistics,contentDetails',
      });
      
      _updateQuotaUsage(AppConfig.quotaPerVideoRequest);
      
      final videosData = videosResponse.data;
      final videos = <YouTubeVideo>[];
      
      for (final item in videosData['items']) {
        videos.add(YouTubeVideo.fromJson(item));
      }
      
      final response = YouTubeVideoListResponse(
        videos: videos,
        nextPageToken: searchData['nextPageToken'],
        totalResults: searchData['pageInfo']['totalResults'],
      );
      
      // Cache the response
      await _cacheService.cacheVideoList(cacheKey, response.toCacheData());
      
      AppLogger.info('Fetched ${videos.length} videos from YouTube API');
      return response;
      
    } on DioException catch (e) {
      AppLogger.error('YouTube API DioException', e);
      throw YouTubeApiException(_handleDioError(e));
    } catch (error, stackTrace) {
      AppLogger.error('YouTube API Error', error, stackTrace);
      throw YouTubeApiException('Failed to fetch videos: ${error.toString()}');
    }
  }
  
  /// Get channel statistics
  Future<YouTubeChannelStats> getChannelStats() async {
    try {
      const cacheKey = 'channel_stats';
      
      // Try to get from cache first
      final cachedData = _cacheService.getCachedAnalytics(cacheKey);
      if (cachedData != null) {
        AppLogger.cache('Get channel stats from cache', cacheKey, true);
        return YouTubeChannelStats.fromJson(cachedData);
      }
      
      // Check quota before making request
      if (!_canMakeRequest(AppConfig.quotaPerChannelRequest)) {
        throw YouTubeApiException('API quota exceeded or no internet connection');
      }
      
      final response = await _dio.get('/channels', queryParameters: {
        'key': AppConfig.youtubeApiKey,
        'id': AppConfig.channelId,
        'part': 'statistics,snippet',
      });
      
      _updateQuotaUsage(AppConfig.quotaPerChannelRequest);
      
      final data = response.data;
      if (data['items'] == null || data['items'].isEmpty) {
        throw YouTubeApiException('Channel not found');
      }
      
      final channelData = data['items'][0];
      final stats = YouTubeChannelStats.fromJson(channelData);
      
      // Cache the stats
      await _cacheService.cacheAnalytics(cacheKey, stats.toJson());
      
      AppLogger.info('Fetched channel statistics');
      return stats;
      
    } on DioException catch (e) {
      AppLogger.error('YouTube Channel Stats DioException', e);
      throw YouTubeApiException(_handleDioError(e));
    } catch (error, stackTrace) {
      AppLogger.error('YouTube Channel Stats Error', error, stackTrace);
      throw YouTubeApiException('Failed to fetch channel stats: ${error.toString()}');
    }
  }
  
  /// Get single video details
  Future<YouTubeVideo?> getVideoDetails(String videoId) async {
    try {
      // Try to get from cache first
      final cachedData = _cacheService.getCachedVideo(videoId);
      if (cachedData != null) {
        AppLogger.cache('Get video details from cache', videoId, true);
        return YouTubeVideo.fromJson(cachedData);
      }
      
      // Check quota before making request
      if (!_canMakeRequest(AppConfig.quotaPerVideoRequest)) {
        throw YouTubeApiException('API quota exceeded or no internet connection');
      }
      
      final response = await _dio.get('/videos', queryParameters: {
        'key': AppConfig.youtubeApiKey,
        'id': videoId,
        'part': 'id,snippet,statistics,contentDetails',
      });
      
      _updateQuotaUsage(AppConfig.quotaPerVideoRequest);
      
      final data = response.data;
      if (data['items'] == null || data['items'].isEmpty) {
        return null;
      }
      
      final video = YouTubeVideo.fromJson(data['items'][0]);
      
      // Cache the video
      await _cacheService.cacheVideo(videoId, video.toJson());
      
      AppLogger.info('Fetched video details for: $videoId');
      return video;
      
    } on DioException catch (e) {
      AppLogger.error('YouTube Video Details DioException', e);
      throw YouTubeApiException(_handleDioError(e));
    } catch (error, stackTrace) {
      AppLogger.error('YouTube Video Details Error', error, stackTrace);
      throw YouTubeApiException('Failed to fetch video details: ${error.toString()}');
    }
  }
  
  /// Check if video is a YouTube Short
  Future<bool> _isYouTubeShort(String videoId) async {
    try {
      final video = await getVideoDetails(videoId);
      if (video == null) return false;
      
      // YouTube Shorts are typically under 60 seconds
      return video.durationInSeconds <= 60;
    } catch (error) {
      AppLogger.warning('Failed to check if video is Short: $videoId');
      return false;
    }
  }
  
  /// Search videos in channel
  Future<YouTubeVideoListResponse> searchVideosInChannel({
    required String query,
    String? pageToken,
    int maxResults = 20,
  }) async {
    try {
      final cacheKey = 'search_${query.replaceAll(' ', '_')}_${pageToken ?? 'first'}_$maxResults';
      
      // Try to get from cache first
      final cachedData = _cacheService.getCachedVideoList(cacheKey);
      if (cachedData != null) {
        AppLogger.cache('Get search results from cache', cacheKey, true);
        return YouTubeVideoListResponse.fromCachedData(cachedData);
      }
      
      // Check quota before making request
      if (!_canMakeRequest(AppConfig.quotaPerSearchRequest)) {
        throw YouTubeApiException('API quota exceeded or no internet connection');
      }
      
      final response = await _dio.get('/search', queryParameters: {
        'key': AppConfig.youtubeApiKey,
        'channelId': AppConfig.channelId,
        'part': 'id,snippet',
        'type': 'video',
        'q': query,
        'order': 'relevance',
        'maxResults': maxResults,
        if (pageToken != null) 'pageToken': pageToken,
      });
      
      _updateQuotaUsage(AppConfig.quotaPerSearchRequest);
      
      final searchData = response.data;
      final videoIds = <String>[];
      
      for (final item in searchData['items']) {
        videoIds.add(item['id']['videoId']);
      }
      
      if (videoIds.isEmpty) {
        return YouTubeVideoListResponse(
          videos: [],
          nextPageToken: searchData['nextPageToken'],
          totalResults: searchData['pageInfo']['totalResults'],
        );
      }
      
      // Get detailed video information
      final videosResponse = await _dio.get('/videos', queryParameters: {
        'key': AppConfig.youtubeApiKey,
        'id': videoIds.join(','),
        'part': 'id,snippet,statistics,contentDetails',
      });
      
      _updateQuotaUsage(AppConfig.quotaPerVideoRequest);
      
      final videosData = videosResponse.data;
      final videos = <YouTubeVideo>[];
      
      for (final item in videosData['items']) {
        videos.add(YouTubeVideo.fromJson(item));
      }
      
      final searchResponse = YouTubeVideoListResponse(
        videos: videos,
        nextPageToken: searchData['nextPageToken'],
        totalResults: searchData['pageInfo']['totalResults'],
      );
      
      // Cache the response
      await _cacheService.cacheVideoList(cacheKey, searchResponse.toCacheData());
      
      AppLogger.info('Search found ${videos.length} videos for query: $query');
      return searchResponse;
      
    } on DioException catch (e) {
      AppLogger.error('YouTube Search DioException', e);
      throw YouTubeApiException(_handleDioError(e));
    } catch (error, stackTrace) {
      AppLogger.error('YouTube Search Error', error, stackTrace);
      throw YouTubeApiException('Failed to search videos: ${error.toString()}');
    }
  }
  
  /// Handle Dio errors and provide user-friendly messages
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 403:
            return AppConfig.apiQuotaExceededMessage;
          case 404:
            return 'Content not found.';
          case 500:
            return 'YouTube service is temporarily unavailable.';
          default:
            return 'Server error occurred. Please try again later.';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return AppConfig.noInternetMessage;
    }
  }
  
  /// Reset daily quota (should be called at midnight)
  void resetDailyQuota() {
    _dailyQuotaUsed.value = 0;
    _quotaExceeded.value = false;
    
    final today = DateTime.now().toIso8601String().split('T')[0];
    _cacheService.setUserPref('quota_used_$today', 0);
    
    AppLogger.info('Daily YouTube API quota reset');
  }
  
  /// Get quota usage percentage
  double get quotaUsagePercentage {
    return (_dailyQuotaUsed.value / AppConfig.dailyQuotaLimit) * 100;
  }
}

/// YouTube Video Model
class YouTubeVideo {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final DateTime publishedAt;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final String duration;
  final int durationInSeconds;
  final List<String> tags;
  
  const YouTubeVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.publishedAt,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.duration,
    required this.durationInSeconds,
    required this.tags,
  });
  
  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'];
    final statistics = json['statistics'];
    final contentDetails = json['contentDetails'];
    
    return YouTubeVideo(
      id: json['id'],
      title: snippet['title'] ?? '',
      description: snippet['description'] ?? '',
      thumbnailUrl: snippet['thumbnails']['high']['url'] ?? '',
      channelTitle: snippet['channelTitle'] ?? '',
      publishedAt: DateTime.parse(snippet['publishedAt']),
      viewCount: int.tryParse(statistics['viewCount'] ?? '0') ?? 0,
      likeCount: int.tryParse(statistics['likeCount'] ?? '0') ?? 0,
      commentCount: int.tryParse(statistics['commentCount'] ?? '0') ?? 0,
      duration: contentDetails['duration'] ?? '',
      durationInSeconds: _parseDuration(contentDetails['duration'] ?? ''),
      tags: List<String>.from(snippet['tags'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'channelTitle': channelTitle,
      'publishedAt': publishedAt.toIso8601String(),
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'duration': duration,
      'durationInSeconds': durationInSeconds,
      'tags': tags,
    };
  }
  
  /// Parse ISO 8601 duration to seconds
  static int _parseDuration(String duration) {
    if (duration.isEmpty) return 0;
    
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(duration);
    
    if (match == null) return 0;
    
    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
    
    return (hours * 3600) + (minutes * 60) + seconds;
  }
  
  /// Get formatted duration string
  String get formattedDuration {
    final hours = durationInSeconds ~/ 3600;
    final minutes = (durationInSeconds % 3600) ~/ 60;
    final seconds = durationInSeconds % 60;
    
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
  }
  
  /// Get formatted view count
  String get formattedViewCount {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M views';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K views';
    } else {
      return '$viewCount views';
    }
  }
}

/// YouTube Channel Statistics Model
class YouTubeChannelStats {
  final String channelId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final int subscriberCount;
  final int videoCount;
  final int viewCount;
  final DateTime fetchedAt;
  
  const YouTubeChannelStats({
    required this.channelId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.subscriberCount,
    required this.videoCount,
    required this.viewCount,
    required this.fetchedAt,
  });
  
  factory YouTubeChannelStats.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'];
    final statistics = json['statistics'];
    
    return YouTubeChannelStats(
      channelId: json['id'],
      title: snippet['title'] ?? '',
      description: snippet['description'] ?? '',
      thumbnailUrl: snippet['thumbnails']['high']['url'] ?? '',
      subscriberCount: int.tryParse(statistics['subscriberCount'] ?? '0') ?? 0,
      videoCount: int.tryParse(statistics['videoCount'] ?? '0') ?? 0,
      viewCount: int.tryParse(statistics['viewCount'] ?? '0') ?? 0,
      fetchedAt: DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'subscriberCount': subscriberCount,
      'videoCount': videoCount,
      'viewCount': viewCount,
      'fetchedAt': fetchedAt.toIso8601String(),
    };
  }
  
  /// Get formatted subscriber count
  String get formattedSubscriberCount {
    if (subscriberCount >= 1000000) {
      return '${(subscriberCount / 1000000).toStringAsFixed(1)}M subscribers';
    } else if (subscriberCount >= 1000) {
      return '${(subscriberCount / 1000).toStringAsFixed(1)}K subscribers';
    } else {
      return '$subscriberCount subscribers';
    }
  }
}

/// YouTube Video List Response Model
class YouTubeVideoListResponse {
  final List<YouTubeVideo> videos;
  final String? nextPageToken;
  final int totalResults;
  
  const YouTubeVideoListResponse({
    required this.videos,
    this.nextPageToken,
    required this.totalResults,
  });
  
  factory YouTubeVideoListResponse.fromCachedData(List<Map<String, dynamic>> cachedData) {
    return YouTubeVideoListResponse(
      videos: cachedData.map((data) => YouTubeVideo.fromJson(data['video'])).toList(),
      nextPageToken: cachedData.isNotEmpty ? cachedData.first['nextPageToken'] : null,
      totalResults: cachedData.isNotEmpty ? cachedData.first['totalResults'] ?? 0 : 0,
    );
  }
  
  List<Map<String, dynamic>> toCacheData() {
    return videos.map((video) => {
      'video': video.toJson(),
      'nextPageToken': nextPageToken,
      'totalResults': totalResults,
    }).toList();
  }
}

/// YouTube API Exception
class YouTubeApiException implements Exception {
  final String message;
  
  const YouTubeApiException(this.message);
  
  @override
  String toString() => 'YouTubeApiException: $message';
}

