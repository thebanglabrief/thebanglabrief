import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/utils/logger.dart';

/// Theme Controller
/// 
/// Manages app theming including dark/light mode switching,
/// system preference detection, and theme persistence.
class ThemeController extends GetxController {
  static ThemeController get instance => Get.find<ThemeController>();
  
  // Reactive state
  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  final RxBool _followSystemTheme = true.obs;
  
  // Getters
  ThemeMode get themeMode => _themeMode.value;
  bool get followSystemTheme => _followSystemTheme.value;
  bool get isDarkMode => _getCurrentBrightness() == Brightness.dark;
  bool get isLightMode => _getCurrentBrightness() == Brightness.light;
  
  // Cache service
  late final CacheService _cacheService;
  
  @override
  void onInit() {
    super.onInit();
    _cacheService = CacheService.instance;
    _loadThemePreferences();
    _setupSystemThemeListener();
  }
  
  /// Load theme preferences from cache
  void _loadThemePreferences() {
    try {
      // Load saved theme mode
      final savedThemeMode = _cacheService.getUserPref<String>('theme_mode');
      final savedFollowSystem = _cacheService.getUserPref<bool>('follow_system_theme', true);
      
      _followSystemTheme.value = savedFollowSystem;
      
      if (savedThemeMode != null && !_followSystemTheme.value) {
        switch (savedThemeMode) {
          case 'light':
            _themeMode.value = ThemeMode.light;
            break;
          case 'dark':
            _themeMode.value = ThemeMode.dark;
            break;
          default:
            _themeMode.value = ThemeMode.system;
        }
      } else {
        _themeMode.value = ThemeMode.system;
      }
      
      AppLogger.debug('Theme preferences loaded: ${_themeMode.value}, follow system: ${_followSystemTheme.value}');
      
      // Update system UI overlay style
      _updateSystemUIOverlayStyle();
      
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load theme preferences', error, stackTrace);
      // Set default values on error
      _themeMode.value = ThemeMode.system;
      _followSystemTheme.value = true;
    }
  }
  
  /// Set up system theme listener
  void _setupSystemThemeListener() {
    // Listen to system theme changes
    ever(_themeMode, (ThemeMode mode) {
      _updateSystemUIOverlayStyle();
      Get.changeThemeMode(mode);
      AppLogger.info('Theme changed to: $mode');
    });
    
    // Listen to system follow preference changes
    ever(_followSystemTheme, (bool followSystem) {
      if (followSystem) {
        _themeMode.value = ThemeMode.system;
      }
      _saveThemePreferences();
    });
  }
  
  /// Update system UI overlay style based on current theme
  void _updateSystemUIOverlayStyle() {
    final brightness = _getCurrentBrightness();
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark 
            ? Brightness.light 
            : Brightness.dark,
        systemNavigationBarColor: brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        systemNavigationBarIconBrightness: brightness == Brightness.dark 
            ? Brightness.light 
            : Brightness.dark,
      ),
    );
  }
  
  /// Get current brightness based on theme mode
  Brightness _getCurrentBrightness() {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
  }
  
  /// Switch to light theme
  void setLightTheme() {
    _followSystemTheme.value = false;
    _themeMode.value = ThemeMode.light;
    _saveThemePreferences();
    AppLogger.userAction('Theme switched to light');
  }
  
  /// Switch to dark theme
  void setDarkTheme() {
    _followSystemTheme.value = false;
    _themeMode.value = ThemeMode.dark;
    _saveThemePreferences();
    AppLogger.userAction('Theme switched to dark');
  }
  
  /// Follow system theme
  void setSystemTheme() {
    _followSystemTheme.value = true;
    _themeMode.value = ThemeMode.system;
    _saveThemePreferences();
    AppLogger.userAction('Theme set to follow system');
  }
  
  /// Toggle between light and dark theme
  void toggleTheme() {
    if (_followSystemTheme.value) {
      // If following system, switch to opposite of current system theme
      final systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      if (systemBrightness == Brightness.dark) {
        setLightTheme();
      } else {
        setDarkTheme();
      }
    } else {
      // If not following system, toggle between current modes
      switch (_themeMode.value) {
        case ThemeMode.light:
          setDarkTheme();
          break;
        case ThemeMode.dark:
          setLightTheme();
          break;
        case ThemeMode.system:
          // This shouldn't happen when not following system, but handle it
          setDarkTheme();
          break;
      }
    }
  }
  
  /// Save theme preferences to cache
  void _saveThemePreferences() {
    try {
      final themeModeString = _themeMode.value.toString().split('.').last;
      _cacheService.setUserPref('theme_mode', themeModeString);
      _cacheService.setUserPref('follow_system_theme', _followSystemTheme.value);
      
      AppLogger.debug('Theme preferences saved');
    } catch (error, stackTrace) {
      AppLogger.error('Failed to save theme preferences', error, stackTrace);
    }
  }
  
  /// Get theme mode display name
  String get themeModeDisplayName {
    if (_followSystemTheme.value) {
      return 'System';
    }
    
    switch (_themeMode.value) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
  
  /// Get theme icon
  IconData get themeIcon {
    if (_followSystemTheme.value) {
      return Icons.brightness_auto;
    }
    
    switch (_themeMode.value) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
  
  /// Check if current theme is the specified mode
  bool isThemeMode(ThemeMode mode) {
    if (_followSystemTheme.value && mode == ThemeMode.system) {
      return true;
    }
    return !_followSystemTheme.value && _themeMode.value == mode;
  }
  
  /// Get available theme options
  List<ThemeOption> get themeOptions => [
    ThemeOption(
      mode: ThemeMode.system,
      title: 'System',
      subtitle: 'Follow system setting',
      icon: Icons.brightness_auto,
      isSelected: _followSystemTheme.value,
    ),
    ThemeOption(
      mode: ThemeMode.light,
      title: 'Light',
      subtitle: 'Light theme',
      icon: Icons.light_mode,
      isSelected: isThemeMode(ThemeMode.light),
    ),
    ThemeOption(
      mode: ThemeMode.dark,
      title: 'Dark',
      subtitle: 'Dark theme',
      icon: Icons.dark_mode,
      isSelected: isThemeMode(ThemeMode.dark),
    ),
  ];
  
  /// Set theme from option
  void setThemeFromOption(ThemeOption option) {
    switch (option.mode) {
      case ThemeMode.system:
        setSystemTheme();
        break;
      case ThemeMode.light:
        setLightTheme();
        break;
      case ThemeMode.dark:
        setDarkTheme();
        break;
    }
  }
  
  /// Reset theme to default (system)
  void resetTheme() {
    setSystemTheme();
    AppLogger.userAction('Theme reset to system');
  }
}

/// Theme option model for UI
class ThemeOption {
  final ThemeMode mode;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  
  const ThemeOption({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
  });
}