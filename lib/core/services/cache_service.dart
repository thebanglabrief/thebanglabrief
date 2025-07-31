import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';

/// Cache Service
/// 
/// Provides local storage and caching functionality using Hive.
/// Handles data persistence, expiration, and automatic cleanup.
class CacheService extends GetxService {
  static CacheService get instance => Get.find<CacheService>();
  
  // Hive boxes
  late Box<dynamic> _cacheBox;
  late Box<dynamic> _userPrefsBox;
  late Box<dynamic> _videosBox;
  late Box<dynamic> _blogsBox;
  late Box<dynamic> _analyticsBox;
  
  // Cache statistics
  final RxInt _cacheSize = 0.obs;
  final RxInt _itemCount = 0.obs;
  
  // Getters
  int get cacheSize => _cacheSize.value;
  int get itemCount => _itemCount.value;
  
  @override
  Future<CacheService> init() async {
    try {
      AppLogger.info('Initializing Cache Service');
      
      // Initialize Hive boxes
      await _initializeBoxes();
      
      // Set up automatic cleanup
      _setupAutomaticCleanup();
      
      // Update cache statistics
      _updateCacheStats();
      
      AppLogger.info('Cache Service initialized successfully');
      return this;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to initialize Cache Service', error, stackTrace);
      rethrow;
    }
  }
  
  /// Initialize Hive boxes
  Future<void> _initializeBoxes() async {
    try {
      // Open cache boxes
      _cacheBox = await Hive.openBox(AppConfig.cacheBox);
      _userPrefsBox = await Hive.openBox(AppConfig.userPrefsBox);
      _videosBox = await Hive.openBox(AppConfig.videosBox);
      _blogsBox = await Hive.openBox(AppConfig.blogsBox);
      _analyticsBox = await Hive.openBox(AppConfig.analyticsBox);
      
      AppLogger.info('Hive boxes initialized');
    } catch (error, stackTrace) {
      AppLogger.error('Failed to initialize Hive boxes', error, stackTrace);
      rethrow;
    }
  }
  
  /// Set up automatic cleanup timer
  void _setupAutomaticCleanup() {
    // Clean up expired items every hour
    Timer.periodic(const Duration(hours: 1), (timer) {
      _cleanupExpiredItems();
    });
  }
  
  /// Update cache statistics
  void _updateCacheStats() {
    try {
      int totalItems = 0;
      int totalSize = 0;
      
      final boxes = [_cacheBox, _videosBox, _blogsBox, _analyticsBox];
      
      for (final box in boxes) {
        totalItems += box.length;
        
        for (final value in box.values) {
          if (value is String) {
            totalSize += value.length;
          } else if (value is Map) {
            totalSize += jsonEncode(value).length;
          }
        }
      }
      
      _itemCount.value = totalItems;
      _cacheSize.value = totalSize;
      
      AppLogger.cache('Cache stats updated', 'Items: $totalItems, Size: ${_formatBytes(totalSize)}');
    } catch (error, stackTrace) {
      AppLogger.error('Failed to update cache stats', error, stackTrace);
    }
  }
  
  /// Generic cache operations
  
  /// Store data in cache with optional expiration
  Future<void> put(String key, dynamic value, {Duration? expiration}) async {
    try {
      final cacheItem = CacheItem(
        value: value,
        timestamp: DateTime.now(),
        expiration: expiration,
      );
      
      await _cacheBox.put(key, cacheItem.toMap());
      AppLogger.cache('Put', key, true);
      _updateCacheStats();
    } catch (error, stackTrace) {
      AppLogger.error('Failed to cache item: $key', error, stackTrace);
    }
  }
  
  /// Get data from cache
  T? get<T>(String key) {
    try {
      final data = _cacheBox.get(key);
      if (data == null) return null;
      
      final cacheItem = CacheItem.fromMap(Map<String, dynamic>.from(data));
      
      // Check if expired
      if (cacheItem.isExpired) {
        _cacheBox.delete(key);
        AppLogger.cache('Get (expired)', key, false);
        return null;
      }
      
      AppLogger.cache('Get', key, true);
      return cacheItem.value as T?;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to get cached item: $key', error, stackTrace);
      return null;
    }
  }
  
  /// Remove item from cache
  Future<void> remove(String key) async {
    try {
      await _cacheBox.delete(key);
      AppLogger.cache('Remove', key, true);
      _updateCacheStats();
    } catch (error, stackTrace) {
      AppLogger.error('Failed to remove cached item: $key', error, stackTrace);
    }
  }
  
  /// Check if key exists in cache
  bool contains(String key) {
    try {
      final data = _cacheBox.get(key);
      if (data == null) return false;
      
      final cacheItem = CacheItem.fromMap(Map<String, dynamic>.from(data));
      return !cacheItem.isExpired;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to check cache for key: $key', error, stackTrace);
      return false;
    }
  }
  
  /// Clear all cache
  Future<void> clear() async {
    try {
      await _cacheBox.clear();
      AppLogger.info('Cache cleared');
      _updateCacheStats();
    } catch (error, stackTrace) {
      AppLogger.error('Failed to clear cache', error, stackTrace);
    }
  }
  
  /// User preferences operations
  
  /// Store user preference
  Future<void> setUserPref(String key, dynamic value) async {
    try {
      await _userPrefsBox.put(key, value);
      AppLogger.debug('User pref set: $key');
    } catch (error, stackTrace) {
      AppLogger.error('Failed to set user preference: $key', error, stackTrace);
    }
  }
  
  /// Get user preference
  T? getUserPref<T>(String key, [T? defaultValue]) {
    try {
      final value = _userPrefsBox.get(key, defaultValue: defaultValue);
      return value as T?;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to get user preference: $key', error, stackTrace);
      return defaultValue;
    }
  }
  
  /// Remove user preference
  Future<void> removeUserPref(String key) async {
    try {
      await _userPrefsBox.delete(key);
      AppLogger.debug('User pref removed: $key');
    } catch (error, stackTrace) {
      AppLogger.error('Failed to remove user preference: $key', error, stackTrace);
    }
  }
  
  /// Video cache operations
  
  /// Cache video data
  Future<void> cacheVideo(String videoId, Map<String, dynamic> videoData) async {
    try {
      final cacheItem = CacheItem(
        value: videoData,
        timestamp: DateTime.now(),
        expiration: Duration(hours: AppConfig.videoCacheDurationHours),
      );
      
      await _videosBox.put(videoId, cacheItem.toMap());
      AppLogger.cache('Video cached', videoId, true);
      _updateCacheStats();
    } catch (error, stackTrace) {
      AppLogger.error('Failed to cache video: $videoId', error, stackTrace);
    }
  }
  
  /// Get cached video
  Map<String, dynamic>? getCachedVideo(String videoId) {
    try {
      final data = _videosBox.get(videoId);
      if (data == null) return null;
      
      final cacheItem = CacheItem.fromMap(Map<String, dynamic>.from(data));
      
      if (cacheItem.isExpired) {
        _videosBox.delete(videoId);
        return null;
      }
      
      return Map<String, dynamic>.from(cacheItem.value);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to get cached video: $videoId', error, stackTrace);
      return null;
    }
  }
  
  /// Cache video list
  Future<void> cacheVideoList(String key, List<Map<String, dynamic>> videos) async {
    try {
      final cacheItem = CacheItem(
        value: videos,
        timestamp: DateTime.now(),
        expiration: Duration(hours: AppConfig.videoCacheDurationHours),
      );
      
      await _videosBox.put(key, cacheItem.toMap());
      AppLogger.cache('Video list cached', key, true);
      _updateCacheStats();
    } catch (error, stackTrace) {
      AppLogger.error('Failed to cache video list: $key', error, stackTrace);
    }
  }
  
  /// Get cached video list
  List<Map<String, dynamic>>? getCachedVideoList(String key) {
    try {
      final data = _videosBox.get(key);
      if (data == null) return null;
      
      final cacheItem = CacheItem.fromMap(Map<String, dynamic>.from(data));
      
      if (cacheItem.isExpired) {
        _videosBox.delete(key);
        return null;
      }
      
      return List<Map<String, dynamic>>.from(cacheItem.value);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to get cached video list: $key', error, stackTrace);
      return null;
    }
  }
  
  /// Blog cache operations
  
  /// Cache blog post
  Future<void> cacheBlog(String blogId, Map<String, dynamic> blogData) async {
    try {
      final cacheItem = CacheItem(
        value: blogData,
        timestamp: DateTime.now(),
        expiration: Duration(hours: AppConfig.blogCacheDurationHours),
      );
      
      await _blogsBox.put(blogId, cacheItem.toMap());
      AppLogger.cache('Blog cached', blogId, true);
      _updateCacheStats();
    } catch (error, stackTrace) {
      AppLogger.error('Failed to cache blog: $blogId', error, stackTrace);
    }
  }
  
  /// Get cached blog
  Map<String, dynamic>? getCachedBlog(String blogId) {
    try {
      final data = _blogsBox.get(blogId);
      if (data == null) return null;
      
      final cacheItem = CacheItem.fromMap(Map<String, dynamic>.from(data));
      
      if (cacheItem.isExpired) {
        _blogsBox.delete(blogId);
        return null;
      }
      
      return Map<String, dynamic>.from(cacheItem.value);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to get cached blog: $blogId', error, stackTrace);
      return null;
    }
  }
  
  /// Analytics cache operations
  
  /// Cache analytics data
  Future<void> cacheAnalytics(String key, Map<String, dynamic> analyticsData) async {
    try {
      final cacheItem = CacheItem(
        value: analyticsData,
        timestamp: DateTime.now(),
        expiration: Duration(minutes: AppConfig.analyticsCacheDurationMinutes),
      );
      
      await _analyticsBox.put(key, cacheItem.toMap());
      AppLogger.cache('Analytics cached', key, true);
      _updateCacheStats();
    } catch (error, stackTrace) {
      AppLogger.error('Failed to cache analytics: $key', error, stackTrace);
    }
  }
  
  /// Get cached analytics
  Map<String, dynamic>? getCachedAnalytics(String key) {
    try {
      final data = _analyticsBox.get(key);
      if (data == null) return null;
      
      final cacheItem = CacheItem.fromMap(Map<String, dynamic>.from(data));
      
      if (cacheItem.isExpired) {
        _analyticsBox.delete(key);
        return null;
      }
      
      return Map<String, dynamic>.from(cacheItem.value);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to get cached analytics: $key', error, stackTrace);
      return null;
    }
  }
  
  /// Cleanup operations
  
  /// Clean up expired items
  Future<void> _cleanupExpiredItems() async {
    try {
      int deletedCount = 0;
      final boxes = [_cacheBox, _videosBox, _blogsBox, _analyticsBox];
      
      for (final box in boxes) {
        final keysToDelete = <String>[];
        
        for (final key in box.keys) {
          final data = box.get(key);
          if (data is Map) {
            final cacheItem = CacheItem.fromMap(Map<String, dynamic>.from(data));
            if (cacheItem.isExpired) {
              keysToDelete.add(key.toString());
            }
          }
        }
        
        for (final key in keysToDelete) {
          await box.delete(key);
          deletedCount++;
        }
      }
      
      if (deletedCount > 0) {
        AppLogger.info('Cleaned up $deletedCount expired cache items');
        _updateCacheStats();
      }
    } catch (error, stackTrace) {
      AppLogger.error('Failed to cleanup expired items', error, stackTrace);
    }
  }
  
  /// Clean up cache if size exceeds limit
  Future<void> cleanupBySize() async {
    try {
      final maxSizeBytes = AppConfig.maxCacheSizeMB * 1024 * 1024;
      
      if (_cacheSize.value > maxSizeBytes) {
        // Remove oldest items until under limit
        final allItems = <CacheItemWithKey>[];
        
        // Collect all items with their keys and timestamps
        for (final box in [_cacheBox, _videosBox, _blogsBox, _analyticsBox]) {
          for (final key in box.keys) {
            final data = box.get(key);
            if (data is Map) {
              final cacheItem = CacheItem.fromMap(Map<String, dynamic>.from(data));
              allItems.add(CacheItemWithKey(
                key: key.toString(),
                cacheItem: cacheItem,
                box: box,
              ));
            }
          }
        }
        
        // Sort by timestamp (oldest first)
        allItems.sort((a, b) => a.cacheItem.timestamp.compareTo(b.cacheItem.timestamp));
        
        // Remove items until under size limit
        int removedCount = 0;
        for (final item in allItems) {
          await item.box.delete(item.key);
          removedCount++;
          
          _updateCacheStats();
          if (_cacheSize.value <= maxSizeBytes) break;
        }
        
        AppLogger.info('Removed $removedCount items to reduce cache size');
      }
    } catch (error, stackTrace) {
      AppLogger.error('Failed to cleanup cache by size', error, stackTrace);
    }
  }
  
  /// Get cache info
  Map<String, dynamic> getCacheInfo() {
    return {
      'totalItems': _itemCount.value,
      'totalSize': _cacheSize.value,
      'formattedSize': _formatBytes(_cacheSize.value),
      'boxes': {
        'cache': _cacheBox.length,
        'videos': _videosBox.length,
        'blogs': _blogsBox.length,
        'analytics': _analyticsBox.length,
        'userPrefs': _userPrefsBox.length,
      },
    };
  }
  
  /// Format bytes to human readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Cache item model with expiration support
class CacheItem {
  final dynamic value;
  final DateTime timestamp;
  final Duration? expiration;
  
  CacheItem({
    required this.value,
    required this.timestamp,
    this.expiration,
  });
  
  bool get isExpired {
    if (expiration == null) return false;
    return DateTime.now().isAfter(timestamp.add(expiration!));
  }
  
  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'expiration': expiration?.inMilliseconds,
    };
  }
  
  factory CacheItem.fromMap(Map<String, dynamic> map) {
    return CacheItem(
      value: map['value'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      expiration: map['expiration'] != null 
          ? Duration(milliseconds: map['expiration']) 
          : null,
    );
  }
}

/// Helper class for cache cleanup
class CacheItemWithKey {
  final String key;
  final CacheItem cacheItem;
  final Box box;
  
  CacheItemWithKey({
    required this.key,
    required this.cacheItem,
    required this.box,
  });
}

