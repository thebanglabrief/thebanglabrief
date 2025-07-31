import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/logger.dart';
import '../views/home_screen.dart';

/// Main Navigation Controller
/// 
/// Manages the main navigation flow including bottom navigation bar,
/// page switching, and context-aware floating action button.
class MainNavigationController extends GetxController {
  // Current page index
  final RxInt _currentIndex = 0.obs;
  
  // FAB state
  final RxBool _showFab = true.obs;
  final Rx<IconData> _fabIcon = Icons.add.obs;
  
  // Getters
  int get currentIndex => _currentIndex.value;
  bool get showFab => _showFab.value;
  IconData get fabIcon => _fabIcon.value;
  
  // Pages list
  List<Widget> get pages => [
    const HomeScreen(),
    const PlaceholderScreen(title: 'Analytics'),
    const PlaceholderScreen(title: 'Blogs'),
    const PlaceholderScreen(title: 'Forum'),
    const PlaceholderScreen(title: 'Chat'),
  ];
  
  @override
  void onInit() {
    super.onInit();
    _updateFabState();
  }
  
  /// Change current page
  void changePage(int index) {
    if (index == _currentIndex.value) return;
    
    _currentIndex.value = index;
    _updateFabState();
    
    AppLogger.userAction('Navigation tab changed', {'index': index, 'tab': _getTabName(index)});
  }
  
  /// Update FAB state based on current page
  void _updateFabState() {
    switch (_currentIndex.value) {
      case 0: // Home
        _showFab.value = true;
        _fabIcon.value = Icons.video_library;
        break;
      case 1: // Analytics
        _showFab.value = false;
        break;
      case 2: // Blogs
        _showFab.value = true;
        _fabIcon.value = Icons.create;
        break;
      case 3: // Forum
        _showFab.value = true;
        _fabIcon.value = Icons.add_comment;
        break;
      case 4: // Chat
        _showFab.value = true;
        _fabIcon.value = Icons.send;
        break;
      default:
        _showFab.value = false;
    }
  }
  
  /// Handle FAB press
  void onFabPressed() {
    switch (_currentIndex.value) {
      case 0: // Home
        _onHomeFabPressed();
        break;
      case 2: // Blogs
        _onBlogFabPressed();
        break;
      case 3: // Forum
        _onForumFabPressed();
        break;
      case 4: // Chat
        _onChatFabPressed();
        break;
    }
  }
  
  /// Handle FAB press on Home tab
  void _onHomeFabPressed() {
    // Navigate to video library or YouTube channel
    Get.toNamed('/video-library');
    AppLogger.userAction('FAB pressed on Home', {'action': 'video_library'});
  }
  
  /// Handle FAB press on Blogs tab
  void _onBlogFabPressed() {
    // Navigate to create blog post (admin only)
    Get.toNamed('/blog/create');
    AppLogger.userAction('FAB pressed on Blogs', {'action': 'create_blog'});
  }
  
  /// Handle FAB press on Forum tab
  void _onForumFabPressed() {
    // Navigate to create forum post
    Get.toNamed('/forum/create-post');
    AppLogger.userAction('FAB pressed on Forum', {'action': 'create_post'});
  }
  
  /// Handle FAB press on Chat tab
  void _onChatFabPressed() {
    // Focus on message input or quick action
    AppLogger.userAction('FAB pressed on Chat', {'action': 'quick_message'});
  }
  
  /// Get tab name for logging
  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Analytics';
      case 2:
        return 'Blogs';
      case 3:
        return 'Forum';
      case 4:
        return 'Chat';
      default:
        return 'Unknown';
    }
  }
  
  /// Navigate to specific tab
  void navigateToTab(int index) {
    if (index >= 0 && index < pages.length) {
      changePage(index);
    }
  }
  
  /// Quick navigation methods
  void goToHome() => navigateToTab(0);
  void goToAnalytics() => navigateToTab(1);
  void goToBlogs() => navigateToTab(2);
  void goToForum() => navigateToTab(3);
  void goToChat() => navigateToTab(4);
  
  /// Check if current tab has new content
  bool hasNewContent(int tabIndex) {
    // This would typically check for unread messages, new posts, etc.
    // For now, return false
    return false;
  }
  
  /// Get current page title
  String get currentPageTitle {
    switch (_currentIndex.value) {
      case 0:
        return 'The Bangla Brief';
      case 1:
        return 'Analytics';
      case 2:
        return 'Blogs';
      case 3:
        return 'Forum';
      case 4:
        return 'Chat';
      default:
        return 'The Bangla Brief';
    }
  }
}

/// Placeholder Screen Widget
class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForTitle(title),
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '$title Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This feature is under development',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Get.snackbar(
                  'Coming Soon',
                  '$title feature will be available in the next update',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: const Text('Notify Me'),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'analytics':
        return Icons.analytics_outlined;
      case 'blogs':
        return Icons.article_outlined;
      case 'forum':
        return Icons.forum_outlined;
      case 'chat':
        return Icons.chat_outlined;
      default:
        return Icons.build_outlined;
    }
  }
}