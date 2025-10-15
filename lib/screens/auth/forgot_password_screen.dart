import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_button.dart' as custom;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryMauve,
              AppTheme.backgroundWhite,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.surfaceLight,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing32),

                  // Header
                  Text(
                    'Forgot Password?',
                    style: AppTheme.headingLarge.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    'Don\'t worry! Enter your email address and we\'ll send you a link to reset your password.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing32),

                  // Email field
                  GlassCard(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),

                  // Send reset link button
                  SizedBox(
                    width: double.infinity,
                    child: custom.PrimaryButton(
                      text: 'Send Reset Link',
                      onPressed: _isLoading ? null : _sendResetLink,
                      isLoading: _isLoading,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),

                  // Back to login
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Back to Login',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryMauve,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Help text
                  Center(
                    child: Text(
                      'If you don\'t receive an email within a few minutes, check your spam folder.',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement password reset API call
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
