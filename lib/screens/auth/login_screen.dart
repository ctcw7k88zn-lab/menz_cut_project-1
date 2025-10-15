import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_button.dart' as custom;
import '../../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      final authState = ref.read(authProvider);
      if (authState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } else if (authState.isAuthenticated) {
        // Navigate based on user role
        if (authState.isCustomer) {
          context.go('/customer-home');
        } else if (authState.isSalonOwner) {
          context.go('/owner-home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.spacing48),
                
                // Logo
                Center(
                  child: GlassCard(
                    width: 100,
                    height: 100,
                    borderRadius: 50,
                    color: Colors.white.withOpacity(0.2),
                    child: Icon(
                      Icons.content_cut,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing32),
                
                // Title
                Text(
                  'Welcome Back',
                  style: AppTheme.headingLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing8),
                
                Text(
                  'Sign in to your account',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing48),
                
                // Login form
                GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTheme.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: AppTheme.textSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceLight,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: AppTheme.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: AppTheme.textSecondary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceLight,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacing24),
                        
                        // Login button
                        custom.PrimaryButton(
                          text: 'Sign In',
                          onPressed: authState.isLoading ? null : _login,
                          isLoading: authState.isLoading,
                          width: double.infinity,
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        
                        // Forgot password
                        TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password
                          },
                          child: Text(
                            'Forgot Password?',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryMauve,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing32),
                
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: Text(
                        'Sign Up',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
