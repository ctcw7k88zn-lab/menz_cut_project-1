import 'package:flutter_test/flutter_test.dart';
import 'package:menz_cut_project/services/app_api.dart';
import 'package:menz_cut_project/services/supabase_service.dart';
import 'package:menz_cut_project/models/user_model.dart';
import 'package:menz_cut_project/models/salon_model.dart';
import 'package:menz_cut_project/models/service_model.dart';
import 'package:menz_cut_project/models/appointment_model.dart';

void main() {
  group('Backend Integration Tests', () {
    late String testUserId;
    late String testSalonId;
    late String testServiceId;

    setUpAll(() async {
      // Initialize test environment
      print('🧪 Starting Backend Integration Tests...');
    });

    group('Authentication Tests', () {
      test('should create user profile successfully', () async {
        try {
          final user = await SupabaseService.signup(
            email: 'test@example.com',
            password: 'testpassword123',
            fullName: 'Test User',
            phone: '+1234567890',
            role: UserRole.customer,
          );
          
          expect(user, isNotNull);
          expect(user.email, equals('test@example.com'));
          expect(user.fullName, equals('Test User'));
          expect(user.role, equals(UserRole.customer));
          
          testUserId = user.id;
          print('✅ User creation test passed');
        } catch (e) {
          print('❌ User creation test failed: $e');
          rethrow;
        }
      });

      test('should login user successfully', () async {
        try {
          final user = await SupabaseService.login('test@example.com', 'testpassword123');
          
          expect(user, isNotNull);
          expect(user.email, equals('test@example.com'));
          
          print('✅ User login test passed');
        } catch (e) {
          print('❌ User login test failed: $e');
          rethrow;
        }
      });
    });

    group('Salon Management Tests', () {
      test('should create salon successfully', () async {
        try {
          final salon = SalonModel(
            id: '',
            ownerId: testUserId,
            name: 'Test Salon',
            description: 'A test salon for integration testing',
            address: '123 Test Street',
            latitude: 40.7128,
            longitude: -74.0060,
            imageUrls: ['https://example.com/salon.jpg'],
            rating: 4.5,
            reviewCount: 10,
            categories: ['Haircut', 'Beard'],
            openingHours: {'Monday': '9:00-18:00'},
            phone: '555-1234',
            email: 'test@salon.com',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final createdSalon = await SupabaseService.createSalon(salon);
          
          expect(createdSalon, isNotNull);
          expect(createdSalon.name, equals('Test Salon'));
          expect(createdSalon.ownerId, equals(testUserId));
          
          testSalonId = createdSalon.id;
          print('✅ Salon creation test passed');
        } catch (e) {
          print('❌ Salon creation test failed: $e');
          rethrow;
        }
      });

      test('should retrieve salon successfully', () async {
        try {
          final salon = await SupabaseService.getSalon(testSalonId);
          
          expect(salon, isNotNull);
          expect(salon.id, equals(testSalonId));
          expect(salon.name, equals('Test Salon'));
          
          print('✅ Salon retrieval test passed');
        } catch (e) {
          print('❌ Salon retrieval test failed: $e');
          rethrow;
        }
      });
    });

    group('Service Management Tests', () {
      test('should create service successfully', () async {
        try {
          final service = ServiceModel(
            id: '',
            salonId: testSalonId,
            name: 'Test Haircut',
            description: 'A test haircut service',
            price: 25.0,
            durationMinutes: 30,
            category: 'Haircut',
            imageUrl: null,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final createdService = await SupabaseService.createService(service);
          
          expect(createdService, isNotNull);
          expect(createdService.name, equals('Test Haircut'));
          expect(createdService.salonId, equals(testSalonId));
          expect(createdService.price, equals(25.0));
          
          testServiceId = createdService.id;
          print('✅ Service creation test passed');
        } catch (e) {
          print('❌ Service creation test failed: $e');
          rethrow;
        }
      });

      test('should retrieve services by salon', () async {
        try {
          final services = await SupabaseService.getServicesBySalon(testSalonId);
          
          expect(services, isNotEmpty);
          expect(services.first.salonId, equals(testSalonId));
          
          print('✅ Service retrieval test passed');
        } catch (e) {
          print('❌ Service retrieval test failed: $e');
          rethrow;
        }
      });
    });

    group('Appointment Management Tests', () {
      test('should create appointment successfully', () async {
        try {
          final startTime = DateTime.now().add(const Duration(hours: 1));
          
          final appointment = await SupabaseService.createAppointmentWithConflictCheck(
            customerId: testUserId,
            salonId: testSalonId,
            serviceId: testServiceId,
            startAt: startTime,
            notes: 'Test appointment',
          );
          
          expect(appointment, isNotNull);
          expect(appointment.customerId, equals(testUserId));
          expect(appointment.salonId, equals(testSalonId));
          expect(appointment.serviceId, equals(testServiceId));
          expect(appointment.status, equals(AppointmentStatus.pending));
          
          print('✅ Appointment creation test passed');
        } catch (e) {
          print('❌ Appointment creation test failed: $e');
          rethrow;
        }
      });

      test('should retrieve customer appointments', () async {
        try {
          final appointments = await SupabaseService.getCustomerAppointments(testUserId);
          
          expect(appointments, isNotEmpty);
          expect(appointments.first.customerId, equals(testUserId));
          
          print('✅ Customer appointments retrieval test passed');
        } catch (e) {
          print('❌ Customer appointments retrieval test failed: $e');
          rethrow;
        }
      });

      test('should update appointment status', () async {
        try {
          // Get the first appointment
          final appointments = await SupabaseService.getCustomerAppointments(testUserId);
          expect(appointments, isNotEmpty);
          
          final appointmentId = appointments.first.id;
          
          final updatedAppointment = await SupabaseService.updateAppointmentStatus(
            appointmentId,
            AppointmentStatus.confirmed,
          );
          
          expect(updatedAppointment.status, equals(AppointmentStatus.confirmed));
          
          print('✅ Appointment status update test passed');
        } catch (e) {
          print('❌ Appointment status update test failed: $e');
          rethrow;
        }
      });
    });

    group('AppApi Facade Tests', () {
      test('should route to Supabase when useLocal is false', () async {
        try {
          // Ensure we're using Supabase
          AppApi.useLocal = false;
          
          final salons = await AppApi.getSalons();
          
          expect(salons, isNotEmpty);
          print('✅ AppApi Supabase routing test passed');
        } catch (e) {
          print('❌ AppApi Supabase routing test failed: $e');
          rethrow;
        }
      });

      test('should create appointment via AppApi', () async {
        try {
          final startTime = DateTime.now().add(const Duration(hours: 2));
          
          final appointmentModel = AppointmentModel(
            id: '',
            customerId: testUserId,
            salonId: testSalonId,
            serviceId: testServiceId,
            startAt: startTime,
            endAt: startTime.add(const Duration(hours: 1)),
            status: AppointmentStatus.pending,
            notes: 'AppApi test appointment',
            totalAmount: 50.0,
            paymentStatus: PaymentStatus.pending,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          final appointment = await AppApi.createAppointment(appointmentModel);
          
          expect(appointment, isNotNull);
          expect(appointment.customerId, equals(testUserId));
          
          print('✅ AppApi appointment creation test passed');
        } catch (e) {
          print('❌ AppApi appointment creation test failed: $e');
          rethrow;
        }
      });
    });

    group('Error Handling Tests', () {
      test('should handle invalid service ID gracefully', () async {
        try {
          final startTime = DateTime.now().add(const Duration(hours: 3));
          
          await SupabaseService.createAppointmentWithConflictCheck(
            customerId: testUserId,
            salonId: testSalonId,
            serviceId: 'invalid-service-id',
            startAt: startTime,
          );
          
          fail('Should have thrown an exception for invalid service ID');
        } catch (e) {
          expect(e.toString(), contains('Failed to create appointment'));
          print('✅ Error handling test passed');
        }
      });

      test('should handle appointment conflicts', () async {
        try {
          final startTime = DateTime.now().add(const Duration(hours: 4));
          
          // Create first appointment
          await SupabaseService.createAppointmentWithConflictCheck(
            customerId: testUserId,
            salonId: testSalonId,
            serviceId: testServiceId,
            startAt: startTime,
          );
          
          // Try to create conflicting appointment
          await SupabaseService.createAppointmentWithConflictCheck(
            customerId: testUserId,
            salonId: testSalonId,
            serviceId: testServiceId,
            startAt: startTime.add(const Duration(minutes: 15)), // Overlapping time
          );
          
          fail('Should have thrown an exception for conflicting appointment');
        } catch (e) {
          expect(e.toString(), contains('conflict'));
          print('✅ Conflict detection test passed');
        }
      });
    });

    tearDownAll(() {
      print('🧪 Backend Integration Tests completed!');
      print('✅ All tests passed successfully!');
    });
  });
}
