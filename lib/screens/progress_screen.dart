import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:intl/intl.dart';
import '../models/activity_model.dart';
import '../models/user_profile_model.dart';
import '../database/database_service.dart';
import '../theme/trak_design_system.dart';
import 'activity_detail_screen.dart';
import 'activity_tracking_screen.dart';

/// Progress Screen - Main dashboard with neon styling
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> 
    with SingleTickerProviderStateMixin {
  List<Activity> _activities = [];
  List<DateTime> _weekDates = [];
  late UserProfile _profile;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _loadProfile();
    _generateWeekDates();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    Future.delayed(const Duration(milliseconds: 50), () {
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
    });
  }

  void _loadActivities() {
    setState(() {
      _activities = DatabaseService.getAllActivities();
    });
  }

  void _generateWeekDates() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    _weekDates = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
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
      child: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(child: _buildHeader()),
              
              // Big Stat Display
              SliverToBoxAdapter(child: _buildBigStat()),
              
              // Stats Row
              SliverToBoxAdapter(child: _buildStatsRow()),
              
              // Weekly Goal
              SliverToBoxAdapter(child: _buildWeeklyGoal()),
              
              // Weekly Chart
              SliverToBoxAdapter(child: _buildWeeklyChart()),
              
              // Activities Header
              SliverToBoxAdapter(child: _buildActivitiesHeader()),
              
              // Activities List
              _buildActivitiesList(),
              
              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d');
    final isDark = currentThemeMode == TrakThemeMode.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Text(
            dateFormat.format(now).toUpperCase(),
            style: NeonTypography.labelMedium.copyWith(
              color: NeonColors.textTertiary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          
          // Greeting & Avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: NeonTypography.displaySmall.copyWith(
                      color: NeonColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profile.name.toUpperCase(),
                    style: NeonTypography.titleMedium.copyWith(
                      color: NeonColors.textSecondary,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              // Avatar with neon glow
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: NeonColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: NeonShadows.neon(NeonColors.primary),
                ),
                child: Center(
                  child: Text(
                    _profile.name.isNotEmpty ? _profile.name[0].toUpperCase() : 'U',
                    style: NeonTypography.headlineMedium.copyWith(
                      color: isDark ? NeonColors.background : LightModeColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildBigStat() {
    double totalKm = 0;
    for (var activity in _activities) {
      if (activity.distanceMeters.isFinite && !activity.distanceMeters.isNaN) {
        totalKm += activity.distanceMeters / 1000;
      }
    }

    final textOnGradient = NeonColors.textOnPrimaryGradient;
    final subtextOnGradient = NeonColors.subtextOnPrimaryGradient;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: NeonColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: NeonShadows.neon(NeonColors.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.flame_fill, color: textOnGradient, size: 20),
                const SizedBox(width: 8),
                Text(
                  'TOTAL DISTANCE',
                  style: NeonTypography.labelMedium.copyWith(
                    color: subtextOnGradient,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalKm.toStringAsFixed(1),
                  style: NeonTypography.displayLarge.copyWith(
                    color: textOnGradient,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'KM',
                    style: NeonTypography.titleLarge.copyWith(
                      color: subtextOnGradient,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: textOnGradient.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: (totalKm / 100 * 100).clamp(1, 100).toInt(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: textOnGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (100 - (totalKm / 100 * 100).clamp(1, 100).toInt()).clamp(0, 99),
                    child: Container(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_activities.length} ACTIVITIES COMPLETED',
              style: NeonTypography.labelSmall.copyWith(
                color: subtextOnGradient,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    double weeklyKm = 0;
    int weeklySeconds = 0;
    
    for (var activity in _activities) {
      if (activity.date.isAfter(_weekDates.first.subtract(const Duration(days: 1)))) {
        if (activity.distanceMeters.isFinite && !activity.distanceMeters.isNaN) {
          weeklyKm += activity.distanceMeters / 1000;
        }
        if (activity.durationSeconds.isFinite && !activity.durationSeconds.isNaN) {
          weeklySeconds += activity.durationSeconds;
        }
      }
    }
    
    final hours = weeklySeconds ~/ 3600;
    final minutes = (weeklySeconds % 3600) ~/ 60;
    final timeString = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard(weeklyKm.toStringAsFixed(1), 'KM THIS WEEK', CupertinoIcons.arrow_left_right, NeonColors.iconOnSurface),
          const SizedBox(width: 12),
          _buildStatCard(timeString, 'ACTIVE TIME', CupertinoIcons.timer, NeonColors.iconOnSurfaceSecondary),
          const SizedBox(width: 12),
          _buildStatCard(_calculateStreak(), 'DAY STREAK', CupertinoIcons.bolt_fill, NeonColors.iconOnSurface),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color iconColor) {
    return Expanded(
      child: NeonCard(
        padding: const EdgeInsets.all(16),
        isGlow: true,
        glowColor: iconColor,
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 10),
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
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _calculateStreak() {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final hasActivity = _activities.any((a) => DateUtils.isSameDay(a.date, date));
      if (hasActivity) {
        streak++;
      } else if (i > 0) break;
    }
    return streak.toString();
  }

  Widget _buildWeeklyGoal() {
    final isDark = currentThemeMode == TrakThemeMode.dark;
    double weeklyKm = 0;
    for (var activity in _activities) {
      if (activity.date.isAfter(_weekDates.first.subtract(const Duration(days: 1)))) {
        if (activity.distanceMeters.isFinite && !activity.distanceMeters.isNaN) {
          weeklyKm += activity.distanceMeters / 1000;
        }
      }
    }
    
    final progress = (weeklyKm / 25).clamp(0.0, 1.0);
    const goalKm = 25.0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: _startNewActivity,
        child: NeonCard(
          padding: const EdgeInsets.all(24),
          showBorder: true,
          isGlow: progress >= 1.0,
          glowColor: NeonColors.success,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'WEEKLY GOAL',
                    style: NeonTypography.titleLarge.copyWith(
                      color: NeonColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: progress >= 1.0 
                          ? NeonColors.primaryGradient 
                          : null,
                      color: progress >= 1.0 ? null : NeonColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: progress >= 1.0 ? NeonColors.primary : NeonColors.border,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: NeonTypography.labelMedium.copyWith(
                        color: progress >= 1.0 
                            ? NeonColors.textOnPrimaryGradient 
                            : NeonColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    weeklyKm.toStringAsFixed(1),
                    style: NeonTypography.displayMedium.copyWith(
                      color: NeonColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '/ ${goalKm.toInt()} KM',
                      style: NeonTypography.titleMedium.copyWith(
                        color: NeonColors.textTertiary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: NeonColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: progress >= 1.0 
                          ? NeonColors.primaryGradient 
                          : null,
                      color: progress >= 1.0 ? null : NeonColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(goalKm - weeklyKm).toStringAsFixed(1)} KM TO GO',
                    style: NeonTypography.labelSmall.copyWith(
                      color: NeonColors.textTertiary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(CupertinoIcons.play_fill, color: NeonColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'START RUN',
                        style: NeonTypography.labelMedium.copyWith(
                          color: NeonColors.primary,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: NeonCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THIS WEEK',
              style: NeonTypography.titleLarge.copyWith(
                color: NeonColors.textPrimary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: CustomPaint(
                size: const Size(double.infinity, 100),
                painter: _WeeklyChartPainter(_weekDates, _activities),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'RECENT ACTIVITIES',
            style: NeonTypography.titleLarge.copyWith(
              color: NeonColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
          if (_activities.isNotEmpty)
            GestureDetector(
              onTap: () {},
              child: Text(
                'SEE ALL',
                style: NeonTypography.labelMedium.copyWith(
                  color: NeonColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList() {
    if (_activities.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: NeonEmptyState(
            icon: CupertinoIcons.sportscourt,
            title: 'No activities yet',
            subtitle: 'Start your first run to see it here',
            actionLabel: 'START RUN',
            onAction: _startNewActivity,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= _activities.length) return null;
          final activity = _activities[index];
          return _buildActivityItem(activity, index);
        },
        childCount: _activities.length.clamp(0, 5),
      ),
    );
  }

  Widget _buildActivityItem(Activity activity, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: () => _openActivityDetail(activity),
        child: NeonCard(
          padding: const EdgeInsets.all(16),
          showBorder: false,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _getActivityGradient(activity.activityTypeString),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getActivityEmoji(activity.activityTypeString),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.activityTypeString,
                      style: NeonTypography.titleMedium.copyWith(
                        color: NeonColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${activity.distanceKm.toStringAsFixed(2)} km • ${activity.formattedDuration}',
                      style: NeonTypography.bodySmall.copyWith(
                        color: NeonColors.textSecondary,
                      ),
                    ),
                  ],
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
      ),
    );
  }

  LinearGradient _getActivityGradient(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return NeonColors.primaryGradient;
      case 'cycling':
        return LinearGradient(
          colors: [NeonColors.secondary, NeonColors.secondaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'swimming':
        return LinearGradient(
          colors: [NeonColors.accent, NeonColors.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return NeonColors.primaryGradient;
    }
  }

  String _getActivityEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'running': return '🏃';
      case 'cycling': return '🚴';
      case 'swimming': return '🏊';
      case 'walking': return '🚶';
      case 'hiking': return '🥾';
      default: return '🏃';
    }
  }

  void _startNewActivity() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const ActivityTrackingScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _openActivityDetail(Activity activity) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ActivityDetailScreen(activityId: activity.id),
      ),
    );
  }
}

/// Custom painter for weekly chart
class _WeeklyChartPainter extends CustomPainter {
  final List<DateTime> weekDates;
  final List<Activity> activities;
  
  _WeeklyChartPainter(this.weekDates, this.activities);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeonColors.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          NeonColors.primary.withValues(alpha: 0.4),
          NeonColors.primary.withValues(alpha: 0.1),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final linePaint = Paint()
      ..color = NeonColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    final dotPaint = Paint()
      ..color = NeonColors.primary
      ..style = PaintingStyle.fill;
    
    final maxValue = 10.0;
    final barWidth = size.width / 7;
    final maxHeight = size.height - 20;
    
    // Get daily distances
    final dailyDistances = List.generate(7, (i) {
      final date = weekDates[i];
      double distance = 0;
      for (var activity in activities) {
        if (DateUtils.isSameDay(activity.date, date)) {
          distance += activity.distanceKm;
        }
      }
      return distance;
    });
    
    // Draw bars
    for (int i = 0; i < 7; i++) {
      final barHeight = (dailyDistances[i] / maxValue * maxHeight).clamp(4.0, maxHeight);
      final x = i * barWidth + barWidth * 0.2;
      final width = barWidth * 0.6;
      
      // Bar background
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, maxHeight - 4, width, 4),
          const Radius.circular(2),
        ),
        paint,
      );
      
      // Active bar
      if (barHeight > 4) {
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
        
        // Glow effect
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, maxHeight - barHeight, width, barHeight),
            const Radius.circular(6),
          ),
          Paint()
            ..color = NeonColors.primary.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
