import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_model.dart';

class ServiceState {
  final List<ServiceModel> services;
  final bool isLoading;
  final String? error;

  const ServiceState({
    this.services = const [],
    this.isLoading = false,
    this.error,
  });

  ServiceState copyWith({
    List<ServiceModel>? services,
    bool? isLoading,
    String? error,
  }) {
    return ServiceState(
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ServiceNotifier extends StateNotifier<ServiceState> {
  ServiceNotifier() : super(const ServiceState()) {
    _loadServices();
  }

  void _loadServices() {
    state = state.copyWith(isLoading: true);
    
    // Simulate loading delay
    Future.delayed(const Duration(seconds: 1), () {
      final mockServices = [
        ServiceModel(
          id: 'service_1',
          name: 'Classic Haircut',
          description: 'Professional haircut with styling',
          price: 25.0,
          duration: 30,
          category: 'Haircut',
          imageUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400',
          salonId: 'salon_1',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        ServiceModel(
          id: 'service_2',
          name: 'Beard Trim',
          description: 'Professional beard trimming and shaping',
          price: 15.0,
          duration: 20,
          category: 'Beard',
          imageUrl: 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400',
          salonId: 'salon_1',
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
          updatedAt: DateTime.now().subtract(const Duration(days: 25)),
        ),
        ServiceModel(
          id: 'service_3',
          name: 'Hair Wash & Style',
          description: 'Complete hair wash with professional styling',
          price: 35.0,
          duration: 45,
          category: 'Styling',
          imageUrl: 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=400',
          salonId: 'salon_1',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
      ];
      
      state = state.copyWith(
        services: mockServices,
        isLoading: false,
        error: null,
      );
    });
  }

  void addService(ServiceModel service) {
    final updatedServices = [...state.services, service];
    state = state.copyWith(services: updatedServices);
  }

  void updateService(ServiceModel updatedService) {
    final updatedServices = state.services.map((service) {
      return service.id == updatedService.id ? updatedService : service;
    }).toList();
    state = state.copyWith(services: updatedServices);
  }

  void deleteService(String serviceId) {
    final updatedServices = state.services.where((service) => service.id != serviceId).toList();
    state = state.copyWith(services: updatedServices);
  }

  void refreshServices() {
    _loadServices();
  }
}

final serviceProvider = StateNotifierProvider<ServiceNotifier, ServiceState>((ref) {
  return ServiceNotifier();
});
