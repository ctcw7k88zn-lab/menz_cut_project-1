import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_theme.dart';
import 'config/app_env.dart';
import 'services/local_data_service.dart';
import 'providers/auth_provider.dart';
import 'models/salon_model.dart';
import 'models/service_model.dart';
import 'screens/onboarding.dart';
import 'screens/auth/role_select_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/customer/customer_home.dart';
import 'screens/customer/customer_appointments.dart';
import 'screens/customer/customer_profile.dart';
import 'screens/customer/customer_map.dart';
import 'screens/customer/customer_salon_list.dart';
import 'screens/customer/ai_hair_suggestions.dart';
import 'screens/owner/owner_dashboard.dart';
import 'screens/owner/owner_profile.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/shared/salon_detail_screen.dart';
import 'screens/shared/booking_screen.dart';
import 'screens/shared/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print('No .env file found, using default values');
    }
    
    // Initialize Supabase with environment variables or defaults
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? 'http://192.168.1.8:54321',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
    );
    
    print('✅ Supabase initialized successfully');
    print('🔗 Supabase URL: ${dotenv.env['SUPABASE_URL'] ?? 'http://192.168.1.8:54321'}');
    print('🔑 Using Supabase backend: ${!AppEnv.enableMock}');
    
    // Initialize local data service (Hive) - keep for fallback
    await LocalDataService.init();
    
    runApp(const ProviderScope(child: SalonApp()));
  } catch (e) {
    print('❌ Failed to initialize app: $e');
    // Show error dialog or fallback UI
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to initialize app: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Retry initialization
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class SalonApp extends ConsumerStatefulWidget {
  const SalonApp({super.key});

  @override
  ConsumerState<SalonApp> createState() => _SalonAppState();
}

class _SalonAppState extends ConsumerState<SalonApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Initialize auth state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initialize();
    });
    _router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/role-select',
          builder: (context, state) => const RoleSelectScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/customer-home',
          builder: (context, state) => const CustomerHomeScreen(),
        ),
        GoRoute(
          path: '/customer-appointments',
          builder: (context, state) => const CustomerAppointmentsScreen(),
        ),
        GoRoute(
          path: '/customer-profile',
          builder: (context, state) => const CustomerProfileScreen(),
        ),
        GoRoute(
          path: '/customer-map',
          builder: (context, state) => const CustomerMapScreen(),
        ),
        GoRoute(
          path: '/customer-salon-list',
          builder: (context, state) => const CustomerSalonListScreen(),
        ),
        GoRoute(
          path: '/ai-hair-suggestions',
          builder: (context, state) => const AIHairSuggestionsScreen(),
        ),
        GoRoute(
          path: '/owner-dashboard',
          builder: (context, state) => const OwnerDashboardScreen(),
        ),
        // Keep individual routes for backward compatibility
        GoRoute(
          path: '/owner-home',
          builder: (context, state) => const OwnerDashboardScreen(),
        ),
        GoRoute(
          path: '/owner-analytics',
          builder: (context, state) => const OwnerDashboardScreen(),
        ),
        GoRoute(
          path: '/owner-services',
          builder: (context, state) => const OwnerDashboardScreen(),
        ),
        GoRoute(
          path: '/owner-appointments',
          builder: (context, state) => const OwnerDashboardScreen(),
        ),
        GoRoute(
          path: '/owner-chat',
          builder: (context, state) => const OwnerDashboardScreen(),
        ),
        GoRoute(
          path: '/owner-profile',
          builder: (context, state) => const OwnerProfileScreen(),
        ),
        GoRoute(
          path: '/salon-detail',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            if (extra != null && extra['salon'] != null) {
              return SalonDetailScreen(salon: extra['salon']);
            }
            // Fallback - create a mock salon
            return SalonDetailScreen(
              salon: SalonModel(
                id: 'salon_1',
                name: 'Style Studio',
                description: 'Premium hair salon',
                address: '123 Fashion Street',
                latitude: 40.7128,
                longitude: -74.0060,
                imageUrls: ['https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400'],
                rating: 4.8,
                reviewCount: 156,
                categories: ['Haircut', 'Coloring'],
                openingHours: {},
                phone: '+1 (555) 123-4567',
                email: 'info@stylestudio.com',
                ownerId: 'owner_1',
                isVerified: true,
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
          },
        ),
        GoRoute(
          path: '/booking',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            if (extra != null) {
              return BookingScreen(
                salon: extra['salon'] as SalonModel,
                service: extra['service'] as ServiceModel,
              );
            }
            return const Scaffold(
              body: Center(child: Text('Invalid booking parameters')),
            );
          },
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        
        // If not initialized, stay on current route
        if (!authState.isInitialized) {
          return null;
        }
        
        // If not authenticated and not on auth routes, redirect to role select
        if (!authState.isAuthenticated) {
          if (state.uri.path == '/onboarding' || 
              state.uri.path == '/role-select' ||
              state.uri.path == '/login' ||
              state.uri.path == '/signup') {
            return null;
          }
          return '/role-select';
        }
        
        // If authenticated, redirect to appropriate home only if on auth routes
        if (authState.isCustomer) {
          // Allow customer to navigate to any customer route
          if (state.uri.path.startsWith('/customer-') || 
              state.uri.path == '/ai-hair-suggestions' ||
              state.uri.path == '/salon-detail' ||
              state.uri.path == '/booking' ||
              state.uri.path == '/notifications') {
            return null; // Allow navigation
          }
          // Redirect to customer home if on other routes
          return '/customer-home';
        } else if (authState.isSalonOwner) {
          // Allow salon owner to navigate to any owner route
          if (state.uri.path.startsWith('/owner-') ||
              state.uri.path == '/salon-detail' ||
              state.uri.path == '/booking' ||
              state.uri.path == '/notifications') {
            return null; // Allow navigation
          }
          // Redirect to owner home if on other routes
          return '/owner-home';
        }
        
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Salon Appointment App',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
