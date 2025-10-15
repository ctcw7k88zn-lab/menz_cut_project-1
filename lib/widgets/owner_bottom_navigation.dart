import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';

class OwnerBottomNavigation extends StatefulWidget {
  final int currentIndex;
  
  const OwnerBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  State<OwnerBottomNavigation> createState() => _OwnerBottomNavigationState();
}

class _OwnerBottomNavigationState extends State<OwnerBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              margin: const EdgeInsets.all(16),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BottomNavigationBar(
                  currentIndex: widget.currentIndex,
                  onTap: (index) => _onTabTapped(index),
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: AppTheme.primaryMauve,
                  unselectedItemColor: Colors.grey.shade500,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  items: [
                    BottomNavigationBarItem(
                      icon: _buildNavIcon(Icons.home_outlined, Icons.home, 0),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildNavIcon(Icons.analytics_outlined, Icons.analytics, 1),
                      label: 'Analytics',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildNavIcon(Icons.calendar_today_outlined, Icons.calendar_today, 2),
                      label: 'Appointments',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildNavIcon(Icons.chat_bubble_outline, Icons.chat_bubble, 3),
                      label: 'Messages',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildNavIcon(Icons.person_outline, Icons.person, 4),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavIcon(IconData outlineIcon, IconData filledIcon, int index) {
    final isSelected = widget.currentIndex == index;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryMauve.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          isSelected ? filledIcon : outlineIcon,
          key: ValueKey(isSelected),
          color: isSelected ? AppTheme.primaryMauve : Colors.grey.shade500,
          size: 24,
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    switch (index) {
      case 0:
        context.go('/owner-home');
        break;
      case 1:
        context.go('/owner-analytics');
        break;
      case 2:
        context.go('/owner-services');
        break;
      case 3:
        context.go('/owner-chat');
        break;
      case 4:
        context.go('/owner-profile');
        break;
    }
  }
}
