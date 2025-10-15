import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/service_model.dart';
import '../services/app_api.dart';
import '../services/realtime_service.dart';

/// Enhanced Services provider using AsyncNotifier for better error handling
class ServicesNotifier extends AsyncNotifier<List<ServiceModel>> {
  final RealtimeService _realtimeService = RealtimeService();
  final Uuid _uuid = const Uuid();

  @override
  Future<List<ServiceModel>> build() async {
    // Initialize services from local storage
    final services = await AppApi.getServices();
    
    // Subscribe to realtime updates
    _subscribeToRealtimeUpdates();
    
    return services;
  }

  /// Subscribe to realtime service updates
  void _subscribeToRealtimeUpdates() {
    _realtimeService.servicesStream.listen((updatedService) {
      if (updatedService.isActive) {
        // Update or add service
        state.whenData((services) {
          final existingIndex = services.indexWhere(
            (service) => service.id == updatedService.id,
          );
          
          if (existingIndex != -1) {
            // Update existing service
            final updatedServices = List<ServiceModel>.from(services);
            updatedServices[existingIndex] = updatedService;
            state = AsyncValue.data(updatedServices);
          } else {
            // Add new service
            state = AsyncValue.data([...services, updatedService]);
          }
        });
      } else {
        // Remove inactive service
        state.whenData((services) {
          state = AsyncValue.data(services.where(
            (service) => service.id != updatedService.id,
          ).toList());
        });
      }
    });
  }

  /// Load services from local storage
  Future<void> loadServices() async {
    state = const AsyncValue.loading();
    try {
      final services = await AppApi.getServices();
      state = AsyncValue.data(services);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Get services by salon ID
  Future<List<ServiceModel>> getServicesBySalon(String salonId) async {
    try {
      return await AppApi.getServicesBySalon(salonId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return [];
    }
  }

  /// Add a new service
  Future<ServiceModel?> addService(ServiceModel service) async {
    try {
      final newService = service.copyWith(
        id: service.id.isEmpty ? _uuid.v4() : service.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final savedService = await AppApi.addService(newService);
      
      // Update state
      state.whenData((services) {
        state = AsyncValue.data([...services, savedService]);
      });
      
      return savedService;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Update an existing service
  Future<ServiceModel?> updateService(ServiceModel service) async {
    try {
      final updatedService = service.copyWith(
        updatedAt: DateTime.now(),
      );
      
      final savedService = await AppApi.updateService(updatedService);
      
      // Update state
      state.whenData((services) {
        final updatedServices = services.map((s) {
          return s.id == savedService.id ? savedService : s;
        }).toList();
        state = AsyncValue.data(updatedServices);
      });
      
      return savedService;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Delete a service
  Future<bool> deleteService(String serviceId) async {
    try {
      await AppApi.deleteService(serviceId);
      
      // Update state
      state.whenData((services) {
        state = AsyncValue.data(services.where(
          (service) => service.id != serviceId,
        ).toList());
      });
      
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Get service by ID
  ServiceModel? getServiceById(String serviceId) {
    return state.whenData((services) {
      try {
        return services.firstWhere(
          (service) => service.id == serviceId,
        );
      } catch (e) {
        return null;
      }
    }).value;
  }

  /// Refresh services
  Future<void> refreshServices() async {
    await loadServices();
  }
}

/// Enhanced Services provider using AsyncNotifier
final servicesProvider = AsyncNotifierProvider<ServicesNotifier, List<ServiceModel>>(() {
  return ServicesNotifier();
});

/// Services by salon provider
final servicesBySalonProvider = FutureProvider.family<List<ServiceModel>, String>((ref, salonId) async {
  final servicesNotifier = ref.read(servicesProvider.notifier);
  return await servicesNotifier.getServicesBySalon(salonId);
});

/// Single service provider
final serviceProvider = Provider.family<ServiceModel?, String>((ref, serviceId) {
  final servicesNotifier = ref.read(servicesProvider.notifier);
  return servicesNotifier.getServiceById(serviceId);
});