import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/app_theme.dart';
import '../../models/salon_model.dart';

class CustomerMapScreen extends ConsumerStatefulWidget {
  const CustomerMapScreen({super.key});

  @override
  ConsumerState<CustomerMapScreen> createState() => _CustomerMapScreenState();
}

class _CustomerMapScreenState extends ConsumerState<CustomerMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _sheetAnimationController;
  late AnimationController _filterAnimationController;
  late Animation<Offset> _sheetAnimation;
  late Animation<double> _filterAnimation;
  
  SalonModel? _selectedSalon;
  bool _isSheetExpanded = false;
  bool _isFilterExpanded = false;
  LatLng? _currentLocation;
  String _searchQuery = '';
  double _selectedRadius = 5.0;
  double _minRating = 0.0;
  String _selectedService = 'All';
  
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // Sample salons near Bahawalpur (30.1788, 71.4687)
  final List<SalonModel> _sampleSalons = [
    SalonModel(
      id: 'salon_1',
      name: 'Elite Hair Studio',
      description: 'Premium hair salon with expert stylists',
      address: 'Model Town, Bahawalpur',
      latitude: 30.1798,
      longitude: 71.4697,
      imageUrls: ['https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400'],
      rating: 4.8,
      reviewCount: 156,
      categories: ['Haircut', 'Coloring', 'Styling'],
      openingHours: {'Monday': '09:00-18:00', 'Tuesday': '09:00-18:00'},
      phone: '+92 300 1234567',
      email: 'info@elitehair.com',
      ownerId: 'owner_1',
      isVerified: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SalonModel(
      id: 'salon_2',
      name: 'Glamour Beauty Lounge',
      description: 'Full-service beauty salon and spa',
      address: 'Canal Road, Bahawalpur',
      latitude: 30.1778,
      longitude: 71.4677,
      imageUrls: ['https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400'],
      rating: 4.6,
      reviewCount: 89,
      categories: ['Haircut', 'Facial', 'Manicure'],
      openingHours: {'Monday': '10:00-19:00', 'Tuesday': '10:00-19:00'},
      phone: '+92 300 2345678',
      email: 'contact@glamourbeauty.com',
      ownerId: 'owner_2',
      isVerified: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SalonModel(
      id: 'salon_3',
      name: 'Style & Cut Salon',
      description: 'Modern salon with latest trends',
      address: 'Satellite Town, Bahawalpur',
      latitude: 30.1808,
      longitude: 71.4707,
      imageUrls: ['https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=400'],
      rating: 4.4,
      reviewCount: 67,
      categories: ['Haircut', 'Beard', 'Hair Treatment'],
      openingHours: {'Monday': '08:00-17:00', 'Tuesday': '08:00-17:00'},
      phone: '+92 300 3456789',
      email: 'hello@stylecut.com',
      ownerId: 'owner_3',
      isVerified: false,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SalonModel(
      id: 'salon_4',
      name: 'Royal Hair & Beauty',
      description: 'Luxury salon experience',
      address: 'Bahawalpur Cantt',
      latitude: 30.1768,
      longitude: 71.4667,
      imageUrls: ['https://images.unsplash.com/photo-1562322140-8baeececf3df?w=400'],
      rating: 4.9,
      reviewCount: 234,
      categories: ['Haircut', 'Coloring', 'Bridal'],
      openingHours: {'Monday': '09:00-20:00', 'Tuesday': '09:00-20:00'},
      phone: '+92 300 4567890',
      email: 'royal@hairbeauty.com',
      ownerId: 'owner_4',
      isVerified: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _requestLocationPermission();
    _getCurrentLocation();
  }

  void _initializeAnimations() {
    _sheetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _sheetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sheetAnimationController,
      curve: Curves.easeInOut,
    ));

    _filterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status != PermissionStatus.granted) {
      _showLocationPermissionDialog();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      
      // Move map to current location
      _mapController.move(_currentLocation!, 15.0);
    } catch (e) {
      // Fallback to Bahawalpur coordinates
      setState(() {
        _currentLocation = const LatLng(30.1788, 71.4687);
      });
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission'),
        content: const Text('Please enable location permission to see nearby salons.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  List<SalonModel> get _filteredSalons {
    return _sampleSalons.where((salon) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!salon.name.toLowerCase().contains(query) &&
            !salon.categories.any((cat) => cat.toLowerCase().contains(query))) {
          return false;
        }
      }
      
      // Rating filter
      if (salon.rating < _minRating) return false;
      
      // Service filter
      if (_selectedService != 'All' && !salon.categories.contains(_selectedService)) {
        return false;
      }
      
      // Distance filter (if current location is available)
      if (_currentLocation != null) {
        final distance = Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          salon.latitude,
          salon.longitude,
        ) / 1000; // Convert to km
        
        if (distance > _selectedRadius) return false;
      }
      
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _sheetAnimationController.dispose();
    _filterAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.backgroundWhite, Color(0xFFF1F5F9)],
          ),
        ),
        child: Stack(
          children: [
            // Map
            _buildMap(),
            
            // Top App Bar
            _buildTopAppBar(),
            
            // Search Bar
            _buildSearchBar(),
            
            // Filter Button
            _buildFilterButton(),
            
            // Filter Panel
            if (_isFilterExpanded) _buildFilterPanel(),
            
            // Bottom Sheet
            if (_selectedSalon != null) _buildBottomSheet(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation ?? const LatLng(30.1788, 71.4687),
        initialZoom: 15.0,
        minZoom: 10.0,
        maxZoom: 18.0,
        onTap: (tapPosition, point) {
          if (_isSheetExpanded) {
            _closeBottomSheet();
          }
        },
      ),
                  children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.menzcut.salonapp',
          maxZoom: 18,
        ),
        
        // Current location marker
        if (_currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation!,
                width: 40,
                height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                    color: AppTheme.primaryMauve,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                            color: AppTheme.primaryMauve.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                          ),
                    ],
                        ),
                        child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        
        // Salon markers
        MarkerLayer(
          markers: _filteredSalons.map((salon) {
            return Marker(
              point: LatLng(salon.latitude, salon.longitude),
              width: 60,
              height: 60,
                        child: GestureDetector(
                          onTap: () => _selectSalon(salon),
                child: Container(
                            decoration: BoxDecoration(
                    color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                      color: _selectedSalon?.id == salon.id 
                          ? AppTheme.primaryMauve 
                          : Colors.grey.shade300,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                    child: salon.imageUrls.isNotEmpty
                        ? Image.network(
                            salon.imageUrls.first,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.primaryMauve,
                                child: const Icon(
                                    Icons.business,
                                    color: Colors.white,
                                  size: 24,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppTheme.primaryMauve,
                            child: const Icon(
                              Icons.business,
                              color: Colors.white,
                              size: 24,
                            ),
                              ),
                            ),
                          ),
                        ),
                      );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTopAppBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
            // Back button
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                          onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new),
                color: AppTheme.textPrimary,
              ),
            ),
            
            const Spacer(),
            
            // Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                            'Nearby Salons',
                            style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            
            const Spacer(),
            
            // Notification bell
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => context.go('/notifications'),
                icon: const Icon(Icons.notifications_outlined),
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search salons by name or service...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: AppTheme.primaryMauve),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: Icon(Icons.clear, color: Colors.grey.shade500),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 130,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryMauve,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryMauve.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () {
            setState(() {
              _isFilterExpanded = !_isFilterExpanded;
            });
            if (_isFilterExpanded) {
              _filterAnimationController.forward();
            } else {
              _filterAnimationController.reverse();
            }
          },
          icon: Icon(
            _isFilterExpanded ? Icons.close : Icons.tune,
                              color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 180,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _filterAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _filterAnimation.value,
            child: Opacity(
              opacity: _filterAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                              fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Distance filter
                    const Text('Distance (km)', style: TextStyle(fontWeight: FontWeight.w600)),
                    Slider(
                      value: _selectedRadius,
                      min: 1.0,
                      max: 20.0,
                      divisions: 19,
                      activeColor: AppTheme.primaryMauve,
                      onChanged: (value) {
                        setState(() {
                          _selectedRadius = value;
                        });
                      },
                    ),
                    Text('${_selectedRadius.toStringAsFixed(1)} km'),
                    const SizedBox(height: 20),
                    
                    // Rating filter
                    const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.w600)),
                    Slider(
                      value: _minRating,
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      activeColor: AppTheme.primaryMauve,
                      onChanged: (value) {
                        setState(() {
                          _minRating = value;
                        });
                      },
                    ),
                    Text('${_minRating.toStringAsFixed(1)} ⭐'),
                    const SizedBox(height: 20),
                    
                    // Service filter
                    const Text('Service Type', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'Haircut', 'Coloring', 'Facial', 'Manicure', 'Beard'].map((service) {
                        final isSelected = _selectedService == service;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedService = service;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryMauve : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              service,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
          );
        },
              ),
    );
  }

  Widget _buildBottomSheet() {
    return Positioned(
      bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _sheetAnimation,
                child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    boxShadow: [
                      BoxShadow(
                color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
            mainAxisSize: MainAxisSize.min,
                    children: [
              // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
              // Salon details
                      Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                          children: [
                        // Salon image
                        Container(
                          width: 80,
                          height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _selectedSalon!.imageUrls.isNotEmpty
                                ? Image.network(
                                    _selectedSalon!.imageUrls.first,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                        color: AppTheme.primaryMauve,
                                                        child: const Icon(
                                                          Icons.business,
                                          color: Colors.white,
                                          size: 40,
                                                        ),
                                                      );
                                                    },
                                  )
                                : Container(
                                    color: AppTheme.primaryMauve,
                                    child: const Icon(
                                      Icons.business,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                          ),
                        ),
                        
                                                const SizedBox(width: 16),
                        
                        // Salon info
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                _selectedSalon!.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                  Icon(Icons.star, color: Colors.amber, size: 16),
                                                          const SizedBox(width: 4),
                                                          Text(
                                    '${_selectedSalon!.rating} (${_selectedSalon!.reviewCount} reviews)',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: AppTheme.primaryMauve, size: 16),
                                                          const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _selectedSalon!.address,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      _selectedSalon!.description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Services
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedSalon!.categories.map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryMauve.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryMauve.withOpacity(0.3)),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: AppTheme.primaryMauve,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Action buttons
                    Row(
                                                  children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryMauve, AppTheme.primaryMauve.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryMauve.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                context.go('/booking', extra: {
                                  'salon': _selectedSalon,
                                  'service': null,
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                                        ),
                                                        child: const Text(
                                'Book Now',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                  fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Expanded(
                                                      child: Container(
                            height: 50,
                                                        decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primaryMauve),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                context.go('/salon-detail', extra: {'salon': _selectedSalon});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'View Profile',
                                style: TextStyle(
                                  color: AppTheme.primaryMauve,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectSalon(SalonModel salon) {
    setState(() {
      _selectedSalon = salon;
        _isSheetExpanded = true;
      });
      _sheetAnimationController.forward();
    }

  void _closeBottomSheet() {
    _sheetAnimationController.reverse().then((_) {
      setState(() {
        _selectedSalon = null;
        _isSheetExpanded = false;
      });
    });
  }
}