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

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _profile;
  
  int _activitiesCount = 0;
  double _totalDistanceKm = 0;
  String _totalTime = '0h';

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
    themeChangeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildProfileInfo()),
          SliverToBoxAdapter(child: _buildStatsCards()),
          SliverToBoxAdapter(child: _buildMenuItems()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
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
    final isDark = currentThemeMode == TrakThemeMode.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: NeonColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _profile.name.isNotEmpty 
                    ? _profile.name[0].toUpperCase() 
                    : 'U',
                style: NeonTypography.displayMedium.copyWith(
                  color: NeonColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _profile.name,
            style: NeonTypography.headlineMedium.copyWith(
              color: NeonColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _profile.activities,
            style: NeonTypography.bodyMedium.copyWith(
              color: NeonColors.textSecondary,
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
          Expanded(
            child: _buildStatCard(
              value: _activitiesCount.toString(),
              label: 'Activities',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              value: _totalDistanceKm.toStringAsFixed(0),
              label: 'km Total',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              value: _totalTime,
              label: 'Time',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeonColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: NeonTypography.headlineMedium.copyWith(
              color: NeonColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: NeonTypography.labelSmall.copyWith(
              color: NeonColors.textTertiary,
            ),
          ),
        ],
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
