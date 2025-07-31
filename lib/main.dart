import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Core imports
import 'core/config/app_config.dart';
import 'core/config/firebase_options.dart';
import 'core/themes/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/utils/logger.dart';
import 'core/services/notification_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/network_service.dart';
import 'core/services/youtube_service.dart';

// Controllers
import 'features/auth/controllers/auth_controller.dart';
import 'features/home/controllers/theme_controller.dart';

// Firebase background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.info('Handling background message: ${message.messageId}');
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set up Firebase Messaging background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Initialize Hive for local storage
    await Hive.initFlutter();
    
    // Initialize services
    await _initializeServices();
    
    // Set system UI preferences
    await _setSystemUIPreferences();
    
    // Run the app
    runApp(const TheBanglabrief());
    
  } catch (error, stackTrace) {
    AppLogger.error('Error during app initialization: $error', stackTrace);
    // Run app with error state
    runApp(const AppErrorWidget());
  }
}

/// Initialize all required services
Future<void> _initializeServices() async {
  try {
    // Initialize cache service
    await Get.putAsync(() => CacheService().init());
    
    // Initialize network service
    await Get.putAsync(() => NetworkService().init());
    
    // Initialize notification service
    await Get.putAsync(() => NotificationService().init());
    
    // Initialize YouTube service
    await Get.putAsync(() => YouTubeService().init());
    
    // Initialize core controllers
    Get.put(AuthController(), permanent: true);
    Get.put(ThemeController(), permanent: true);
    
    AppLogger.info('Services initialized successfully');
  } catch (error, stackTrace) {
    AppLogger.error('Error initializing services: $error', stackTrace);
    rethrow;
  }
}

/// Set system UI preferences
Future<void> _setSystemUIPreferences() async {
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

class TheBanglabrief extends StatelessWidget {
  const TheBanglabrief({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // App Configuration
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: Get.find<ThemeController>().themeMode,
      
      // Localization
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      
      // Navigation
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      unknownRoute: AppRoutes.unknownRoute,
      
      // Performance optimizations
      routingCallback: (routing) {
        AppLogger.debug('Navigation: ${routing?.current}');
      },
      
      // Global configurations
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      
      // Error handling
      builder: (context, child) {
        return MediaQuery(
          // Prevent font scaling issues
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Error widget displayed when app initialization fails
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Bangla Brief - Error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please restart the app. If the problem persists, contact support.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Force app restart
                    SystemNavigator.pop();
                  },
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}