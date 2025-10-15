import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_button.dart' as custom;
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.customer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authProvider.notifier).signup(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole,
        );
        
        final authState = ref.read(authProvider);
        if (authState.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Signup failed: ${authState.error}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        } else if (authState.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signup successful! You can now login with your credentials.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          context.go('/login');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
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
                const SizedBox(height: AppTheme.spacing32),
                
                // Logo
                Center(
                  child: GlassCard(
                    width: 80,
                    height: 80,
                    borderRadius: 40,
                    color: Colors.white.withOpacity(0.2),
                    child: Icon(
                      Icons.content_cut,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),
                
                // Title
                Text(
                  'Create Account',
                  style: AppTheme.headingLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing8),
                
                Text(
                  'Join our community today',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing32),
                
                // Signup form
                GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Role selection
                        Text(
                          'I am a:',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedRole = UserRole.customer),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacing16,
                                    vertical: AppTheme.spacing12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedRole == UserRole.customer
                                        ? AppTheme.primaryMauve
                                        : AppTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    border: Border.all(
                                      color: _selectedRole == UserRole.customer
                                          ? AppTheme.primaryMauve
                                          : AppTheme.textLight,
                                    ),
                                  ),
                                  child: Text(
                                    'Customer',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: _selectedRole == UserRole.customer
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedRole = UserRole.salonOwner),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacing16,
                                    vertical: AppTheme.spacing12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedRole == UserRole.salonOwner
                                        ? AppTheme.primaryMauve
                                        : AppTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    border: Border.all(
                                      color: _selectedRole == UserRole.salonOwner
                                          ? AppTheme.primaryMauve
                                          : AppTheme.textLight,
                                    ),
                                  ),
                                  child: Text(
                                    'Salon Owner',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: _selectedRole == UserRole.salonOwner
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacing24),
                        
                        // Name field
                        TextFormField(
                          controller: _nameController,
                          style: AppTheme.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(
                              Icons.person_outline,
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
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        
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
                        
                        // Phone field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: AppTheme.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'Enter your phone number',
                            prefixIcon: Icon(
                              Icons.phone_outlined,
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
                              return 'Please enter your phone number';
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
                        const SizedBox(height: AppTheme.spacing16),
                        
                        // Confirm password field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: AppTheme.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Confirm your password',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: AppTheme.textSecondary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
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
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacing24),
                        
                        // Signup button
                        custom.PrimaryButton(
                          text: 'Create Account',
                          onPressed: authState.isLoading ? null : _signup,
                          isLoading: authState.isLoading,
                          width: double.infinity,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Sign In',
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
