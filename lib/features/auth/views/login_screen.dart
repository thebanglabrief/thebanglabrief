import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../controllers/auth_controller.dart';

/// Login Screen
/// 
/// Provides user authentication with email/password and admin login.
/// Features Material Design 3 components and responsive layout.
class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryBlueDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and title section
                  _buildHeader(),
                  
                  const SizedBox(height: 48),
                  
                  // Login form
                  _buildLoginForm(context),
                  
                  const SizedBox(height: 24),
                  
                  // Alternative actions
                  _buildAlternativeActions(),
                  
                  const SizedBox(height: 32),
                  
                  // Quick admin access
                  _buildAdminQuickAccess(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build header with logo and app name
  Widget _buildHeader() {
    return Column(
      children: [
        // App logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.play_circle_fill,
            size: 48,
            color: AppTheme.primaryBlue,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // App name
        const Text(
          AppConfig.appName,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Welcome message
        Text(
          'Welcome back!',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  /// Build login form
  Widget _buildLoginForm(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Form title
            Text(
              'Sign In',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlueDark,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Email field
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email or Username',
                hintText: 'Enter your email or username',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email or username';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Password field
            Obx(() => TextFormField(
              controller: passwordController,
              obscureText: !controller.isPasswordVisible.value,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordVisible.value 
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
              onFieldSubmitted: (_) => _performLogin(
                formKey, 
                emailController.text, 
                passwordController.text,
              ),
            )),
            
            const SizedBox(height: 8),
            
            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                child: const Text('Forgot password?'),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Error message
            Obx(() => controller.authError.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.authError,
                            style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink()),
            
            // Login button
            Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => _performLogin(
                        formKey,
                        emailController.text,
                        passwordController.text,
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            )),
          ],
        ),
      ),
    );
  }

  /// Build alternative actions
  Widget _buildAlternativeActions() {
    return Column(
      children: [
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Register button
        OutlinedButton(
          onPressed: () => Get.toNamed(AppRoutes.register),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Create New Account',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Continue as guest
        TextButton(
          onPressed: () => Get.offAllNamed(AppRoutes.mainNavigation),
          child: Text(
            'Continue as Guest',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Build admin quick access
  Widget _buildAdminQuickAccess() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Admin Access',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Use: ${AppConfig.adminUsername} / ${AppConfig.adminPassword}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          
          const SizedBox(height: 12),
          
          ElevatedButton(
            onPressed: () => _performAdminLogin(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Quick Admin Login',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Perform login with validation
  Future<void> _performLogin(
    GlobalKey<FormState> formKey,
    String email,
    String password,
  ) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    controller.clearError();
    
    final success = await controller.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (success) {
      Get.offAllNamed(AppRoutes.mainNavigation);
    }
  }

  /// Perform admin login
  Future<void> _performAdminLogin() async {
    controller.clearError();
    
    final success = await controller.signInWithEmailAndPassword(
      email: AppConfig.adminUsername,
      password: AppConfig.adminPassword,
    );

    if (success) {
      Get.offAllNamed(AppRoutes.mainNavigation);
    }
  }
}