import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/logger.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/routes/app_routes.dart';
import '../models/user_model.dart';

/// Authentication Controller
/// 
/// Manages Firebase Authentication, user sessions, role-based access control,
/// and admin functionality for The Bangla Brief app.
class AuthController extends GetxController {
  static AuthController get instance => Get.find<AuthController>();
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Services
  late final CacheService _cacheService;
  late final NotificationService _notificationService;
  
  // Reactive state
  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isLoggedIn = false.obs;
  final RxBool _isAdmin = false.obs;
  final RxBool _isModerator = false.obs;
  final RxString _authError = ''.obs;
  final RxBool _isPasswordVisible = false.obs;
  
  // Getters
  User? get firebaseUser => _firebaseUser.value;
  UserModel? get currentUser => _userModel.value;
  bool get isLoading => _isLoading.value;
  bool get isLoggedIn => _isLoggedIn.value;
  bool get isAdmin => _isAdmin.value;
  bool get isModerator => _isModerator.value;
  bool get hasModeratorAccess => _isAdmin.value || _isModerator.value;
  String get authError => _authError.value;
  bool get isPasswordVisible => _isPasswordVisible.value;
  String? get userId => _firebaseUser.value?.uid;
  String? get userEmail => _firebaseUser.value?.email;
  String? get userDisplayName => _userModel.value?.displayName ?? _firebaseUser.value?.displayName;
  String? get userPhotoUrl => _userModel.value?.photoUrl ?? _firebaseUser.value?.photoURL;
  
  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _setupAuthStateListener();
  }
  
  /// Initialize required services
  void _initializeServices() {
    _cacheService = CacheService.instance;
    _notificationService = NotificationService.instance;
  }
  
  /// Set up Firebase Auth state listener
  void _setupAuthStateListener() {
    _firebaseUser.bindStream(_auth.authStateChanges());
    
    // Listen to auth state changes
    ever(_firebaseUser, _handleAuthStateChange);
  }
  
  /// Handle Firebase Auth state changes
  Future<void> _handleAuthStateChange(User? user) async {
    try {
      if (user != null) {
        AppLogger.info('User signed in: ${user.uid}');
        
        // Load user data from Firestore
        await _loadUserData(user);
        
        // Update login state
        _isLoggedIn.value = true;
        
        // Subscribe to notification topics
        await _subscribeToNotificationTopics();
        
      } else {
        AppLogger.info('User signed out');
        
        // Clear user data
        _userModel.value = null;
        _isLoggedIn.value = false;
        _isAdmin.value = false;
        _isModerator.value = false;
        
        // Clear cached auth data
        await _clearAuthCache();
        
        // Unsubscribe from notification topics
        await _unsubscribeFromNotificationTopics();
      }
    } catch (error, stackTrace) {
      AppLogger.error('Error handling auth state change', error, stackTrace);
      _authError.value = 'Authentication error occurred';
    }
  }
  
  /// Load user data from Firestore
  Future<void> _loadUserData(User user) async {
    try {
      final doc = await _firestore
          .collection(AppConfig.usersCollection)
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        _userModel.value = UserModel.fromFirestore(doc);
        _updateUserRoles();
        AppLogger.info('User data loaded from Firestore');
      } else {
        // Create new user document
        await _createUserDocument(user);
      }
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load user data', error, stackTrace);
      throw Exception('Failed to load user data');
    }
  }
  
  /// Create new user document in Firestore
  Future<void> _createUserDocument(User user) async {
    try {
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL,
        role: UserRole.user,
        isActive: true,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        notificationSettings: const NotificationSettings(
          enablePushNotifications: true,
          enableEmailNotifications: true,
          enableVideoNotifications: true,
          enableBlogNotifications: true,
          enableChatNotifications: true,
        ),
      );
      
      await _firestore
          .collection(AppConfig.usersCollection)
          .doc(user.uid)
          .set(userModel.toFirestore());
      
      _userModel.value = userModel;
      _updateUserRoles();
      
      AppLogger.info('New user document created');
    } catch (error, stackTrace) {
      AppLogger.error('Failed to create user document', error, stackTrace);
      throw Exception('Failed to create user profile');
    }
  }
  
  /// Update user roles based on user data
  void _updateUserRoles() {
    final user = _userModel.value;
    if (user != null) {
      _isAdmin.value = user.role == UserRole.admin;
      _isModerator.value = user.role == UserRole.moderator;
    }
  }
  
  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading.value = true;
      _authError.value = '';
      
      // Check for admin credentials
      if (email.toLowerCase() == AppConfig.adminUsername && password == AppConfig.adminPassword) {
        return await _signInAsAdmin();
      }
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Update last login time
        await _updateLastLoginTime();
        AppLogger.userAction('User signed in with email', {'email': email});
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return false;
    } catch (error, stackTrace) {
      AppLogger.error('Sign in error', error, stackTrace);
      _authError.value = AppConfig.genericErrorMessage;
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
  
  /// Sign in as admin with special credentials
  Future<bool> _signInAsAdmin() async {
    try {
      // Create or sign in admin user
      UserCredential? credential;
      const adminEmail = '${AppConfig.adminUsername}@admin.local';
      
      try {
        // Try to sign in
        credential = await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: AppConfig.adminPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // Create admin account
          credential = await _auth.createUserWithEmailAndPassword(
            email: adminEmail,
            password: AppConfig.adminPassword,
          );
        } else {
          rethrow;
        }
      }
      
      if (credential?.user != null) {
        // Create/update admin user document
        await _createAdminUserDocument(credential!.user!);
        AppLogger.userAction('Admin signed in');
        return true;
      }
      
      return false;
    } catch (error, stackTrace) {
      AppLogger.error('Admin sign in error', error, stackTrace);
      _authError.value = 'Failed to sign in as admin';
      return false;
    }
  }
  
  /// Create admin user document
  Future<void> _createAdminUserDocument(User user) async {
    final adminUser = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: 'Admin',
      photoUrl: null,
      role: UserRole.admin,
      isActive: true,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      notificationSettings: const NotificationSettings(
        enablePushNotifications: true,
        enableEmailNotifications: true,
        enableVideoNotifications: true,
        enableBlogNotifications: true,
        enableChatNotifications: true,
      ),
    );
    
    await _firestore
        .collection(AppConfig.usersCollection)
        .doc(user.uid)
        .set(adminUser.toFirestore());
    
    _userModel.value = adminUser;
    _updateUserRoles();
  }
  
  /// Register with email and password
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _isLoading.value = true;
      _authError.value = '';
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(displayName);
        
        // Create user document with provided display name
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
          photoUrl: null,
          role: UserRole.user,
          isActive: true,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          notificationSettings: const NotificationSettings(
            enablePushNotifications: true,
            enableEmailNotifications: true,
            enableVideoNotifications: true,
            enableBlogNotifications: true,
            enableChatNotifications: true,
          ),
        );
        
        await _firestore
            .collection(AppConfig.usersCollection)
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());
        
        AppLogger.userAction('User registered', {'email': email, 'displayName': displayName});
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return false;
    } catch (error, stackTrace) {
      AppLogger.error('Registration error', error, stackTrace);
      _authError.value = AppConfig.genericErrorMessage;
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
  
  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _isLoading.value = true;
      _authError.value = '';
      
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.userAction('Password reset email sent', {'email': email});
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return false;
    } catch (error, stackTrace) {
      AppLogger.error('Password reset error', error, stackTrace);
      _authError.value = AppConfig.genericErrorMessage;
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading.value = true;
      
      await _auth.signOut();
      AppLogger.userAction('User signed out');
      
      // Navigate to login screen
      Get.offAllNamed(AppRoutes.login);
    } catch (error, stackTrace) {
      AppLogger.error('Sign out error', error, stackTrace);
    } finally {
      _isLoading.value = false;
    }
  }
  
  /// Update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      _isLoading.value = true;
      final user = _firebaseUser.value;
      if (user == null) return false;
      
      // Update Firebase user profile
      if (displayName != null || photoUrl != null) {
        await user.updateDisplayName(displayName);
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }
      }
      
      // Update Firestore document
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection(AppConfig.usersCollection)
          .doc(user.uid)
          .update(updates);
      
      // Update local user model
      if (_userModel.value != null) {
        _userModel.value = _userModel.value!.copyWith(
          displayName: displayName ?? _userModel.value!.displayName,
          photoUrl: photoUrl ?? _userModel.value!.photoUrl,
        );
      }
      
      AppLogger.userAction('User profile updated');
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('Profile update error', error, stackTrace);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
  
  /// Update last login time
  Future<void> _updateLastLoginTime() async {
    try {
      final user = _firebaseUser.value;
      if (user != null) {
        await _firestore
            .collection(AppConfig.usersCollection)
            .doc(user.uid)
            .update({'lastLoginAt': FieldValue.serverTimestamp()});
      }
    } catch (error, stackTrace) {
      AppLogger.error('Failed to update last login time', error, stackTrace);
    }
  }
  
  /// Subscribe to notification topics
  Future<void> _subscribeToNotificationTopics() async {
    try {
      // Subscribe to general topics
      await _notificationService.subscribeToTopic('general');
      await _notificationService.subscribeToTopic('videos');
      await _notificationService.subscribeToTopic('blogs');
      
      // Subscribe to role-specific topics
      if (_isAdmin.value) {
        await _notificationService.subscribeToTopic('admin');
      }
      if (_isModerator.value) {
        await _notificationService.subscribeToTopic('moderator');
      }
    } catch (error, stackTrace) {
      AppLogger.error('Failed to subscribe to notification topics', error, stackTrace);
    }
  }
  
  /// Unsubscribe from notification topics
  Future<void> _unsubscribeFromNotificationTopics() async {
    try {
      await _notificationService.unsubscribeFromTopic('general');
      await _notificationService.unsubscribeFromTopic('videos');
      await _notificationService.unsubscribeFromTopic('blogs');
      await _notificationService.unsubscribeFromTopic('admin');
      await _notificationService.unsubscribeFromTopic('moderator');
    } catch (error, stackTrace) {
      AppLogger.error('Failed to unsubscribe from notification topics', error, stackTrace);
    }
  }
  
  /// Clear auth cache
  Future<void> _clearAuthCache() async {
    try {
      await _cacheService.removeUserPref('user_id');
      await _cacheService.removeUserPref('user_role');
    } catch (error, stackTrace) {
      AppLogger.error('Failed to clear auth cache', error, stackTrace);
    }
  }
  
  /// Handle Firebase Auth exceptions
  void _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        _authError.value = 'No user found with this email.';
        break;
      case 'wrong-password':
        _authError.value = 'Wrong password provided.';
        break;
      case 'invalid-email':
        _authError.value = 'The email address is not valid.';
        break;
      case 'user-disabled':
        _authError.value = 'This user account has been disabled.';
        break;
      case 'email-already-in-use':
        _authError.value = 'An account already exists with this email.';
        break;
      case 'weak-password':
        _authError.value = 'The password provided is too weak.';
        break;
      case 'operation-not-allowed':
        _authError.value = 'Email/password accounts are not enabled.';
        break;
      case 'too-many-requests':
        _authError.value = 'Too many requests. Please try again later.';
        break;
      default:
        _authError.value = e.message ?? AppConfig.genericErrorMessage;
    }
    AppLogger.warning('Auth exception: ${e.code} - ${e.message}');
  }
  
  /// Clear error message
  void clearError() {
    _authError.value = '';
  }
  
  /// Toggle password visibility
  void togglePasswordVisibility() {
    _isPasswordVisible.value = !_isPasswordVisible.value;
  }
  
  /// Check if current user can access admin features
  bool canAccessAdmin() {
    return _isLoggedIn.value && _isAdmin.value;
  }
  
  /// Check if current user can moderate content
  bool canModerateContent() {
    return _isLoggedIn.value && (_isAdmin.value || _isModerator.value);
  }
  
  /// Get user role display name
  String get userRoleDisplayName {
    if (!_isLoggedIn.value) return 'Guest';
    
    switch (_userModel.value?.role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.user:
      default:
        return 'User';
    }
  }
}