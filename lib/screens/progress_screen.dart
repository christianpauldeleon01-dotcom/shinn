import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:intl/intl.dart';
import '../models/activity_model.dart';
import '../models/user_profile_model.dart';
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
          SliverToBoxAdapter(child: _buildSummarySection()),
          SliverToBoxAdapter(child: _buildWeeklySection()),
          SliverToBoxAdapter(child: _buildGoalsSection()),
          SliverToBoxAdapter(child: _buildActivitiesSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
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

    double weeklyKm = 0;
    for (var activity in _activities) {
      if (activity.date.isAfter(_weekDates.first.subtract(const Duration(days: 1)))) {
        if (activity.distanceMeters.isFinite && !activity.distanceMeters.isNaN) {
          weeklyKm += activity.distanceMeters / 1000;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsRow('Total Distance', '${totalKm.toStringAsFixed(1)} km', CupertinoIcons.map),
          _buildSettingsRow('Total Time', timeString, CupertinoIcons.timer),
          _buildSettingsRow('Activities', '${_activities.length}', CupertinoIcons.flame),
          _buildSettingsRow('This Week', '${weeklyKm.toStringAsFixed(1)} km', CupertinoIcons.calendar),
        ],
      ),
    );
  }

  Widget _buildWeeklySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'THIS WEEK',
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
              children: List.generate(7, (i) {
                final date = _weekDates[i];
                double dayKm = 0;
                for (var activity in _activities) {
                  if (DateUtils.isSameDay(activity.date, date)) {
                    dayKm += activity.distanceKm;
                  }
                }
                final dayName = DateFormat('EEE').format(date).toUpperCase();
                return _buildChartRow(dayName, dayKm, i == 6);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartRow(String day, double km, bool isLast) {
    final progress = (km / 10).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(color: NeonColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              day,
              style: NeonTypography.bodyMedium.copyWith(
                color: NeonColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 12),
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
          ),
          SizedBox(
            width: 50,
            child: Text(
              km > 0 ? '${km.toStringAsFixed(1)} km' : '--',
              style: NeonTypography.bodySmall.copyWith(
                color: NeonColors.textTertiary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'GOALS',
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weekly Distance Goal',
                        style: NeonTypography.bodyMedium.copyWith(
                          color: NeonColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: NeonTypography.bodyMedium.copyWith(
                          color: NeonColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  Text(
                    '${weeklyKm.toStringAsFixed(1)} / 25 km',
                    style: NeonTypography.bodySmall.copyWith(
                      color: NeonColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT ACTIVITIES',
                  style: NeonTypography.labelSmall.copyWith(
                    color: NeonColors.textTertiary,
                    letterSpacing: 1,
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
          ),
          if (_activities.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: NeonColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'No activities yet',
                  style: NeonTypography.bodyMedium.copyWith(
                    color: NeonColors.textTertiary,
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: NeonColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: _activities.take(5).map((activity) {
                  final index = _activities.indexOf(activity);
                  return _buildActivityRow(activity, index >= 4);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(Activity activity, bool isLast) {
    return GestureDetector(
      onTap: () => _openActivityDetail(activity),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(color: NeonColors.border.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: NeonColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _getActivityEmoji(activity.activityTypeString),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.activityTypeString,
                    style: NeonTypography.bodyMedium.copyWith(
                      color: NeonColors.textPrimary,
                    ),
                  ),
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
                  style: NeonTypography.bodyMedium.copyWith(
                    color: NeonColors.textPrimary,
                  ),
                ),
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

  Widget _buildSettingsRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: NeonColors.surface,
        border: Border(
          bottom: BorderSide(color: NeonColors.border.withValues(alpha: 0.3)),
        ),
      ),
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

  void _openActivityDetail(Activity activity) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ActivityDetailScreen(activityId: activity.id),
      ),
    );
  }
}