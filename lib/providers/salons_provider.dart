import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/salon_model.dart';
import '../services/app_api.dart';

// Salon filters
class SalonFilters {
  final String? search;
  final List<String>? categories;
  final double? minRating;
  final double? maxPrice;
  final double? latitude;
  final double? longitude;
  final double? radius;

  const SalonFilters({
    this.search,
    this.categories,
    this.minRating,
    this.maxPrice,
    this.latitude,
    this.longitude,
    this.radius,
  });

  SalonFilters copyWith({
    String? search,
    List<String>? categories,
    double? minRating,
    double? maxPrice,
    double? latitude,
    double? longitude,
    double? radius,
  }) {
    return SalonFilters(
      search: search ?? this.search,
      categories: categories ?? this.categories,
      minRating: minRating ?? this.minRating,
      maxPrice: maxPrice ?? this.maxPrice,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
    );
  }

  bool get hasFilters => 
      search != null ||
      (categories != null && categories!.isNotEmpty) ||
      minRating != null ||
      maxPrice != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SalonFilters &&
        other.search == search &&
        other.categories == categories &&
        other.minRating == minRating &&
        other.maxPrice == maxPrice &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.radius == radius;
  }

  @override
  int get hashCode {
    return Object.hash(
      search,
      categories,
      minRating,
      maxPrice,
      latitude,
      longitude,
      radius,
    );
  }
}

// Salons state
class SalonsState {
  final List<SalonModel> salons;
  final bool isLoading;
  final String? error;
  final SalonFilters filters;
  final Map<String, SalonModel> salonCache;

  const SalonsState({
    this.salons = const [],
    this.isLoading = false,
    this.error,
    this.filters = const SalonFilters(),
    this.salonCache = const {},
  });

  SalonsState copyWith({
    List<SalonModel>? salons,
    bool? isLoading,
    String? error,
    SalonFilters? filters,
    Map<String, SalonModel>? salonCache,
  }) {
    return SalonsState(
      salons: salons ?? this.salons,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      filters: filters ?? this.filters,
      salonCache: salonCache ?? this.salonCache,
    );
  }
}

// Salons notifier
class SalonsNotifier extends StateNotifier<SalonsState> {
  SalonsNotifier() : super(const SalonsState());

  Future<void> loadSalons({SalonFilters? filters}) async {
    final newFilters = filters ?? state.filters;
    state = state.copyWith(
      isLoading: true,
      error: null,
      filters: newFilters,
    );

    try {
      final allSalons = await AppApi.getSalons();
      
      print('🔄 Loaded ${allSalons.length} salons from API');
      
      // Apply filters locally
      var filteredSalons = allSalons.where((salon) {
        // Search filter
        if (newFilters.search != null && newFilters.search!.isNotEmpty) {
          final searchLower = newFilters.search!.toLowerCase();
          if (!salon.name.toLowerCase().contains(searchLower) &&
              !salon.address.toLowerCase().contains(searchLower)) {
            return false;
          }
        }
        
        // Category filter
        if (newFilters.categories != null && newFilters.categories!.isNotEmpty) {
          // Check if salon has services matching the category
          bool hasMatchingCategory = false;
          for (final category in newFilters.categories!) {
            // Map category names to service categories
            final serviceCategory = _mapCategoryToServiceCategory(category);
            if (salon.categories.contains(serviceCategory)) {
              hasMatchingCategory = true;
              break;
            }
          }
          if (!hasMatchingCategory) {
            return false;
          }
        }
        
        // Rating filter
        if (newFilters.minRating != null && newFilters.minRating! > 0 && salon.rating < newFilters.minRating!) {
          return false;
        }
        
        // Price filter would need to be implemented based on salon services
        // For now, we'll skip this filter
        
        return true;
      }).toList();
      
      final salons = filteredSalons;

      state = state.copyWith(
        salons: salons,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshSalons() async {
    await loadSalons();
  }

  Future<void> searchSalons(String query) async {
    final newFilters = state.filters.copyWith(search: query);
    await loadSalons(filters: newFilters);
  }

  Future<void> filterByCategory(String category) async {
    final newFilters = state.filters.copyWith(categories: [category]);
    await loadSalons(filters: newFilters);
  }

  Future<void> clearFilters() async {
    await loadSalons(filters: const SalonFilters());
  }

  String _mapCategoryToServiceCategory(String category) {
    switch (category.toLowerCase()) {
      case 'haircut':
        return 'Haircut';
      case 'spa':
        return 'Spa';
      case 'coloring':
        return 'Coloring';
      case 'styling':
        return 'Styling';
      case 'beard':
        return 'Beard';
      default:
        return category;
    }
  }

  Future<void> refreshSalonWithReviews(String salonId) async {
    try {
      // Get the salon with updated rating from reviews
      final salon = await AppApi.getSalonById(salonId);
      
      print('🔄 Updated salon data: ${salon.name} - Rating: ${salon.rating}, Reviews: ${salon.reviewCount}');
      
      // Update the salon in the current list
      final updatedSalons = state.salons.map((s) {
        if (s.id == salonId) {
          print('🔄 Replacing salon in list: ${s.name} (${s.rating}) -> ${salon.name} (${salon.rating})');
          return salon;
        }
        return s;
      }).toList();
      
      // Update the salon cache
      final updatedCache = Map<String, SalonModel>.from(state.salonCache);
      updatedCache[salonId] = salon;
      
      state = state.copyWith(
        salons: updatedSalons,
        salonCache: updatedCache,
      );
      
      print('🔄 Salon list updated with ${updatedSalons.length} salons');
    } catch (e) {
      print('Error refreshing salon with reviews: $e');
    }
  }

  Future<SalonModel> getSalonById(String salonId) async {
    // Check cache first
    if (state.salonCache.containsKey(salonId)) {
      return state.salonCache[salonId]!;
    }

    try {
      final salon = await AppApi.getSalonById(salonId);
      final updatedCache = Map<String, SalonModel>.from(state.salonCache);
      updatedCache[salonId] = salon;
      
      state = state.copyWith(salonCache: updatedCache);
      return salon;
    } catch (e) {
      throw Exception('Failed to load salon: $e');
    }
  }

  void updateFilters(SalonFilters filters) {
    state = state.copyWith(filters: filters);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Featured salons (highest rated)
  List<SalonModel> get featuredSalons {
    final sortedSalons = List<SalonModel>.from(state.salons);
    sortedSalons.sort((a, b) => b.rating.compareTo(a.rating));
    return sortedSalons.take(5).toList();
  }

  // Popular salons (most reviews)
  List<SalonModel> get popularSalons {
    final sortedSalons = List<SalonModel>.from(state.salons);
    sortedSalons.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    return sortedSalons.take(5).toList();
  }

  // Nearby salons (if location is available)
  List<SalonModel> get nearbySalons {
    if (state.filters.latitude == null || state.filters.longitude == null) {
      return [];
    }

    final sortedSalons = List<SalonModel>.from(state.salons);
    sortedSalons.sort((a, b) {
      final distanceA = _calculateDistance(
        state.filters.latitude!,
        state.filters.longitude!,
        a.latitude,
        a.longitude,
      );
      final distanceB = _calculateDistance(
        state.filters.latitude!,
        state.filters.longitude!,
        b.latitude,
        b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });

    return sortedSalons.take(5).toList();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simple distance calculation (not accurate for large distances)
    final dx = lat1 - lat2;
    final dy = lon1 - lon2;
    return (dx * dx + dy * dy).abs();
  }
}

// Providers
final salonsProvider = StateNotifierProvider<SalonsNotifier, SalonsState>((ref) {
  return SalonsNotifier();
});

final salonsListProvider = Provider<List<SalonModel>>((ref) {
  return ref.watch(salonsProvider).salons;
});

final featuredSalonsProvider = Provider<List<SalonModel>>((ref) {
  final notifier = ref.watch(salonsProvider.notifier);
  return notifier.featuredSalons;
});

final popularSalonsProvider = Provider<List<SalonModel>>((ref) {
  final notifier = ref.watch(salonsProvider.notifier);
  return notifier.popularSalons;
});

final nearbySalonsProvider = Provider<List<SalonModel>>((ref) {
  final notifier = ref.watch(salonsProvider.notifier);
  return notifier.nearbySalons;
});

final salonProvider = FutureProvider.family<SalonModel, String>((ref, salonId) async {
  final notifier = ref.read(salonsProvider.notifier);
  return notifier.getSalonById(salonId);
});
