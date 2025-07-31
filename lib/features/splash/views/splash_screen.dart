import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/themes/app_theme.dart';
import '../controllers/splash_controller.dart';

/// Splash Screen
/// 
/// Initial screen shown when the app launches. Displays branding,
/// handles initialization, and navigates to appropriate screen.
class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryBlueDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top spacing
              const Spacer(flex: 2),
              
              // Logo and branding section
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_circle_fill,
                        size: 64,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // App name
                    const Text(
                      AppConfig.appName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Tagline
                    Text(
                      'Your Source for Bengali Content',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Loading section
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Loading indicator
                    Obx(() => AnimatedOpacity(
                      opacity: controller.isLoading.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            controller.loadingMessage.value,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    )),
                    
                    // Error message
                    Obx(() => AnimatedOpacity(
                      opacity: controller.hasError.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[300],
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.errorMessage.value,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[300],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: controller.retry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryBlue,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              
              // Bottom section
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Version info
                    Text(
                      'Version ${AppConfig.appVersion}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Copyright
                    Text(
                      '© 2024 The Bangla Brief',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}