import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/database_service.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/activity_tracking_screen.dart';
import 'theme/trak_design_system.dart';
import 'theme/trak_theme.dart';

// Riverpod providers for app state
final selectedIndexProvider = StateProvider<int>((ref) => 0);
final isRecordButtonPressedProvider = StateProvider<bool>((ref) => false);

// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, TrakThemeMode>((ref) {
  return ThemeModeNotifier();
});

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive database
  await DatabaseService.init();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Run the app with Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: TrakApp(),
    ),
  );
}

/// Main App Widget - Black & White Edition
class TrakApp extends StatelessWidget {
  const TrakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final themeMode = ref.watch(themeModeProvider);
      return CupertinoApp(
        title: 'Trak',
        debugShowCheckedModeBanner: false,
        theme: TrakTheme.getTheme(themeMode),
        home: const MainTabBarScaffold(),
      );
    });
  }
}

/// Main Tab Scaffold with floating navigation
class MainTabBarScaffold extends ConsumerStatefulWidget {
  const MainTabBarScaffold({super.key});

  @override
  ConsumerState<MainTabBarScaffold> createState() => _MainTabBarScaffoldState();
}

class _MainTabBarScaffoldState extends ConsumerState<MainTabBarScaffold> 
    with SingleTickerProviderStateMixin {
  late AnimationController _recordButtonController;
  late Animation<double> _recordButtonScale;
  late Animation<double> _recordButtonGlow;

  @override
  void initState() {
    super.initState();
    _recordButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _recordButtonScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _recordButtonController, curve: Curves.easeOut),
    );
    _recordButtonGlow = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _recordButtonController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _recordButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final isRecordButtonPressed = ref.watch(isRecordButtonPressedProvider);

    return CupertinoPageScaffold(
      backgroundColor: NeonColors.background,
      child: Stack(
        children: [
          // Main content with animation
          AnimatedSwitcher(
            duration: NeonAnimations.normal,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(selectedIndex),
              child: _buildBody(selectedIndex),
            ),
          ),
          
          // Floating Navigation Bar with start button
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: _buildFloatingNav(selectedIndex, isRecordButtonPressed),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return const ProgressScreen();
      case 1:
        return const ProfileScreen();
      default:
        return const ProgressScreen();
    }
  }

  Widget _buildFloatingNav(int selectedIndex, bool isRecordButtonPressed) {
    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background nav bar
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  NeonColors.surface.withValues(alpha: 0.95),
                  NeonColors.surfaceElevated.withValues(alpha: 0.95),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: NeonColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: NeonColors.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Progress tab
                  Expanded(
                    child: _buildNavItem(
                      icon: CupertinoIcons.graph_circle_fill,
                      label: 'Progress',
                      index: 0,
                      isSelected: selectedIndex == 0,
                    ),
                  ),
                  
                  const SizedBox(width: 60),
                  
                  // Profile tab
                  Expanded(
                    child: _buildNavItem(
                      icon: CupertinoIcons.person_circle_fill,
                      label: 'Profile',
                      index: 1,
                      isSelected: selectedIndex == 1,
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Theme toggle button
                  _buildThemeToggle(),
                ],
              ),
            ),
          ),
          
          // Start/Record button in center
          Positioned(
            bottom: 16,
            child: _buildRecordButton(isRecordButtonPressed),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(selectedIndexProvider.notifier).state = index;
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: NeonAnimations.fast,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: NeonAnimations.fast,
              child: Icon(
                icon,
                color: isSelected ? NeonColors.primary : NeonColors.textTertiary,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: NeonAnimations.fast,
              style: TextStyle(
                color: isSelected ? NeonColors.primary : NeonColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordButton(bool isRecordButtonPressed) {
    final borderColor = NeonColors.textOnPrimaryGradient;
    
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        ref.read(isRecordButtonPressedProvider.notifier).state = true;
        _recordButtonController.forward();
      },
      onTapUp: (_) {
        ref.read(isRecordButtonPressedProvider.notifier).state = false;
        _recordButtonController.reverse();
        _openRecordingScreen();
      },
      onTapCancel: () {
        ref.read(isRecordButtonPressedProvider.notifier).state = false;
        _recordButtonController.reverse();
      },
      child: AnimatedBuilder(
        animation: _recordButtonController,
        builder: (context, child) {
          return Transform.scale(
            scale: _recordButtonScale.value,
            child: child,
          );
        },
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                NeonColors.primary,
                NeonColors.accent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: borderColor,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: NeonColors.primary.withValues(alpha: _recordButtonGlow.value),
                blurRadius: isRecordButtonPressed ? 35 : 25,
                spreadRadius: isRecordButtonPressed ? 8 : 4,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: NeonColors.accent.withValues(alpha: _recordButtonGlow.value * 0.5),
                blurRadius: isRecordButtonPressed ? 45 : 35,
                spreadRadius: isRecordButtonPressed ? 12 : 6,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: AnimatedContainer(
              duration: NeonAnimations.instant,
              width: isRecordButtonPressed ? 20 : 24,
              height: isRecordButtonPressed ? 20 : 24,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(
                  isRecordButtonPressed ? 4 : 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == TrakThemeMode.dark;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(themeModeProvider.notifier).toggle();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: NeonAnimations.fast,
              child: Icon(
                isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                color: NeonColors.textTertiary,
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: NeonAnimations.fast,
              style: TextStyle(
                color: NeonColors.textTertiary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              child: Text(isDark ? 'Dark' : 'Light'),
            ),
          ],
        ),
      ),
    );
  }

  void _openRecordingScreen() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const ActivityTrackingScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}
