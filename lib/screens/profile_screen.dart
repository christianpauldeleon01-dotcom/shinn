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
          SliverToBoxAdapter(child: _buildProfileHeader()),
          SliverToBoxAdapter(child: _buildStatsSection()),
          SliverToBoxAdapter(child: _buildAccountSection()),
          SliverToBoxAdapter(child: _buildSettingsSection()),
          SliverToBoxAdapter(child: _buildAboutSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 12),
          Text(
            _profile.name,
            style: NeonTypography.headlineMedium.copyWith(
              color: NeonColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'STATISTICS',
              style: NeonTypography.labelSmall.copyWith(
                color: NeonColors.textTertiary,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: NeonColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildSettingsRow('Activities', '$_activitiesCount', CupertinoIcons.flame),
                _buildDivider(),
                _buildSettingsRow('Total Distance', '${_totalDistanceKm.toStringAsFixed(1)} km', CupertinoIcons.map),
                _buildDivider(),
                _buildSettingsRow('Total Time', _totalTime, CupertinoIcons.timer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'ACCOUNT',
              style: NeonTypography.labelSmall.copyWith(
                color: NeonColors.textTertiary,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: NeonColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildArrowRow('Edit Profile', CupertinoIcons.person),
                _buildDivider(),
                _buildArrowRow('Notifications', CupertinoIcons.bell),
                _buildDivider(),
                _buildArrowRow('Privacy', CupertinoIcons.lock),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'SETTINGS',
              style: NeonTypography.labelSmall.copyWith(
                color: NeonColors.textTertiary,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: NeonColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildArrowRow('Units', CupertinoIcons.number),
                _buildDivider(),
                _buildArrowRow('Goals', CupertinoIcons.flag),
                _buildDivider(),
                _buildArrowRow('GPS Settings', CupertinoIcons.location),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'ABOUT',
              style: NeonTypography.labelSmall.copyWith(
                color: NeonColors.textTertiary,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: NeonColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildArrowRow('Help & Support', CupertinoIcons.question_circle),
                _buildDivider(),
                _buildArrowRow('About', CupertinoIcons.info),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: NeonColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: NeonTypography.bodyMedium.copyWith(
                color: NeonColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: NeonTypography.bodyMedium.copyWith(
              color: NeonColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowRow(String label, IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: NeonColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Container(
        height: 0.5,
        color: NeonColors.border.withValues(alpha: 0.3),
      ),
    );
  }
}