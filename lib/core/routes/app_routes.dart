import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Screens
import '../../features/splash/views/splash_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/auth/views/forgot_password_screen.dart';
import '../../features/home/views/main_navigation_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/analytics/views/analytics_screen.dart';
import '../../features/blog/views/blog_list_screen.dart';
import '../../features/blog/views/blog_detail_screen.dart';
import '../../features/blog/views/blog_create_screen.dart';
import '../../features/forum/views/forum_screen.dart';
import '../../features/forum/views/forum_post_detail_screen.dart';
import '../../features/forum/views/forum_create_post_screen.dart';
import '../../features/chat/views/chat_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/profile/views/edit_profile_screen.dart';
import '../../features/settings/views/settings_screen.dart';
import '../../features/admin/views/admin_dashboard_screen.dart';
import '../../features/admin/views/admin_blog_management_screen.dart';
import '../../features/admin/views/admin_user_management_screen.dart';
import '../../features/admin/views/admin_forum_moderation_screen.dart';
import '../../features/video/views/video_player_screen.dart';

// Bindings
import '../../features/splash/bindings/splash_binding.dart';
import '../../features/auth/bindings/auth_binding.dart';

// Controllers (for middleware)
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/home/bindings/home_binding.dart';
import '../../features/analytics/bindings/analytics_binding.dart';
import '../../features/blog/bindings/blog_binding.dart';
import '../../features/forum/bindings/forum_binding.dart';
import '../../features/chat/bindings/chat_binding.dart';
import '../../features/profile/bindings/profile_binding.dart';
import '../../features/settings/bindings/settings_binding.dart';
import '../../features/admin/bindings/admin_binding.dart';
import '../../features/video/bindings/video_binding.dart';

/// App Routes Configuration
/// 
/// Defines all application routes with proper bindings and middleware.
/// Uses GetX routing system for efficient navigation and state management.
class AppRoutes {
  // Route Names
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String mainNavigation = '/main';
  static const String home = '/home';
  static const String analytics = '/analytics';
  static const String blogList = '/blogs';
  static const String blogDetail = '/blog/:id';
  static const String blogCreate = '/blog/create';
  static const String blogEdit = '/blog/edit/:id';
  static const String forum = '/forum';
  static const String forumPostDetail = '/forum/post/:id';
  static const String forumCreatePost = '/forum/create-post';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String adminDashboard = '/admin';
  static const String adminBlogManagement = '/admin/blogs';
  static const String adminUserManagement = '/admin/users';
  static const String adminForumModeration = '/admin/forum';
  static const String videoPlayer = '/video/:videoId';
  
  // Error Routes
  static const String notFound = '/404';
  
  /// All app routes with their respective pages and bindings
  static List<GetPage> get pages => [
    // Splash & Authentication Routes
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: register,
      page: () => const RegisterScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: forgotPassword,
      page: () => const ForgotPasswordScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Main Navigation
    GetPage(
      name: mainNavigation,
      page: () => const MainNavigationScreen(),
      bindings: [
        HomeBinding(),
        AnalyticsBinding(),
        BlogBinding(),
        ForumBinding(),
        ChatBinding(),
      ],
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Home Routes
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      transition: Transition.noTransition,
    ),
    
    // Analytics Routes
    GetPage(
      name: analytics,
      page: () => const AnalyticsScreen(),
      binding: AnalyticsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Blog Routes
    GetPage(
      name: blogList,
      page: () => const BlogListScreen(),
      binding: BlogBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: blogDetail,
      page: () => const BlogDetailScreen(),
      binding: BlogBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: blogCreate,
      page: () => const BlogCreateScreen(),
      binding: BlogBinding(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 400),
      middlewares: [AdminMiddleware()],
    ),
    
    GetPage(
      name: blogEdit,
      page: () => const BlogCreateScreen(isEdit: true),
      binding: BlogBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AdminMiddleware()],
    ),
    
    // Forum Routes
    GetPage(
      name: forum,
      page: () => const ForumScreen(),
      binding: ForumBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: forumPostDetail,
      page: () => const ForumPostDetailScreen(),
      binding: ForumBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: forumCreatePost,
      page: () => const ForumCreatePostScreen(),
      binding: ForumBinding(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 400),
      middlewares: [AuthMiddleware()],
    ),
    
    // Chat Routes
    GetPage(
      name: chat,
      page: () => const ChatScreen(),
      binding: ChatBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),
    
    // Profile Routes
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),
    
    GetPage(
      name: editProfile,
      page: () => const EditProfileScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),
    
    // Settings Routes
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Admin Routes
    GetPage(
      name: adminDashboard,
      page: () => const AdminDashboardScreen(),
      binding: AdminBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AdminMiddleware()],
    ),
    
    GetPage(
      name: adminBlogManagement,
      page: () => const AdminBlogManagementScreen(),
      binding: AdminBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AdminMiddleware()],
    ),
    
    GetPage(
      name: adminUserManagement,
      page: () => const AdminUserManagementScreen(),
      binding: AdminBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AdminMiddleware()],
    ),
    
    GetPage(
      name: adminForumModeration,
      page: () => const AdminForumModerationScreen(),
      binding: AdminBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AdminMiddleware()],
    ),
    
    // Video Player Route
    GetPage(
      name: videoPlayer,
      page: () => const VideoPlayerScreen(),
      binding: VideoBinding(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 400),
    ),
  ];
  
  /// Unknown route handler
  static GetPage get unknownRoute => GetPage(
    name: notFound,
    page: () => const NotFoundScreen(),
    transition: Transition.fadeIn,
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// Authentication Middleware
/// Checks if user is authenticated before accessing protected routes
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Check if user is authenticated
    final authController = Get.find<AuthController>();
    if (!authController.isLoggedIn.value) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

/// Admin Middleware
/// Checks if user has admin privileges before accessing admin routes
class AdminMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Check if user is authenticated and has admin role
    final authController = Get.find<AuthController>();
    if (!authController.isLoggedIn.value) {
      return const RouteSettings(name: AppRoutes.login);
    }
    if (!authController.isAdmin.value) {
      return const RouteSettings(name: AppRoutes.home);
    }
    return null;
  }
}

/// 404 Not Found Screen
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed(AppRoutes.home),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                '404',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The page you are looking for does not exist.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Get.offAllNamed(AppRoutes.home),
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}