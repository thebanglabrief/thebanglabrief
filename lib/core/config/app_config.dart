/// App Configuration Constants
/// 
/// This file contains all the configuration constants for The Bangla Brief app.
/// Includes API keys, channel information, and app-wide settings.
class AppConfig {
  // App Information
  static const String appName = 'The Bangla Brief';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // YouTube Channel Information
  static const String channelName = 'The Bangla Brief';
  static const String channelId = 'UC0uUj0_ZJwB402cBWqWW86g';
  static const String youtubeApiKey = 'AIzaSyB810n5djmNO1dz-HsPDe8L5Sbv4XIYD4E';
  
  // Social Media Links
  static const String facebookPageUrl = 'https://www.facebook.com/share/1A73WndqWH/';
  static const String youtubeChannelUrl = 'https://www.youtube.com/channel/$channelId';
  
  // API Endpoints
  static const String youtubeApiBaseUrl = 'https://www.googleapis.com/youtube/v3';
  static const String youtubeApiSearchUrl = '$youtubeApiBaseUrl/search';
  static const String youtubeApiChannelUrl = '$youtubeApiBaseUrl/channels';
  static const String youtubeApiVideosUrl = '$youtubeApiBaseUrl/videos';
  static const String youtubeApiPlaylistUrl = '$youtubeApiBaseUrl/playlistItems';
  
  // Performance Constants
  static const int maxAppSizeMB = 50;
  static const int appLaunchTimeoutSeconds = 3;
  static const int videoLoadTimeoutSeconds = 5;
  static const int apiRequestTimeoutSeconds = 10;
  
  // Pagination & Limits
  static const int videosPerPage = 20;
  static const int blogsPerPage = 15;
  static const int commentsPerPage = 25;
  static const int chatMessagesPerPage = 50;
  static const int maxImageUploadSizeMB = 5;
  static const int maxVideoThumbnailSize = 480; // Width in pixels
  
  // Cache Settings
  static const int videoCacheDurationHours = 6;
  static const int analyticsCacheDurationMinutes = 30;
  static const int blogCacheDurationHours = 24;
  static const int maxCacheSizeMB = 100;
  
  // Refresh Intervals
  static const int subscriberCountRefreshSeconds = 30;
  static const int analyticsRefreshMinutes = 5;
  static const int chatRefreshSeconds = 2;
  
  // Authentication
  static const String adminUsername = 'arif';
  static const String adminPassword = 'arif2000';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String blogsCollection = 'blogs';
  static const String commentsCollection = 'comments';
  static const String forumPostsCollection = 'forum_posts';
  static const String forumRepliesCollection = 'forum_replies';
  static const String chatMessagesCollection = 'chat_messages';
  static const String analyticsCollection = 'analytics';
  static const String reportsCollection = 'reports';
  
  // Hive Boxes
  static const String videosBox = 'videos';
  static const String blogsBox = 'blogs';
  static const String userPrefsBox = 'user_preferences';
  static const String cacheBox = 'cache';
  static const String analyticsBox = 'analytics';
  
  // Error Messages
  static const String noInternetMessage = 'No internet connection. Please check your connection and try again.';
  static const String genericErrorMessage = 'Something went wrong. Please try again later.';
  static const String videoLoadErrorMessage = 'Failed to load video. Please try again.';
  static const String apiQuotaExceededMessage = 'Service temporarily unavailable. Please try again later.';
  
  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  
  // YouTube API Quota Management
  static const int dailyQuotaLimit = 10000;
  static const int quotaPerSearchRequest = 100;
  static const int quotaPerVideoRequest = 1;
  static const int quotaPerChannelRequest = 1;
  
  // UI Constants
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // Animation Durations
  static const int shortAnimationMs = 200;
  static const int mediumAnimationMs = 300;
  static const int longAnimationMs = 500;
  
  // Environment Detection
  static bool get isDebug {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
  
  static bool get isRelease => !isDebug;
  
  // Platform Compatibility
  static const int minAndroidSdk = 21; // Android 5.0
  static const String miniOSVersion = '12.0'; // iOS 12.0
  
  // Content Guidelines
  static const int maxBlogTitleLength = 100;
  static const int maxBlogContentLength = 10000;
  static const int maxCommentLength = 500;
  static const int maxForumPostTitleLength = 150;
  static const int maxForumPostContentLength = 5000;
  static const int maxChatMessageLength = 300;
  
  // Profanity Filter
  static const List<String> profanityWords = [
    // Add common profanity words for filtering
    // This is a basic list - in production, use a comprehensive profanity filter service
  ];
  
  // File Upload Settings
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedVideoFormats = ['mp4', 'mov', 'avi'];
  static const int imageCompressionQuality = 85;
  
  // Deep Links
  static const String appScheme = 'banglabbrief';
  static const String webDomain = 'thebanglabbrief.com';
  
  // Privacy & GDPR
  static const String privacyPolicyUrl = 'https://thebanglabbrief.com/privacy';
  static const String termsOfServiceUrl = 'https://thebanglabbrief.com/terms';
  static const int dataRetentionDays = 365;
}