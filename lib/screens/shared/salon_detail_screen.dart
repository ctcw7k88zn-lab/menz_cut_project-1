import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../models/salon_model.dart';
import '../../models/service_model.dart';
import '../../providers/services_provider.dart';
import '../../widgets/service_tile.dart';
import '../../widgets/rating_stars.dart';

class SalonDetailScreen extends ConsumerStatefulWidget {
  final SalonModel salon;

  const SalonDetailScreen({
    super.key,
    required this.salon,
  });

  @override
  ConsumerState<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends ConsumerState<SalonDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _favoriteAnimationController;
  late Animation<double> _favoriteScaleAnimation;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _favoriteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _favoriteScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _favoriteAnimationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Services are automatically loaded by the provider
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _favoriteAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesBySalonProvider(widget.salon.id));

    return servicesAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(widget.salon.name)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(widget.salon.name)),
        body: Center(child: Text('Error: $error')),
      ),
      data: (services) => Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.backgroundWhite, Color(0xFFF1F5F9)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Hero App Bar
            SliverAppBar(
              expandedHeight: AppTheme.isMobile(context) ? 300 : 400,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'salon_image_${widget.salon.id}',
                      child: Image.network(
                        widget.salon.primaryImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.business,
                                size: 100,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    // Salon info overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.salon.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                RatingStars(rating: widget.salon.rating),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.salon.rating.toStringAsFixed(1)} (${widget.salon.reviewCount} reviews)',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.salon.address,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _toggleFavorite,
                  icon: AnimatedBuilder(
                    animation: _favoriteScaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _favoriteScaleAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  onPressed: _shareSalon,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share, color: Colors.white),
                  ),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'About'),
                  Tab(text: 'Services'),
                  Tab(text: 'Reviews'),
                  Tab(text: 'Gallery'),
                ],
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAboutTab(),
                    _buildServicesTab(services),
                    _buildReviewsTab(),
                    _buildGalleryTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _callSalon,
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryMauve,
                    side: const BorderSide(color: AppTheme.primaryMauve),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _bookAppointment,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Book Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMauve,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildAboutTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        AppTheme.glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About',
                style: AppTheme.heading2,
              ),
              const SizedBox(height: 16),
              Text(
                widget.salon.description,
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Contact Information
        AppTheme.glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Information',
                style: AppTheme.heading2,
              ),
              const SizedBox(height: 16),
              _buildContactItem(Icons.phone, 'Phone', widget.salon.phone),
              const SizedBox(height: 12),
              _buildContactItem(Icons.email, 'Email', widget.salon.email),
              const SizedBox(height: 12),
              _buildContactItem(Icons.web, 'Website', widget.salon.website),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Operating Hours
        AppTheme.glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Operating Hours',
                style: AppTheme.heading2,
              ),
              const SizedBox(height: 16),
              ...widget.salon.operatingHours.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          entry.key.capitalize(),
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: AppTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Amenities
        AppTheme.glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Amenities',
                style: AppTheme.heading2,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (widget.salon.amenities?.keys.toList() ?? []).map((amenity) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMauve.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryMauve.withOpacity(0.3)),
                    ),
                    child: Text(
                      amenity,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryMauve,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesTab(List<ServiceModel> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Services',
          style: AppTheme.heading2,
        ),
        const SizedBox(height: 16),
        
        if (services.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No services available',
                style: AppTheme.bodyMedium,
              ),
            ),
          )
        else
          Column(
            children: services.map((service) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ServiceTile(
                  service: service,
                  onTap: () => _selectService(service),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    // Mock reviews data
    final reviews = [
      {
        'name': 'Sarah Johnson',
        'rating': 5.0,
        'comment': 'Amazing service! The stylist was very professional and the haircut was exactly what I wanted.',
        'date': '2 days ago',
        'image': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100',
      },
      {
        'name': 'Michael Chen',
        'rating': 4.5,
        'comment': 'Great atmosphere and friendly staff. The coloring service was excellent.',
        'date': '1 week ago',
        'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      },
      {
        'name': 'Emily Davis',
        'rating': 5.0,
        'comment': 'Love this salon! Always leave feeling beautiful and confident.',
        'date': '2 weeks ago',
        'image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Reviews',
              style: AppTheme.heading2,
            ),
            const Spacer(),
            TextButton(
              onPressed: _writeReview,
              child: const Text('Write Review'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        ...reviews.map((review) => _buildReviewCard(review)),
      ],
    );
  }

  Widget _buildGalleryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gallery',
          style: AppTheme.heading2,
        ),
        const SizedBox(height: 16),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: widget.salon.images.length,
          itemBuilder: (context, index) {
            return _buildGalleryImage(widget.salon.images[index]);
          },
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryMauve, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppTheme.glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(review['image']),
                  onBackgroundImageError: (exception, stackTrace) {
                    // Handle image error
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['name'],
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RatingStars(rating: review['rating']),
                          const SizedBox(width: 8),
                          Text(
                            review['date'],
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review['comment'],
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryImage(String imageUrl) {
    return GestureDetector(
      onTap: () => _viewImage(imageUrl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppTheme.primaryMauve.withOpacity(0.1),
                child: const Icon(
                  Icons.image,
                  color: AppTheme.primaryMauve,
                  size: 32,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _toggleFavorite() async {
    try {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      
      if (_isFavorite) {
        _favoriteAnimationController.forward().then((_) {
          _favoriteAnimationController.reverse();
        });
        
        // Add to favorites via AppApi
        // TODO: Implement addToFavorites method in AppApi
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to favorites'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        // Remove from favorites via AppApi
        // TODO: Implement removeFromFavorites method in AppApi
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      // Revert state on error
      setState(() {
        _isFavorite = !_isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorites: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _shareSalon() {
    // TODO: Implement share functionality with share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }

  void _callSalon() {
    // TODO: Implement phone call functionality with url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Call functionality coming soon'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }

  void _bookAppointment() {
    context.go('/booking', extra: {
      'salon': widget.salon,
    });
  }

  void _selectService(ServiceModel service) {
    context.go('/booking', extra: {
      'salon': widget.salon,
      'service': service,
    });
  }

  void _writeReview() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening review form...'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }

  void _viewImage(String imageUrl) {
    // Implement image viewer
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.primaryMauve.withOpacity(0.1),
                    child: const Icon(
                      Icons.image,
                      color: AppTheme.primaryMauve,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}