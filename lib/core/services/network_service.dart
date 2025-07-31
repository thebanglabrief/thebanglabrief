import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../utils/logger.dart';

/// Network Service
/// 
/// Monitors network connectivity and provides connection status information.
/// Uses connectivity_plus package for cross-platform connectivity detection.
class NetworkService extends GetxService {
  static NetworkService get instance => Get.find<NetworkService>();
  
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
  // Reactive state
  final RxBool _isConnected = false.obs;
  final Rx<ConnectivityResult> _connectionType = ConnectivityResult.none.obs;
  final RxBool _isWifiConnected = false.obs;
  final RxBool _isMobileConnected = false.obs;
  
  // Getters
  bool get isConnected => _isConnected.value;
  ConnectivityResult get connectionType => _connectionType.value;
  bool get isWifiConnected => _isWifiConnected.value;
  bool get isMobileConnected => _isMobileConnected.value;
  bool get hasInternetConnection => _isConnected.value;
  
  @override
  Future<NetworkService> init() async {
    try {
      AppLogger.info('Initializing Network Service');
      
      // Check initial connectivity
      await _checkInitialConnectivity();
      
      // Set up connectivity listener
      _setupConnectivityListener();
      
      AppLogger.info('Network Service initialized successfully');
      return this;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to initialize Network Service', error, stackTrace);
      rethrow;
    }
  }
  
  /// Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to check initial connectivity', error, stackTrace);
      // Default to no connection on error
      _updateConnectionStatus([ConnectivityResult.none]);
    }
  }
  
  /// Set up connectivity change listener
  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        AppLogger.error('Connectivity listener error', error);
      },
    );
  }
  
  /// Update connection status based on connectivity results
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Get the primary connection type
    final primaryConnection = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _connectionType.value = primaryConnection;
    
    // Determine if connected
    final wasConnected = _isConnected.value;
    _isConnected.value = results.any((result) => 
        result != ConnectivityResult.none);
    
    // Update specific connection types
    _isWifiConnected.value = results.contains(ConnectivityResult.wifi);
    _isMobileConnected.value = results.contains(ConnectivityResult.mobile);
    
    // Log connectivity changes
    if (wasConnected != _isConnected.value) {
      if (_isConnected.value) {
        AppLogger.info('Internet connection restored: ${_getConnectionTypeString()}');
      } else {
        AppLogger.warning('Internet connection lost');
      }
    }
    
    AppLogger.debug('Connection status: ${_getConnectionTypeString()}');
  }
  
  /// Get human-readable connection type string
  String _getConnectionTypeString() {
    switch (_connectionType.value) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
      default:
        return 'No Connection';
    }
  }
  
  /// Get connection status description
  String get connectionStatusDescription {
    if (!_isConnected.value) {
      return 'No internet connection';
    }
    
    return 'Connected via ${_getConnectionTypeString()}';
  }
  
  /// Check if connection is metered (mobile data)
  bool get isMeteredConnection {
    return _isMobileConnected.value && !_isWifiConnected.value;
  }
  
  /// Check if connection is suitable for large downloads
  bool get isSuitableForLargeDownloads {
    return _isWifiConnected.value || 
           (_isMobileConnected.value && !isMeteredConnection);
  }
  
  /// Check if connection is suitable for video streaming
  bool get isSuitableForVideoStreaming {
    // Allow video streaming on any connection, but prefer WiFi
    return _isConnected.value;
  }
  
  /// Force refresh connectivity status
  Future<void> refreshConnectivity() async {
    try {
      AppLogger.debug('Refreshing connectivity status');
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to refresh connectivity', error, stackTrace);
    }
  }
  
  /// Wait for internet connection
  Future<void> waitForConnection({Duration? timeout}) async {
    if (_isConnected.value) return;
    
    final completer = Completer<void>();
    late StreamSubscription subscription;
    Timer? timeoutTimer;
    
    // Set up timeout if specified
    if (timeout != null) {
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.completeError(TimeoutException(
            'Timeout waiting for internet connection',
            timeout,
          ));
        }
      });
    }
    
    // Listen for connection
    subscription = _isConnected.listen((isConnected) {
      if (isConnected && !completer.isCompleted) {
        timeoutTimer?.cancel();
        subscription.cancel();
        completer.complete();
      }
    });
    
    return completer.future;
  }
  
  /// Show connection status message
  void showConnectionStatus() {
    if (_isConnected.value) {
      Get.snackbar(
        'Connected',
        connectionStatusDescription,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } else {
      Get.snackbar(
        'No Connection',
        'Please check your internet connection',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }
  
  /// Get network quality estimation
  NetworkQuality get networkQuality {
    if (!_isConnected.value) {
      return NetworkQuality.none;
    }
    
    if (_isWifiConnected.value) {
      return NetworkQuality.high;
    } else if (_isMobileConnected.value) {
      return NetworkQuality.medium;
    } else {
      return NetworkQuality.low;
    }
  }
  
  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}

/// Network Quality Enumeration
enum NetworkQuality {
  none,
  low,
  medium,
  high,
}

/// Network Quality Extensions
extension NetworkQualityExtension on NetworkQuality {
  String get displayName {
    switch (this) {
      case NetworkQuality.none:
        return 'No Connection';
      case NetworkQuality.low:
        return 'Poor Connection';
      case NetworkQuality.medium:
        return 'Good Connection';
      case NetworkQuality.high:
        return 'Excellent Connection';
    }
  }
  
  bool get canStreamVideo => this != NetworkQuality.none;
  bool get canDownloadLargeFiles => this == NetworkQuality.high;
  bool get shouldCompressImages => this == NetworkQuality.low || this == NetworkQuality.medium;
}

/// Timeout Exception
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  
  TimeoutException(this.message, this.timeout);
  
  @override
  String toString() => 'TimeoutException: $message (${timeout.inSeconds}s)';
}