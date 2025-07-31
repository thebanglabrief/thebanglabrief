import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';

/// Notification Service
/// 
/// Handles Firebase Cloud Messaging (FCM) and local notifications.
/// Manages notification permissions, tokens, and message handling.
class NotificationService extends GetxService {
  static NotificationService get instance => Get.find<NotificationService>();
  
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Reactive state
  final RxString _fcmToken = ''.obs;
  final RxBool _notificationsEnabled = false.obs;
  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs;
  
  // Getters
  String get fcmToken => _fcmToken.value;
  bool get notificationsEnabled => _notificationsEnabled.value;
  List<NotificationModel> get notifications => _notifications;
  
  @override
  Future<NotificationService> init() async {
    try {
      AppLogger.info('Initializing Notification Service');
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request notification permissions
      await _requestPermissions();
      
      // Initialize FCM
      await _initializeFCM();
      
      // Set up notification handlers
      _setupNotificationHandlers();
      
      AppLogger.info('Notification Service initialized successfully');
      return this;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to initialize Notification Service', error, stackTrace);
      rethrow;
    }
  }
  
  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channels for Android
    await _createNotificationChannels();
  }
  
  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'general',
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'chat',
        'Chat Messages',
        description: 'New chat messages',
        importance: Importance.high,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('chat_notification'),
      ),
      AndroidNotificationChannel(
        'video',
        'Video Updates',
        description: 'New video notifications',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'blog',
        'Blog Posts',
        description: 'New blog post notifications',
        importance: Importance.defaultImportance,
      ),
    ];
    
    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }
  
  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Request notification permission
    final permission = await Permission.notification.request();
    _notificationsEnabled.value = permission.isGranted;
    
    // Request FCM permission
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      announcement: false,
    );
    
    AppLogger.info('Notification permission status: ${settings.authorizationStatus}');
  }
  
  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    if (!AppConfig.enablePushNotifications) {
      AppLogger.info('Push notifications disabled in config');
      return;
    }
    
    try {
      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        _fcmToken.value = token;
        AppLogger.info('FCM Token obtained: ${token.substring(0, 20)}...');
        
        // Send token to server
        await _sendTokenToServer(token);
      }
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
      
    } catch (error, stackTrace) {
      AppLogger.error('Failed to initialize FCM', error, stackTrace);
    }
  }
  
  /// Set up notification message handlers
  void _setupNotificationHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    
    // Handle notification when app is opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpenedApp);
    
    // Handle notification when app is opened from background
    _handleInitialMessage();
  }
  
  /// Handle foreground messages
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    AppLogger.info('Received foreground message: ${message.messageId}');
    
    // Show local notification
    await _showLocalNotification(message);
    
    // Add to notification list
    _addNotificationToList(message);
  }
  
  /// Handle notification when app is opened
  Future<void> _onNotificationOpenedApp(RemoteMessage message) async {
    AppLogger.info('Notification opened app: ${message.messageId}');
    await _handleNotificationTap(message.data);
  }
  
  /// Handle initial message when app is launched from notification
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      AppLogger.info('App launched from notification: ${initialMessage.messageId}');
      await _handleNotificationTap(initialMessage.data);
    }
  }
  
  /// Handle notification tap
  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    final id = data['id'] as String?;
    
    switch (type) {
      case 'video':
        if (id != null) {
          Get.toNamed('/video/$id');
        }
        break;
      case 'blog':
        if (id != null) {
          Get.toNamed('/blog/$id');
        }
        break;
      case 'chat':
        Get.toNamed('/chat');
        break;
      case 'forum':
        if (id != null) {
          Get.toNamed('/forum/post/$id');
        } else {
          Get.toNamed('/forum');
        }
        break;
      default:
        Get.toNamed('/home');
    }
  }
  
  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    
    final channelId = _getChannelIdFromType(message.data['type']);
    
    const androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ticker: 'ticker',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: message.data.toString(),
    );
  }
  
  /// Get notification channel ID based on type
  String _getChannelIdFromType(String? type) {
    switch (type) {
      case 'chat':
        return 'chat';
      case 'video':
        return 'video';
      case 'blog':
        return 'blog';
      default:
        return 'general';
    }
  }
  
  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('Local notification tapped: ${response.id}');
    
    if (response.payload != null) {
      // Parse payload and navigate
      // This is a simplified implementation
      Get.toNamed('/home');
    }
  }
  
  /// Handle token refresh
  Future<void> _onTokenRefresh(String token) async {
    _fcmToken.value = token;
    AppLogger.info('FCM Token refreshed');
    await _sendTokenToServer(token);
  }
  
  /// Send token to server
  Future<void> _sendTokenToServer(String token) async {
    try {
      // TODO: Implement API call to send token to your server
      AppLogger.info('Token sent to server');
    } catch (error, stackTrace) {
      AppLogger.error('Failed to send token to server', error, stackTrace);
    }
  }
  
  /// Add notification to local list
  void _addNotificationToList(RemoteMessage message) {
    final notification = NotificationModel.fromRemoteMessage(message);
    _notifications.insert(0, notification);
    
    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }
  }
  
  /// Show custom local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'general',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
  
  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (error, stackTrace) {
      AppLogger.error('Failed to subscribe to topic: $topic', error, stackTrace);
    }
  }
  
  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (error, stackTrace) {
      AppLogger.error('Failed to unsubscribe from topic: $topic', error, stackTrace);
    }
  }
  
  /// Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    _localNotifications.cancelAll();
  }
  
  /// Remove notification by ID
  void removeNotification(String id) {
    _notifications.removeWhere((notification) => notification.id == id);
  }
  
  /// Mark notification as read
  void markAsRead(String id) {
    final index = _notifications.indexWhere((notification) => notification.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }
  
  /// Get unread count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
}

/// Notification Model
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.data,
    required this.timestamp,
    this.isRead = false,
    this.type = 'general',
  });
  
  factory NotificationModel.fromRemoteMessage(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
      data: message.data,
      timestamp: message.sentTime ?? DateTime.now(),
      type: message.data['type'] ?? 'general',
    );
  }
  
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    String? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}