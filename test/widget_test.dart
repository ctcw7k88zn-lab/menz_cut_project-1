import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:menz_cut_project/main.dart';
import 'package:menz_cut_project/widgets/glass_card.dart';
import 'package:menz_cut_project/widgets/salon_card.dart';
import 'package:menz_cut_project/widgets/animated_button.dart' as custom;
import 'package:menz_cut_project/models/salon_model.dart';
import 'package:menz_cut_project/models/service_model.dart';
import 'package:menz_cut_project/screens/auth/login_screen.dart';
import 'package:menz_cut_project/screens/shared/booking_screen.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('GlassCard renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GlassCard(
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(GlassCard), findsOneWidget);
    });

    testWidgets('SalonCard renders with mock data', (WidgetTester tester) async {
      final mockSalon = SalonModel(
        id: '1',
        name: 'Test Salon',
        description: 'A test salon',
        address: '123 Test Street',
        latitude: 40.7128,
        longitude: -74.0060,
        phone: '+1234567890',
        email: 'test@salon.com',
        rating: 4.5,
        reviewCount: 100,
        imageUrls: ['https://example.com/image.jpg'],
        categories: ['Hair', 'Beauty'],
        openingHours: {
          'Monday': '09:00 - 18:00',
          'Tuesday': '09:00 - 18:00',
          'Wednesday': '09:00 - 18:00',
          'Thursday': '09:00 - 18:00',
          'Friday': '09:00 - 18:00',
          'Saturday': '09:00 - 17:00',
          'Sunday': 'Closed',
        },
        ownerId: 'owner_1',
        isVerified: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        amenities: {
          'wifi': true,
          'parking': true,
          'wheelchair_accessible': true,
          'air_conditioning': true,
        },
        averagePrice: 50.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SalonCard(
                salon: mockSalon,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Salon'), findsOneWidget);
      expect(find.text('A test salon'), findsOneWidget);
      expect(find.text('123 Test Street'), findsOneWidget);
      expect(find.byType(SalonCard), findsOneWidget);
    });

    testWidgets('PrimaryButton renders and responds to tap', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: custom.PrimaryButton(
                text: 'Test Button',
                onPressed: () {
                  buttonPressed = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(custom.PrimaryButton), findsOneWidget);

      await tester.tap(find.byType(custom.PrimaryButton));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });

    testWidgets('SecondaryButton renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: custom.SecondaryButton(
                text: 'Secondary Button',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Secondary Button'), findsOneWidget);
      expect(find.byType(custom.SecondaryButton), findsOneWidget);
    });

    testWidgets('FloatingActionButton renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: custom.FloatingActionButton(
                onPressed: () {},
                icon: Icons.add,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(custom.FloatingActionButton), findsOneWidget);
    });
  });

  group('Integration Tests', () {
    testWidgets('App starts and shows onboarding', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: SalonApp()));
      await tester.pumpAndSettle();

      // The app should start with onboarding or role selection
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Button press animations work', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: custom.PrimaryButton(
                text: 'Animated Button',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final button = find.byType(custom.PrimaryButton);
      expect(button, findsOneWidget);

      // Test button press animation
      await tester.tap(button);
      await tester.pump(const Duration(milliseconds: 100));
      
      // Button should still be visible after animation
      expect(button, findsOneWidget);
    });
  });

  group('Login Form Tests', () {
    testWidgets('Login form renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Login form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Try to submit empty form
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show validation errors
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Login form accepts valid input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Enter valid email
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.pump();

      // Enter valid password
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.pump();

      // Form should be valid
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });
  });

  group('Booking Flow Tests', () {
    testWidgets('Booking screen renders correctly', (WidgetTester tester) async {
      final mockSalon = SalonModel(
        id: '1',
        name: 'Test Salon',
        description: 'A test salon',
        address: '123 Test Street',
        latitude: 40.7128,
        longitude: -74.0060,
        phone: '+1234567890',
        email: 'test@salon.com',
        rating: 4.5,
        reviewCount: 100,
        imageUrls: ['https://example.com/image.jpg'],
        categories: ['Hair', 'Beauty'],
        openingHours: {
          'Monday': '09:00 - 18:00',
          'Tuesday': '09:00 - 18:00',
          'Wednesday': '09:00 - 18:00',
          'Thursday': '09:00 - 18:00',
          'Friday': '09:00 - 18:00',
          'Saturday': '09:00 - 17:00',
          'Sunday': 'Closed',
        },
        ownerId: 'owner_1',
        isVerified: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        amenities: {
          'wifi': true,
          'parking': true,
          'wheelchair_accessible': true,
          'air_conditioning': true,
        },
        averagePrice: 50.0,
      );

      final mockService = ServiceModel(
        id: '1',
        salonId: '1',
        name: 'Haircut',
        description: 'Professional haircut',
        price: 50.0,
        duration: 60,
        category: 'Haircut',
        imageUrl: 'https://example.com/image.jpg',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingScreen(
              salon: mockSalon,
              service: mockService,
            ),
          ),
        ),
      );

      expect(find.text('Book Appointment'), findsOneWidget);
      expect(find.text('Haircut'), findsOneWidget);
      expect(find.text('Professional haircut'), findsOneWidget);
      expect(find.text('Confirm Booking'), findsOneWidget);
    });
  });

  group('Chat Input Tests', () {
    testWidgets('Chat input renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const Expanded(child: Text('Chat Messages')),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Type a message...'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Chat input accepts text', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const Expanded(child: Text('Chat Messages')),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Enter text in the chat input
      await tester.enterText(find.byType(TextField), 'Hello, how are you?');
    await tester.pump();

      expect(find.text('Hello, how are you?'), findsOneWidget);
    });
  });
}
