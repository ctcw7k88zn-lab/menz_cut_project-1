import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../widgets/glass_card.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Title
                GlassCard(
                  width: 120,
                  height: 120,
                  borderRadius: 60,
                  color: Colors.white.withOpacity(0.2),
                  child: Icon(
                    Icons.content_cut,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing32),
                
                Text(
                  'Welcome to Salon App',
                  style: AppTheme.headingLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing16),
                
                Text(
                  'Choose how you\'d like to use the app',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing48),
                
                // Customer option
                GlassCard(
                  onTap: () => context.go('/login?role=customer'),
                  margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMauve.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: AppTheme.primaryMauve,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I\'m a Customer',
                              style: AppTheme.headingSmall.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing4),
                            Text(
                              'Book appointments and find salons',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppTheme.textSecondary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                
                // Salon Owner option
                GlassCard(
                  onTap: () => context.go('/login?role=owner'),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          Icons.store,
                          size: 30,
                          color: AppTheme.accentGold,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I\'m a Salon Owner',
                              style: AppTheme.headingSmall.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing4),
                            Text(
                              'Manage appointments and grow your business',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppTheme.textSecondary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacing48),
                
                // Sign up link
                TextButton(
                  onPressed: () => context.go('/signup'),
                  child: Text(
                    'Don\'t have an account? Sign up',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
