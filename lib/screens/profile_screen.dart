import 'package:flutter/cupertino.dart';
import '../models/user_profile_model.dart';
import '../database/database_service.dart';
import '../theme/trak_design_system.dart';

/// Profile Screen - User profile with neon styling
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> 
    with SingleTickerProviderStateMixin {
  late UserProfile _profile;
  
  int _activitiesCount = 0;
  double _totalDistanceKm = 0;
  String _totalTime = '0h';
  double _weeklyDistanceKm = 0;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _animationController.forward();
    });
    
    themeChangeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  void _loadProfile() {
    setState(() {
      _profile = DatabaseService.getUserProfile();
      
      _activitiesCount = DatabaseService.getActivitiesCount();
      _totalDistanceKm = DatabaseService.getTotalDistance() / 1000;
      
      final totalSeconds = DatabaseService.getTotalDuration();
      _totalTime = _formatDuration(totalSeconds);
      
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekEndDate = weekStartDate.add(const Duration(days: 6));
      
      final weekActivities = DatabaseService.getActivitiesInRange(weekStartDate, weekEndDate);
      _weeklyDistanceKm = weekActivities.fold(0.0, (sum, a) => sum + a.distanceMeters) / 1000;
    });
  }
  
  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    }
    return '${minutes}m';
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    themeChangeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            
            // Profile Info
            SliverToBoxAdapter(
              child: _buildProfileInfo(),
            ),
            
            // Quick Actions
            SliverToBoxAdapter(
              child: _buildQuickActions(),
            ),
            
            // Stats Cards
            SliverToBoxAdapter(
              child: _buildStatsCards(),
            ),
            
            // Weekly Chart
            SliverToBoxAdapter(
              child: _buildWeeklyChart(),
            ),
            
            // Menu Items
            SliverToBoxAdapter(
              child: _buildMenuItems(),
            ),
            
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profile',
            style: NeonTypography.displaySmall.copyWith(
              color: NeonColors.textPrimary,
            ),
          ),
          Row(
            children: [
              _buildHeaderButton(
                icon: CupertinoIcons.bell,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _buildHeaderButton(
                icon: CupertinoIcons.gear,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: NeonColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeonColors.border, width: 1),
        ),
        child: Icon(
          icon,
          color: NeonColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    final textOnGradient = NeonColors.textOnPrimaryGradient;
    final isDark = currentThemeMode == TrakThemeMode.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Avatar with neon glow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: NeonColors.primaryGradient,
                  boxShadow: NeonShadows.neon(NeonColors.primary),
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? NeonColors.background : LightModeColors.secondary,
                  border: Border.all(color: NeonColors.border, width: 2),
                ),
                child: Center(
                  child: Text(
                    _profile.name.isNotEmpty 
                        ? _profile.name[0].toUpperCase() 
                        : 'U',
                    style: NeonTypography.displayMedium.copyWith(
                      color: isDark ? NeonColors.background : LightModeColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _profile.name,
            style: NeonTypography.headlineMedium.copyWith(
              color: NeonColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          // Stats on gradient background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: NeonColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: NeonShadows.glow(NeonColors.primary),
            ),
            child: Text(
              _profile.activities,
              style: NeonTypography.labelLarge.copyWith(
                color: textOnGradient,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: NeonButton(
              label: 'Edit Profile',
              icon: CupertinoIcons.pencil,
              onPressed: _showEditProfile,
            ),
          ),
          const SizedBox(width: 12),
          NeonIconButton(
            icon: CupertinoIcons.share,
            onPressed: () {},
            iconColor: NeonColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard(
            value: _activitiesCount.toString(),
            label: 'Activities',
            icon: CupertinoIcons.flame_fill,
            iconColor: NeonColors.iconOnSurface,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            value: _totalDistanceKm.toStringAsFixed(0),
            label: 'km Total',
            icon: CupertinoIcons.arrow_left_right,
            iconColor: NeonColors.iconOnSurfaceSecondary,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            value: _totalTime,
            label: 'Time',
            icon: CupertinoIcons.timer,
            iconColor: NeonColors.iconOnSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    final textOnGradient = NeonColors.textOnPrimaryGradient;
    
    return Expanded(
      child: NeonCard(
        padding: const EdgeInsets.all(14),
        isGlow: true,
        glowColor: iconColor,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconColor, iconColor.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: textOnGradient,
                size: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: NeonTypography.headlineMedium.copyWith(
                color: NeonColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: NeonTypography.labelSmall.copyWith(
                color: NeonColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final textOnGradient = NeonColors.textOnPrimaryGradient;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: NeonCard(
        padding: const EdgeInsets.all(20),
        showBorder: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THIS WEEK',
                      style: NeonTypography.titleLarge.copyWith(
                        color: NeonColors.textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Distance tracked',
                      style: NeonTypography.bodySmall.copyWith(
                        color: NeonColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: NeonColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: NeonShadows.glow(NeonColors.primary),
                  ),
                  child: Text(
                    '${_weeklyDistanceKm.toStringAsFixed(1)} KM',
                    style: NeonTypography.titleMedium.copyWith(
                      color: textOnGradient,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: CustomPaint(
                size: const Size(double.infinity, 120),
                painter: _WeeklyChartPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems() {
    final menuItems = [
      {'icon': CupertinoIcons.person, 'title': 'Account Settings'},
      {'icon': CupertinoIcons.bell, 'title': 'Notifications'},
      {'icon': CupertinoIcons.lock, 'title': 'Privacy'},
      {'icon': CupertinoIcons.question_circle, 'title': 'Help & Support'},
      {'icon': CupertinoIcons.info_circle, 'title': 'About'},
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: menuItems.map((item) => _buildMenuItem(
          icon: item['icon'] as IconData,
          title: item['title'] as String,
        )).toList(),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: NeonColors.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: NeonColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: NeonTypography.bodyLarge.copyWith(
                  color: NeonColors.textPrimary,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: NeonColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfile() {
    // Show edit profile modal
  }
}

/// Weekly chart painter
class _WeeklyChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeonColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = NeonColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = NeonColors.primary
      ..style = PaintingStyle.fill;

    // Simple bar chart for 7 days
    final barWidth = size.width / 7;
    final maxHeight = size.height - 10;
    final values = [3.2, 5.1, 2.8, 6.5, 4.2, 1.5, 0.0];
    final maxValue = 8.0;

    for (int i = 0; i < 7; i++) {
      final barHeight = (values[i] / maxValue * maxHeight).clamp(4.0, maxHeight);
      final x = i * barWidth + barWidth * 0.15;
      final width = barWidth * 0.7;

      // Bar background
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, maxHeight - 4, width, 4),
          const Radius.circular(2),
        ),
        paint,
      );

      if (barHeight > 4) {
        // Gradient fill
        final gradient = LinearGradient(
          colors: [NeonColors.primary, NeonColors.secondary],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );

        final barPaint = Paint()
          ..shader = gradient.createShader(
            Rect.fromLTWH(x, maxHeight - barHeight, width, barHeight),
          );

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, maxHeight - barHeight, width, barHeight),
            const Radius.circular(6),
          ),
          barPaint,
        );

        // Glow
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, maxHeight - barHeight, width, barHeight),
            const Radius.circular(6),
          ),
          Paint()
            ..color = NeonColors.primary.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
