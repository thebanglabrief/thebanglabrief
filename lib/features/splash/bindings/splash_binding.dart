import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

/// Splash Binding
/// 
/// Provides dependency injection for the Splash feature.
/// Binds controllers and services required for the splash screen.
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(
      () => SplashController(),
      fenix: true,
    );
  }
}