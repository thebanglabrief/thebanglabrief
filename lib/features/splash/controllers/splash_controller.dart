import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/logger.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/network_service.dart';
import '../../../core/services/youtube_service.dart';
import '../../auth/controllers/auth_controller.dart';

/// Splash Controller
/// 
/// Manages the splash screen functionality including app initialization,
/// service health checks, and navigation logic.
class SplashController extends GetxController {
  // Services
  late final CacheService _cacheService;
  late final NetworkService _networkService;
  late final YouTubeService _youTubeService;
  late final AuthController _authController;
  
  // Reactive state
  final RxBool _isLoading = true.obs;
  final RxBool _hasError = false.obs;
  final RxString _loadingMessage = 'Initializing...'.obs;
  final RxString _errorMessage = ''.obs;
  
  // Getters
  bool get isLoading => _isLoading.value;
  bool get hasError => _hasError.value;
  String get loadingMessage => _loadingMessage.value;
  String get errorMessage => _errorMessage.value;
  
  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _startInitialization();
  }
  
  /// Initialize service references
  void _initializeServices() {
    _cacheService = CacheService.instance;
    _networkService = NetworkService.instance;
    _youTubeService = YouTubeService.instance;
    _authController = AuthController.instance;
  }
  
  /// Start the app initialization process
  Future<void> _startInitialization() async {
    try {
      AppLogger.info('Starting splash initialization');
      
      // Step 1: Check network connectivity
      await _checkNetworkConnectivity();
      
      // Step 2: Verify services
      await _verifyServices();
      
      // Step 3: Load essential data
      await _loadEssentialData();
      
      // Step 4: Check authentication state
      await _checkAuthenticationState();
      
      // Step 5: Navigate to appropriate screen
      await _navigateToNextScreen();
      
    } catch (error, stackTrace) {
      AppLogger.error('Splash initialization failed', error, stackTrace);
      _handleInitializationError(error.toString());
    }
  }
  
  /// Check network connectivity
  Future<void> _checkNetworkConnectivity() async {
    _updateLoadingMessage('Checking connectivity...');
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!_networkService.isConnected) {
      AppLogger.warning('No internet connection detected');
      // Continue without network - app should work offline
    } else {
      AppLogger.info('Network connectivity confirmed');
    }
  }
  
  /// Verify that all services are properly initialized
  Future<void> _verifyServices() async {
    _updateLoadingMessage('Verifying services...');
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check cache service
    final cacheInfo = _cacheService.getCacheInfo();
    AppLogger.debug('Cache service verified: ${cacheInfo['totalItems']} items');
    
    // Check YouTube service quota
    if (_youTubeService.quotaExceeded) {
      AppLogger.warning('YouTube API quota exceeded');
    }
    
    AppLogger.info('All services verified successfully');
  }
  
  /// Load essential data required for app startup
  Future<void> _loadEssentialData() async {
    _updateLoadingMessage('Loading essential data...');
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      // Try to load channel stats if network is available
      if (_networkService.isConnected && !_youTubeService.quotaExceeded) {
        AppLogger.info('Preloading channel statistics');
        await _youTubeService.getChannelStats();
      }
    } catch (error) {
      AppLogger.warning('Failed to preload channel stats: $error');
      // Continue without preloaded data
    }
    
    AppLogger.info('Essential data loaded');
  }
  
  /// Check current authentication state
  Future<void> _checkAuthenticationState() async {
    _updateLoadingMessage('Checking authentication...');
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Authentication state is automatically managed by AuthController
    // through Firebase Auth state listener
    
    AppLogger.info('Authentication state checked');
  }
  
  /// Navigate to the appropriate screen based on app state
  Future<void> _navigateToNextScreen() async {
    _updateLoadingMessage('Launching app...');
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Hide loading
    _isLoading.value = false;
    
    // Small delay for smooth transition
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Determine navigation destination
    String destination;
    
    if (_authController.isLoggedIn.value) {
      // User is authenticated, go to main app
      destination = AppRoutes.mainNavigation;
      AppLogger.info('Navigating to main app - user authenticated');
    } else {
      // User not authenticated, check if first time
      final isFirstTime = _cacheService.getUserPref<bool>('is_first_time', true);
      
      if (isFirstTime) {
        // First time user, could go to onboarding or direct to login
        destination = AppRoutes.login;
        await _cacheService.setUserPref('is_first_time', false);
        AppLogger.info('Navigating to login - first time user');
      } else {
        // Returning user, go to login
        destination = AppRoutes.login;
        AppLogger.info('Navigating to login - returning user');
      }
    }
    
    // Navigate with replacement to prevent back navigation to splash
    Get.offAllNamed(destination);
  }
  
  /// Handle initialization errors
  void _handleInitializationError(String error) {
    _isLoading.value = false;
    _hasError.value = true;
    _errorMessage.value = _getErrorMessage(error);
    
    AppLogger.error('Initialization error displayed to user: $_errorMessage');
  }
  
  /// Get user-friendly error message
  String _getErrorMessage(String error) {
    if (error.toLowerCase().contains('network') || 
        error.toLowerCase().contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    } else if (error.toLowerCase().contains('firebase')) {
      return 'Service error. Please try again in a moment.';
    } else if (error.toLowerCase().contains('timeout')) {
      return 'Request timeout. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
  
  /// Update loading message
  void _updateLoadingMessage(String message) {
    _loadingMessage.value = message;
    AppLogger.debug('Loading: $message');
  }
  
  /// Retry initialization
  void retry() {
    AppLogger.info('Retrying splash initialization');
    
    // Reset state
    _isLoading.value = true;
    _hasError.value = false;
    _errorMessage.value = '';
    _loadingMessage.value = 'Retrying...';
    
    // Restart initialization
    _startInitialization();
  }
  
  /// Skip to main app (emergency bypass)
  void skipToApp() {
    AppLogger.warning('Emergency bypass to main app');
    Get.offAllNamed(AppRoutes.mainNavigation);
  }
  
  /// Get initialization progress percentage
  double getInitializationProgress() {
    if (_hasError.value) return 0.0;
    if (!_isLoading.value) return 1.0;
    
    // Estimate progress based on loading message
    switch (_loadingMessage.value) {
      case 'Initializing...':
        return 0.1;
      case 'Checking connectivity...':
        return 0.25;
      case 'Verifying services...':
        return 0.5;
      case 'Loading essential data...':
        return 0.75;
      case 'Checking authentication...':
        return 0.9;
      case 'Launching app...':
        return 0.95;
      default:
        return 0.5;
    }
  }
  
  /// Check if app is ready to proceed
  bool get isAppReady {
    return !_isLoading.value && !_hasError.value;
  }
  
  /// Get app health status for debugging
  Map<String, dynamic> getAppHealth() {
    return {
      'isLoading': _isLoading.value,
      'hasError': _hasError.value,
      'errorMessage': _errorMessage.value,
      'loadingMessage': _loadingMessage.value,
      'networkConnected': _networkService.isConnected,
      'quotaExceeded': _youTubeService.quotaExceeded,
      'isAuthenticated': _authController.isLoggedIn.value,
      'cacheItems': _cacheService.itemCount,
      'initializationProgress': getInitializationProgress(),
    };
  }
}