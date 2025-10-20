import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/salons_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/salon_card.dart';
import '../../widgets/search_bar.dart' as custom;
import '../../widgets/filter_sheet.dart';
import '../../widgets/lottie_loader.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  Map<String, dynamic> _filters = {};
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  // Featured categories
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Haircut', 'icon': Icons.content_cut, 'color': AppTheme.primaryMauve},
    {'name': 'Spa', 'icon': Icons.spa, 'color': AppTheme.successColor},
    {'name': 'Coloring', 'icon': Icons.palette, 'color': AppTheme.warningColor},
    {'name': 'Styling', 'icon': Icons.face, 'color': AppTheme.infoColor},
    {'name': 'Beard', 'icon': Icons.face_retouching_natural, 'color': AppTheme.accentGold},
  ];

  // Nearby deals
  final List<Map<String, dynamic>> _deals = [
    {
      'title': '50% Off Haircut',
      'salon': 'Style Studio',
      'discount': '50%',
      'expires': '2 days left',
      'image': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
    },
    {
      'title': 'Free Spa Treatment',
      'salon': 'Luxury Spa',
      'discount': 'FREE',
      'expires': '1 day left',
      'image': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=400',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salonsProvider.notifier).loadSalons();
      // Load notifications for the current user
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        ref.read(notificationsProvider.notifier).loadNotificationsForUser(authState.user!.id);
      }
      
      // Refresh salon ratings immediately and after delays to get updated data
      _refreshSalonRatings();
      Future.delayed(const Duration(seconds: 1), () {
        _refreshSalonRatings();
      });
      Future.delayed(const Duration(seconds: 3), () {
        _refreshSalonRatings();
      });
      
      // Also reload all salon data to ensure fresh data
      Future.delayed(const Duration(seconds: 2), () {
        ref.read(salonsProvider.notifier).refreshSalons();
      });
      
      // Force a complete reload after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        print('🔄 Force reloading all salon data...');
        ref.read(salonsProvider.notifier).loadSalons();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refreshSalonRatings() async {
    try {
      // Refresh salon ratings to get updated data
      final salonsState = ref.read(salonsProvider);
      for (final salon in salonsState.salons) {
        // Refresh all salons to ensure we have the latest rating data
        print('🔄 Refreshing salon rating for: ${salon.name} (current: ${salon.rating})');
        await ref.read(salonsProvider.notifier).refreshSalonWithReviews(salon.id);
      }
    } catch (e) {
      print('Error refreshing salon ratings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final salonsState = ref.watch(salonsProvider);
    final salons = salonsState.salons;

    return Scaffold(
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
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Text(
                                'Find Your Style',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const Spacer(),
                              Consumer(
                                builder: (context, ref, child) {
                                  final notificationsState = ref.watch(notificationsProvider);
                                  final unreadCount = notificationsState.when(
                                    data: (notifications) => notifications.where((n) => !n.isRead).length,
                                    loading: () => 0,
                                    error: (_, __) => 0,
                                  );
                                  
                                  return Stack(
                                    children: [
                                      IconButton(
                                        onPressed: () => context.push('/notifications'),
                                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                      ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentGold,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _showChatOptions(),
                                icon: const Icon(Icons.chat_outlined, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: custom.SearchBar(
                        controller: _searchController,
                        hint: 'Search salons, services...',
                        onChanged: (value) {
                          // Implement search
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _showFilterSheet(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryMauve.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.tune, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Featured Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Featured Categories',
                      style: AppTheme.heading2,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 16),
                            child: AppTheme.glassCard(
                              onTap: () {
                                _filterByCategory(category['name']);
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: category['color'].withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      category['icon'],
                                      color: category['color'],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    category['name'],
                                    style: AppTheme.bodySmall.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top Rated Salons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Top Rated Salons',
                          style: AppTheme.heading2,
                        ),
                        TextButton(
                          onPressed: () {
                            context.push('/customer-salon-list');
                          },
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (salonsState.isLoading)
                      const LottieLoader(
                        assetPath: 'assets/lottie/loading.json',
                        message: 'Finding the best salons...',
                      )
                    else if (salonsState.error != null)
                      Center(
                        child: Text(
                          salonsState.error!,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.errorColor,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: salons.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 280,
                              margin: const EdgeInsets.only(right: 16),
                              child: SalonCard(
                                salon: salons[index],
                                onTap: () {
                                  context.push('/salon-detail', extra: {'salon': salons[index]});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Nearby Deals
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nearby Deals',
                      style: AppTheme.heading2,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _deals.length,
                        itemBuilder: (context, index) {
                          final deal = _deals[index];
                          return Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 16),
                            child: AppTheme.glassCard(
                              onTap: () {
                                // Navigate to deal
                              },
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      deal['image'],
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
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
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.goldGradient,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        deal['discount'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    right: 8,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          deal['title'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          deal['salon'],
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          deal['expires'],
                                          style: const TextStyle(
                                            color: AppTheme.accentGold,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recommended for You
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended for You',
                      style: AppTheme.heading2,
                    ),
                    const SizedBox(height: 16),
                    if (salons.isNotEmpty)
                      ...salons.take(3).map((salon) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: AppTheme.glassCard(
                            onTap: () {
                              context.push('/salon-detail', extra: {'salon': salon});
                            },
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    salon.primaryImageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        salon.name,
                                        style: AppTheme.heading3,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        salon.address,
                                        style: AppTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: AppTheme.accentGold,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            salon.rating.toStringAsFixed(1),
                                            style: AppTheme.bodySmall.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () {
                                              // Toggle like
                                            },
                                            child: const Icon(
                                              Icons.favorite_border,
                                              color: AppTheme.primaryMauve,
                                              size: 20,
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
                        );
                      }),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // Space for FAB
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: () {
                // Quick book functionality
                context.push('/booking');
              },
              backgroundColor: AppTheme.primaryMauve,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Quick Book',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryMauve.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: 0,
            onTap: (index) {
              switch (index) {
                case 0:
                  // Already on home
                  break;
                case 1:
                  context.push('/customer-map');
                  break;
                case 2:
                  context.push('/customer-appointments');
                  break;
                case 3:
                  context.push('/ai-hair-suggestions');
                  break;
                case 4:
                  context.push('/customer-profile');
                  break;
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Bookings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome),
                label: 'AI Style',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        initialFilters: _filters,
        onFiltersApplied: (filters) {
          setState(() {
            _filters = filters;
          });
        },
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chat Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryMauve),
              title: const Text('Recent Chats'),
              subtitle: const Text('Continue conversations with salon owners'),
              onTap: () {
                Navigator.pop(context);
                context.push('/customer-chats');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: AppTheme.accentGold),
              title: const Text('Support Chat'),
              subtitle: const Text('Get help from our support team'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support chat feature coming soon!'),
                    backgroundColor: AppTheme.infoColor,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _filterByCategory(String category) {
    setState(() {
      _filters['category'] = category;
    });
    // Show a snackbar to indicate filtering
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtering by $category'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primaryMauve,
      ),
    );
  }
}