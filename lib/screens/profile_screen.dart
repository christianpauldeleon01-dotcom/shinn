import 'package:flutter/cupertino.dart';
import '../models/user_profile_model.dart';
import '../database/database_service.dart';
import '../theme/trak_design_system.dart';

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
    return CupertinoPageScaffold(
      backgroundColor: NeonColors.background,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: NeonColors.background,
            border: null,
            largeTitle: Text(
              'Profile',
              style: TextStyle(color: NeonColors.textPrimary),
            ),
          ),
          SliverToBoxAdapter(child: _buildProfileCard()),
          SliverToBoxAdapter(child: _buildStatsCard()),
          SliverToBoxAdapter(child: _buildMenuCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: NeonColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
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
                  _profile.name.isNotEmpty ? _profile.name[0].toUpperCase() : 'U',
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: NeonColors.primary,
                borderRadius: BorderRadius.circular(12),
                child: Text(
                  'Edit Profile',
                  style: NeonTypography.bodyMedium.copyWith(
                    color: NeonColors.background,
                  ),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: NeonColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: NeonTypography.titleMedium.copyWith(
                color: NeonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('$_activitiesCount', 'Activities', CupertinoIcons.flame),
                ),
                Container(width: 1, height: 50, color: NeonColors.border.withValues(alpha: 0.3)),
                Expanded(
                  child: _buildStatItem('${_totalDistanceKm.toStringAsFixed(0)}', 'km Total', CupertinoIcons.map),
                ),
                Container(width: 1, height: 50, color: NeonColors.border.withValues(alpha: 0.3)),
                Expanded(
                  child: _buildStatItem(_totalTime, 'Total Time', CupertinoIcons.timer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: NeonColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: NeonTypography.headlineSmall.copyWith(
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
    );
  }

  Widget _buildMenuCard() {
    final menuItems = [
      {'icon': CupertinoIcons.person, 'title': 'Account Settings'},
      {'icon': CupertinoIcons.bell, 'title': 'Notifications'},
      {'icon': CupertinoIcons.lock, 'title': 'Privacy'},
      {'icon': CupertinoIcons.question_circle, 'title': 'Help & Support'},
      {'icon': CupertinoIcons.info, 'title': 'About'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: NeonColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: menuItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _buildMenuRow(item['icon'] as IconData, item['title'] as String),
                if (index < menuItems.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Container(
                      height: 0.5,
                      color: NeonColors.border.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMenuRow(IconData icon, String title) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: NeonColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: NeonColors.primary, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: NeonTypography.bodyMedium.copyWith(
                  color: NeonColors.textPrimary,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: NeonColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}