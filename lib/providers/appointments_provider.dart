import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/appointment_model.dart';
import '../services/app_api.dart';
import '../services/realtime_service.dart';

/// Enhanced Appointments provider using AsyncNotifier for better error handling
class AppointmentsNotifier extends AsyncNotifier<List<AppointmentModel>> {
  final RealtimeService _realtimeService = RealtimeService();
  final Uuid _uuid = const Uuid();

  @override
  Future<List<AppointmentModel>> build() async {
    // Initialize appointments from local storage
    final appointments = await AppApi.getAppointments();
    
    // Subscribe to realtime updates
    _subscribeToRealtimeUpdates();
    
    return appointments;
  }

  /// Subscribe to realtime appointment updates
  void _subscribeToRealtimeUpdates() {
    _realtimeService.appointmentsStream.listen((updatedAppointment) {
      state.whenData((appointments) {
        final existingIndex = appointments.indexWhere(
          (appointment) => appointment.id == updatedAppointment.id,
        );
        
        if (existingIndex != -1) {
          // Update existing appointment
          final updatedAppointments = List<AppointmentModel>.from(appointments);
          updatedAppointments[existingIndex] = updatedAppointment;
          state = AsyncValue.data(updatedAppointments);
        } else {
          // Add new appointment
          state = AsyncValue.data([...appointments, updatedAppointment]);
        }
      });
    });
  }

  /// Load appointments from local storage
  Future<void> loadAppointments() async {
    state = const AsyncValue.loading();
    try {
      final appointments = await AppApi.getAppointments();
      state = AsyncValue.data(appointments);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Load appointments for a specific customer
  Future<void> loadAppointmentsForCustomer(String customerId) async {
    print('🔧 AppointmentsProvider: Loading appointments for customer: $customerId');
    state = const AsyncValue.loading();
    try {
      final appointments = await AppApi.getAppointmentsByCustomer(customerId);
      print('🔧 AppointmentsProvider: Loaded ${appointments.length} appointments for customer');
      for (final appointment in appointments) {
        print('🔧 AppointmentsProvider: Appointment ${appointment.id} - ${appointment.startAt} - ${appointment.status}');
      }
      state = AsyncValue.data(appointments);
    } catch (error, stackTrace) {
      print('❌ AppointmentsProvider: Error loading customer appointments: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Load appointments for a specific salon
  Future<void> loadAppointmentsForSalon(String salonId) async {
    print('🔧 AppointmentsProvider: Loading appointments for salon: $salonId');
    state = const AsyncValue.loading();
    try {
      final appointments = await AppApi.getAppointmentsBySalon(salonId);
      print('🔧 AppointmentsProvider: Loaded ${appointments.length} appointments for salon');
      for (final appointment in appointments) {
        print('🔧 AppointmentsProvider: Appointment ${appointment.id} - ${appointment.startAt} - ${appointment.status}');
      }
      state = AsyncValue.data(appointments);
    } catch (error, stackTrace) {
      print('❌ AppointmentsProvider: Error loading salon appointments: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Book a new appointment
  Future<AppointmentModel?> bookAppointment({
    required String customerId,
    required String salonId,
    required String serviceId,
    required DateTime startAt,
    String? notes,
    String? staffId,
  }) async {
    try {
      print('🔧 AppointmentsProvider: Starting bookAppointment...');
      print('🔧 AppointmentsProvider: Service ID: $serviceId');
      
      // Get service to calculate end time and price
      final service = await AppApi.getServiceById(serviceId);
      print('🔧 AppointmentsProvider: Service retrieved: ${service.name}');
      
      final endAt = startAt.add(Duration(minutes: service.durationMinutes));
      
      final appointment = AppointmentModel(
        id: _uuid.v4(),
        customerId: customerId,
        salonId: salonId,
        serviceId: serviceId,
        staffId: staffId,
        startAt: startAt,
        endAt: endAt,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: AppointmentStatus.pending,
        paymentStatus: PaymentStatus.pending,
        totalAmount: service.price,
        duration: service.durationMinutes,
        price: service.price,
        notes: notes,
      );
      
      print('🔧 AppointmentsProvider: Calling AppApi.createAppointment...');
      final savedAppointment = await AppApi.createAppointment(appointment);
      print('🔧 AppointmentsProvider: Appointment created: ${savedAppointment.id}');
      
      // Update state
      state.whenData((appointments) {
        state = AsyncValue.data([...appointments, savedAppointment]);
      });
      
      return savedAppointment;
    } catch (error, stackTrace) {
      print('❌ AppointmentsProvider: Error: $error');
      print('❌ AppointmentsProvider: StackTrace: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Update appointment status
  Future<AppointmentModel?> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  ) async {
    try {
      final updatedAppointment = await AppApi.updateAppointmentStatus(
        appointmentId,
        status,
      );
      
      // Update state
      state.whenData((appointments) {
        final updatedAppointments = appointments.map((appointment) {
          return appointment.id == appointmentId ? updatedAppointment : appointment;
        }).toList();
        state = AsyncValue.data(updatedAppointments);
      });
      
      return updatedAppointment;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Cancel an appointment
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      await AppApi.cancelAppointment(appointmentId);
      
      // Update state
      state.whenData((appointments) {
        final updatedAppointments = appointments.map((appointment) {
          if (appointment.id == appointmentId) {
            return appointment.copyWith(
              status: AppointmentStatus.cancelled,
              updatedAt: DateTime.now(),
            );
          }
          return appointment;
        }).toList();
        state = AsyncValue.data(updatedAppointments);
      });
      
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Delete an appointment
  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      await AppApi.deleteAppointment(appointmentId);
      
      // Update state
      state.whenData((appointments) {
        state = AsyncValue.data(appointments.where(
          (appointment) => appointment.id != appointmentId,
        ).toList());
      });
      
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Get appointment by ID
  AppointmentModel? getAppointmentById(String appointmentId) {
    final currentState = state;
    if (!currentState.hasValue) return null;
    
    try {
      return currentState.value!.firstWhere(
        (appointment) => appointment.id == appointmentId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Refresh appointments
  Future<void> refreshAppointments() async {
    await loadAppointments();
  }
}

/// Enhanced Appointments provider using AsyncNotifier
final appointmentsProvider = AsyncNotifierProvider<AppointmentsNotifier, List<AppointmentModel>>(() {
  return AppointmentsNotifier();
});

/// Appointments by customer provider
final appointmentsByCustomerProvider = FutureProvider.family<List<AppointmentModel>, String>((ref, customerId) async {
  final appointmentsNotifier = ref.read(appointmentsProvider.notifier);
  await appointmentsNotifier.loadAppointmentsForCustomer(customerId);
  final appointmentsAsync = ref.read(appointmentsProvider);
  return appointmentsAsync.when(
    data: (appointments) => appointments.where((appointment) => appointment.customerId == customerId).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Appointments by salon provider
final appointmentsBySalonProvider = FutureProvider.family<List<AppointmentModel>, String>((ref, salonId) async {
  final appointmentsNotifier = ref.read(appointmentsProvider.notifier);
  await appointmentsNotifier.loadAppointmentsForSalon(salonId);
  final appointmentsAsync = ref.read(appointmentsProvider);
  return appointmentsAsync.when(
    data: (appointments) => appointments.where((appointment) => appointment.salonId == salonId).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Single appointment provider
final appointmentProvider = Provider.family<AppointmentModel?, String>((ref, appointmentId) {
  final appointmentsAsync = ref.watch(appointmentsProvider);
  return appointmentsAsync.when(
    data: (appointments) {
      try {
        return appointments.firstWhere((appointment) => appointment.id == appointmentId);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Upcoming appointments provider
final upcomingAppointmentsProvider = Provider<List<AppointmentModel>>((ref) {
  final appointmentsAsync = ref.watch(appointmentsProvider);
  return appointmentsAsync.when(
    data: (appointments) {
      final now = DateTime.now();
      return appointments.where(
        (appointment) => appointment.startAt.isAfter(now) &&
            appointment.status != AppointmentStatus.cancelled,
      ).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Past appointments provider
final pastAppointmentsProvider = Provider<List<AppointmentModel>>((ref) {
  final appointmentsAsync = ref.watch(appointmentsProvider);
  return appointmentsAsync.when(
    data: (appointments) {
      final now = DateTime.now();
      return appointments.where(
        (appointment) => appointment.startAt.isBefore(now) ||
            appointment.status == AppointmentStatus.completed,
      ).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});