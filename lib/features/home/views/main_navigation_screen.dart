import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_theme.dart';
import '../controllers/main_navigation_controller.dart';

/// Main Navigation Screen
/// 
/// The primary navigation hub of the app featuring a bottom navigation bar
/// with access to Home, Analytics, Blogs, Forum, and Chat sections.
class MainNavigationScreen extends GetView<MainNavigationController> {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: controller.pages,
      )),
      bottomNavigationBar: Obx(() => NavigationBar(
        selectedIndex: controller.currentIndex.value,
        onDestinationSelected: controller.changePage,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Blogs',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Forum',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
      )),
      floatingActionButton: Obx(() => controller.showFab.value
          ? FloatingActionButton(
              onPressed: controller.onFabPressed,
              backgroundColor: AppTheme.accentOrange,
              child: Icon(controller.fabIcon.value),
            )
          : const SizedBox.shrink()),
    );
  }
}