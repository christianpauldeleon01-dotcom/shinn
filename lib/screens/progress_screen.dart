import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:intl/intl.dart';
import '../models/activity_model.dart';
import '../database/database_service.dart';
import '../theme/trak_design_system.dart';
import 'activity_detail_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Activity> _activities = [];
  List<DateTime> _weekDates = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _generateWeekDates();
    themeChangeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
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
              'Progress',
              style: TextStyle(color: NeonColors.textPrimary),
            ),
          ),
          SliverToBoxAdapter(child: _buildOverviewCard()),
          SliverToBoxAdapter(child: _buildStatsGrid()),
          SliverToBoxAdapter(child: _buildWeeklyCard()),
          SliverToBoxAdapter(child: _buildGoalsCard()),
          SliverToBoxAdapter(child: _buildActivitiesCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    double totalKm = 0;
    int totalSeconds = 0;
    for (var activity in _activities) {
      if (activity.distanceMeters.isFinite && !activity.distanceMeters.isNaN) {
        totalKm += activity.distanceMeters / 1000;
      }
      if (activity.durationSeconds.isFinite && !activity.durationSeconds.isNaN) {
        totalSeconds += activity.durationSeconds;
      }
    }
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final timeString = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [NeonColors.primary, NeonColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.flame_fill, color: NeonColors.textOnPrimaryGradient, size: 20),
                const SizedBox(width: 8),
                Text(
                  'TOTAL DISTANCE',
                  style: NeonTypography.labelMedium.copyWith(
                    color: NeonColors.subtextOnPrimaryGradient,
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
                    color: NeonColors.textOnPrimaryGradient,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'KM',
                    style: NeonTypography.titleLarge.copyWith(
                      color: NeonColors.subtextOnPrimaryGradient,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${_activities.length} activities  •  $timeString',
              style: NeonTypography.bodyMedium.copyWith(
                color: NeonColors.subtextOnPrimaryGradient,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    double weeklyKm = 0;
    int streak = 0;
    final now = DateTime.now();
    for (var activity in _activities) {
      if (activity.date.isAfter(_weekDates.first.subtract(const Duration(days: 1)))) {
        if (activity.distanceMeters.isFinite && !activity.distanceMeters.isNaN) {
          weeklyKm += activity.distanceMeters / 1000;
        }
      }
    }
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final hasActivity = _activities.any((a) => DateUtils.isSameDay(a.date, date));
      if (hasActivity) {
        streak++;
      } else if (i > 0) break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('${weeklyKm.toStringAsFixed(1)}', 'KM This Week', CupertinoIcons.calendar)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('$streak', 'Day Streak', CupertinoIcons.bolt_fill)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('${_activities.length}', 'Activities', CupertinoIcons.flame)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NeonColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: NeonColors.primary, size: 20),
          ),
          const SizedBox(height: 12),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: NeonColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Week',
              style: NeonTypography.titleMedium.copyWith(
                color: NeonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
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

  Widget _buildGoalsCard() {
    double weeklyKm = 0;
    for (var activity in _activities) {
      if (activity.date.isAfter(_weekDates.first.subtract(const Duration(days: 1)))) {
        if (activity.distanceMeters.isFinite && !activity.distanceMeters.isNaN) {
          weeklyKm += activity.distanceMeters / 1000;
        }
      }
    }
    final progress = (weeklyKm / 25).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: NeonColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Goal',
                  style: NeonTypography.titleMedium.copyWith(
                    color: NeonColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: NeonColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: NeonTypography.labelMedium.copyWith(
                      color: NeonColors.primary,
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
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/ 25 km',
                    style: NeonTypography.bodyMedium.copyWith(
                      color: NeonColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: NeonColors.background,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: NeonColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activities',
                style: NeonTypography.titleMedium.copyWith(
                  color: NeonColors.textPrimary,
                ),
              ),
              if (_activities.isNotEmpty)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  child: Text(
                    'See All',
                    style: NeonTypography.bodySmall.copyWith(
                      color: NeonColors.primary,
                    ),
                  ),
                  onPressed: () {},
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_activities.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: NeonColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.sportscourt, color: NeonColors.textTertiary, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'No activities yet',
                      style: NeonTypography.bodyMedium.copyWith(
                        color: NeonColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_activities.take(3).length, (index) {
              final activity = _activities[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildActivityCard(activity),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return GestureDetector(
      onTap: () => _openActivityDetail(activity),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NeonColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: NeonColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getActivityEmoji(activity.activityTypeString),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.activityTypeString,
                    style: NeonTypography.titleSmall.copyWith(
                      color: NeonColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(activity.date),
                    style: NeonTypography.bodySmall.copyWith(
                      color: NeonColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${activity.distanceKm.toStringAsFixed(1)} km',
                  style: NeonTypography.titleSmall.copyWith(
                    color: NeonColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.formattedDuration,
                  style: NeonTypography.bodySmall.copyWith(
                    color: NeonColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  void _openActivityDetail(Activity activity) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ActivityDetailScreen(activityId: activity.id),
      ),
    );
  }
}

class _WeeklyChartPainter extends CustomPainter {
  final List<DateTime> weekDates;
  final List<Activity> activities;
  
  _WeeklyChartPainter(this.weekDates, this.activities);

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = 10.0;
    final barWidth = size.width / 7;
    final maxHeight = size.height - 20;
    
    for (int i = 0; i < 7; i++) {
      final date = weekDates[i];
      double distance = 0;
      for (var activity in activities) {
        if (DateUtils.isSameDay(activity.date, date)) {
          distance += activity.distanceKm;
        }
      }
      
      final barHeight = (distance / maxValue * maxHeight).clamp(4.0, maxHeight);
      final x = i * barWidth + barWidth * 0.15;
      final width = barWidth * 0.7;
      
      final barPaint = Paint()
        ..color = NeonColors.primary.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, maxHeight - barHeight, width, barHeight),
          const Radius.circular(6),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}