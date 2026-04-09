import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Color, Theme, ThemeData, TextTheme, CircularProgressIndicator, SliderTheme, Slider, SliderThemeData, RoundSliderThumbShape, Colors;

// ========================================
// THEME MODE ENUM
// ========================================

enum TrakThemeMode { light, dark }

// Current theme mode (default: dark)
TrakThemeMode currentThemeMode = TrakThemeMode.dark;

// Theme change notifier - triggers rebuild when theme changes
final themeChangeNotifier = ValueNotifier<TrakThemeMode>(currentThemeMode);

/// Widget that rebuilds when theme changes
class ThemeListener extends StatelessWidget {
  final Widget Function(BuildContext context, TrakThemeMode mode) builder;
  
  const ThemeListener({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TrakThemeMode>(
      valueListenable: themeChangeNotifier,
      builder: (context, mode, _) => builder(context, mode),
    );
  }
}

/// ========================================
/// TRAK DESIGN SYSTEM - BLACK & WHITE EDITION
/// ========================================
/// Ultra-stark monochrome black and white aesthetic
/// Bold, high-contrast minimalist design

class NeonColors {
  // Primary - Pure White
  static Color get primary => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFFFFFFFF) 
      : const Color(0xFF000000);
  static const Color primaryDark = Color(0xFFE0E0E0);
  static const Color primaryLight = Color(0xFFFFFFFF);
  
  // Icon color - always opposite of background for visibility
  static Color get iconOnSurface => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFFFFFFFF) 
      : const Color(0xFF000000);
  static Color get iconOnSurfaceSecondary => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFFE0E0E0) 
      : const Color(0xFF333333);
  
  // Dynamic secondary color based on theme mode
  static Color get secondary => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFF000000) 
      : const Color(0xFF333333);
  static const Color secondaryDark = Color(0xFF000000);
  static const Color secondaryLight = Color(0xFF333333);
  
  // Dynamic accent color based on theme mode
  static Color get accent => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFFFFFFFF) 
      : const Color(0xFF000000);
  static const Color accentDark = Color(0xFFE0E0E0);
  static const Color accentLight = Color(0xFFFFFFFF);
  
  // Dynamic success color based on theme mode
  static Color get success => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFFFFFFFF) 
      : const Color(0xFF000000);
  static const Color successDark = Color(0xFFE0E0E0);
  
  // Dynamic warning color based on theme mode
  static Color get warning => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFFCCCCCC) 
      : const Color(0xFF666666);
  static const Color warningDark = Color(0xFF999999);
  
  // Dynamic error color based on theme mode
  static Color get error => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFFFFFFFF) 
      : const Color(0xFF000000);
  static const Color errorDark = Color(0xFFE0E0E0);
  
  // Dynamic background colors based on theme mode
  static Color get background => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFF000000) 
      : const Color(0xFFFFFFFF);
  static Color get backgroundSecondary => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFF0A0A0A) 
      : const Color(0xFFF5F5F5);
  static Color get surface => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFF141414) 
      : const Color(0xFFEEEEEE);
  static Color get surfaceElevated => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFF1E1E1E) 
      : const Color(0xFFF0F0F0);
  static Color get surfaceHighlight => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFF282828) 
      : const Color(0xFFE8E8E8);
  
  // Dynamic text colors based on theme mode
  static Color get textPrimary => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFFFFFFFF) 
      : const Color(0xFF000000);
  static Color get textSecondary => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFFE0E0E0) 
      : const Color(0xFF333333);
  static Color get textTertiary => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFF999999) 
      : const Color(0xFF666666);
  static Color get textMuted => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFF666666) 
      : const Color(0xFF999999);
  
  // Dynamic border colors based on theme mode
  static Color get border => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFF333333) 
      : const Color(0xFFDDDDDD);
  static Color get borderLight => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFF444444) 
      : const Color(0xFFEEEEEE);
  static const Color borderAccent = Color(0xFFFFFFFF);
  static Color get divider => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFF222222) 
      : const Color(0xFFE0E0E0);
  
  // Dynamic gradients based on theme mode
  static LinearGradient get primaryGradient => currentThemeMode == TrakThemeMode.dark 
      ? const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF333333)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
  
  // Text color on gradient - opposite of gradient colors
  static Color get textOnPrimaryGradient => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFF000000) 
      : const Color(0xFFFFFFFF);
  static Color get subtextOnPrimaryGradient => currentThemeMode == TrakThemeMode.dark 
      ? const Color(0xFF000000).withValues(alpha: 0.7)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.7);
  
  static LinearGradient get accentGradient => currentThemeMode == TrakThemeMode.dark 
      ? const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
  
  static LinearGradient get darkGradient => LinearGradient(
    colors: [backgroundSecondary, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static LinearGradient get surfaceGradient => LinearGradient(
    colors: [surfaceElevated, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static LinearGradient get cardGradient => LinearGradient(
    colors: [surfaceElevated, surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get neonGlow => const LinearGradient(
    colors: [Color(0x40FFFFFF), Color(0x00000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static LinearGradient get blackWhiteGradient => currentThemeMode == TrakThemeMode.dark 
      ? const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFCCCCCC), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF666666), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
}

// ========================================
// LIGHT MODE COLORS - B&W EDITION
// ========================================

class LightModeColors {
  // Primary - Pure Black
  static const Color primary = Color(0xFF000000);
  static const Color primaryDark = Color(0xFF1A1A1A);
  static const Color primaryLight = Color(0xFF333333);
  
  // Secondary - Pure White
  static const Color secondary = Color(0xFFFFFFFF);
  static const Color secondaryDark = Color(0xFFE0E0E0);
  static const Color secondaryLight = Color(0xFFF5F5F5);
  
  // Accent - Black
  static const Color accent = Color(0xFF000000);
  static const Color accentDark = Color(0xFF1A1A1A);
  static const Color accentLight = Color(0xFF333333);
  
  // Success - Black
  static const Color success = Color(0xFF000000);
  static const Color successDark = Color(0xFF1A1A1A);
  
  // Warning - Dark Gray
  static const Color warning = Color(0xFF666666);
  static const Color warningDark = Color(0xFF444444);
  
  // Error - Black
  static const Color error = Color(0xFF000000);
  static const Color errorDark = Color(0xFF1A1A1A);
  
  // Backgrounds - Pure White
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFEEEEEE);
  static const Color surfaceElevated = Color(0xFFF0F0F0);
  static const Color surfaceHighlight = Color(0xFFE8E8E8);
  
  // Text Colors - High Contrast
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF333333);
  static const Color textTertiary = Color(0xFF666666);
  static const Color textMuted = Color(0xFF999999);
  
  // Borders
  static const Color border = Color(0xFFDDDDDD);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color borderAccent = Color(0xFF000000);
  static const Color divider = Color(0xFFE0E0E0);

  // Invert helper for gradients
  static Color invert(Color c) => c == NeonColors.primary ? NeonColors.primary : (c == NeonColors.background ? NeonColors.background : c);
}

// ========================================
// TYPOGRAPHY
// ========================================

class NeonTypography {
  static const String fontFamily = '.SF Pro Display';
  
  // Display
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1.0,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    letterSpacing: -1,
    height: 1.1,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  // Headline
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.3,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.35,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  // Title
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  // Label
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
  );
  
  // Stats
  static const TextStyle statValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    height: 1.0,
  );
  
  static TextStyle get statLabel => TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1,
    height: 1.4,
    color: NeonColors.textTertiary,
  );
}

class NeonSpacing {
  static const double unit = 4.0;
  
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
  
  static const double screenHorizontal = 20.0;
  static const double screenVertical = 16.0;
  
  static const double cardPadding = 20.0;
  static const double cardPaddingLarge = 24.0;
  
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;
  static const double radiusFull = 100.0;
}

class NeonShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: NeonColors.primary.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: NeonColors.primary.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get large => [
    BoxShadow(
      color: NeonColors.primary.withValues(alpha: 0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> neon(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.2),
      blurRadius: 40,
      spreadRadius: 8,
    ),
  ];
  
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 12,
      spreadRadius: 1,
    ),
  ];
}

class NeonAnimations {
  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration slower = Duration(milliseconds: 500);
  
  static const Curve defaultCurve = Curves.easeOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeOutCubic;
  static const Curve smoothCurve = Curves.easeInOutCubic;
}

// ========================================
// WIDGET COMPONENTS - BLACK & WHITE
// ========================================

/// Neon Card - Black & White style
class NeonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showBorder;
  final bool isGlow;
  final Color? glowColor;
  final VoidCallback? onTap;
  
  const NeonCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.gradient,
    this.backgroundColor,
    this.borderRadius = NeonSpacing.radiusMd,
    this.showBorder = false,
    this.isGlow = false,
    this.glowColor,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final glow = glowColor ?? NeonColors.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: NeonAnimations.fast,
        margin: margin,
        padding: padding ?? const EdgeInsets.all(NeonSpacing.cardPadding),
        decoration: BoxDecoration(
          gradient: gradient ?? NeonColors.cardGradient,
          color: gradient == null ? (backgroundColor ?? NeonColors.surface) : null,
          borderRadius: BorderRadius.circular(borderRadius),
          border: showBorder 
              ? Border.all(
                  color: NeonColors.border,
                  width: 1,
                )
              : Border.all(
                  color: NeonColors.border.withValues(alpha: 0.5),
                  width: 0.5,
                ),
          boxShadow: isGlow ? NeonShadows.neon(glow) : NeonShadows.medium,
        ),
        child: child,
      ),
    );
  }
}

/// Neon Button - Black & White
class NeonButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final double? width;
  final double height;
  final bool isLoading;
  final bool isOutlined;
  final bool isSmall;
  final Color? color;
  
  const NeonButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.gradient,
    this.width,
    this.height = 56,
    this.isLoading = false,
    this.isOutlined = false,
    this.isSmall = false,
    this.color,
  });
  
  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: NeonAnimations.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: NeonAnimations.defaultCurve),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final height = widget.isSmall ? 44.0 : widget.height;
    final color = widget.color ?? NeonColors.primary;
    final isOutlined = widget.isOutlined;
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: widget.width ?? double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: isOutlined ? null : (widget.gradient ?? LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )),
            color: isOutlined ? NeonColors.surface : null,
            borderRadius: BorderRadius.circular(NeonSpacing.radiusMd),
            border: isOutlined 
                ? Border.all(color: color, width: 2)
                : null,
            boxShadow: isOutlined ? null : NeonShadows.glow(color),
          ),
          child: Center(
            child: widget.isLoading
                ? CupertinoActivityIndicator(
                    color: NeonColors.background,
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: isOutlined ? color : NeonColors.background,
                          size: widget.isSmall ? 16 : 20,
                        ),
                        const SizedBox(width: NeonSpacing.xs),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: NeonTypography.fontFamily,
                          fontSize: widget.isSmall ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: isOutlined ? color : NeonColors.background,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Neon Icon Button
class NeonIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final bool showBorder;
  final bool isGlow;
  
  const NeonIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
    this.showBorder = false,
    this.isGlow = false,
  });
  
  @override
  State<NeonIconButton> createState() => _NeonIconButtonState();
}

class _NeonIconButtonState extends State<NeonIconButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: NeonAnimations.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: NeonAnimations.defaultCurve),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final iconColor = widget.iconColor ?? NeonColors.primary;
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? NeonColors.surface,
            shape: BoxShape.circle,
            border: widget.showBorder 
                ? Border.all(color: NeonColors.borderAccent, width: 2)
                : Border.all(color: NeonColors.border, width: 1),
            boxShadow: widget.isGlow ? NeonShadows.glow(iconColor) : null,
          ),
          child: Icon(
            widget.icon,
            color: iconColor,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// Neon Stat Display
class NeonStatDisplay extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final bool isLarge;
  final Color? color;
  
  const NeonStatDisplay({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.isLarge = false,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final textColor = color ?? NeonColors.primary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: textColor,
            size: isLarge ? 28 : 22,
          ),
          const SizedBox(height: NeonSpacing.xs),
        ],
        Text(
          value,
          style: isLarge 
              ? NeonTypography.statValue.copyWith(color: textColor)
              : NeonTypography.headlineMedium.copyWith(color: textColor),
        ),
        const SizedBox(height: NeonSpacing.xxs),
        Text(
          label.toUpperCase(),
          style: NeonTypography.statLabel.copyWith(
            color: NeonColors.textTertiary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Neon Section Header
class NeonSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? titleColor;
  
  const NeonSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.titleColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NeonSpacing.screenHorizontal,
        vertical: NeonSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: NeonTypography.titleLarge.copyWith(
                    color: titleColor ?? NeonColors.textPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: NeonSpacing.xxs),
                  Text(
                    subtitle!,
                    style: NeonTypography.bodySmall.copyWith(
                      color: NeonColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!.toUpperCase(),
                    style: NeonTypography.labelMedium.copyWith(
                      color: NeonColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: NeonSpacing.xxs),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: NeonColors.primary,
                    size: 16,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Neon Progress Ring
class NeonProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final Widget? child;
  final bool showBorder;
  final bool isAnimated;
  
  const NeonProgressRing({
    super.key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 8,
    this.backgroundColor,
    this.progressColor,
    this.child,
    this.showBorder = false,
    this.isAnimated = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? NeonColors.surface;
    final progColor = progressColor ?? NeonColors.primary;
    
    return Container(
      width: size,
      height: size,
      decoration: showBorder 
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: NeonColors.border,
                width: 2,
              ),
            )
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              backgroundColor: bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(bgColor),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: isAnimated
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: NeonAnimations.slow,
                    curve: NeonAnimations.sharpCurve,
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value.clamp(0.0, 1.0),
                      strokeWidth: strokeWidth,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(progColor),
                      strokeCap: StrokeCap.round,
                    ),
                  )
                : CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: strokeWidth,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(progColor),
                    strokeCap: StrokeCap.round,
                  ),
          ),
          ?child,
        ],
      ),
    );
  }
}

/// Neon Empty State
class NeonEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  
  const NeonEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NeonSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(NeonSpacing.lg),
              decoration: BoxDecoration(
                color: NeonColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: NeonColors.border, width: 1),
              ),
              child: Icon(
                icon,
                size: 48,
                color: NeonColors.textTertiary,
              ),
            ),
            const SizedBox(height: NeonSpacing.lg),
            Text(
              title.toUpperCase(),
              style: NeonTypography.headlineMedium.copyWith(
                color: NeonColors.textPrimary,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: NeonSpacing.xs),
              Text(
                subtitle!,
                style: NeonTypography.bodyMedium.copyWith(
                  color: NeonColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: NeonSpacing.xl),
              NeonButton(
                label: actionLabel!,
                icon: CupertinoIcons.play_fill,
                onPressed: onAction,
                width: 180,
                height: 48,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Neon Bottom Sheet
class NeonBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final double? height;
  
  const NeonBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.height,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: NeonColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(NeonSpacing.radiusXl),
        ),
        border: Border(
          top: BorderSide(color: NeonColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: NeonSpacing.sm),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: NeonColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(NeonSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: NeonTypography.headlineSmall.copyWith(
                    color: NeonColors.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: NeonColors.textTertiary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Neon Activity Badge
class NeonActivityBadge extends StatelessWidget {
  final String activityType;
  final Color? color;
  
  const NeonActivityBadge({
    super.key,
    required this.activityType,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? NeonColors.primary;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NeonSpacing.sm,
        vertical: NeonSpacing.xxs,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [badgeColor, badgeColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(NeonSpacing.radiusFull),
        boxShadow: NeonShadows.glow(badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getActivityIcon(activityType),
            color: NeonColors.background,
            size: 14,
          ),
          const SizedBox(width: NeonSpacing.xxs),
          Text(
            activityType.toUpperCase(),
            style: NeonTypography.labelMedium.copyWith(
              color: NeonColors.background,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return CupertinoIcons.hare;
      case 'cycling':
        return CupertinoIcons.car_detailed;
      case 'swimming':
        return CupertinoIcons.drop;
      case 'walking':
        return CupertinoIcons.person_2;
      case 'hiking':
        return CupertinoIcons.tree;
      default:
        return CupertinoIcons.sportscourt;
    }
  }
}

// ========================================
// COMPATIBILITY LAYER
// ========================================

class MonoColors extends NeonColors {}
class MonoTypography extends NeonTypography {}
class MonoSpacing extends NeonSpacing {}
class MonoShadows extends NeonShadows {}
class MonoAnimations extends NeonAnimations {}
class MonoCard extends NeonCard {
  const MonoCard({super.key, required super.child, super.padding, super.margin, super.gradient, super.backgroundColor, super.borderRadius, super.showBorder, super.isGlow, super.glowColor, super.onTap});
}
class MonoButton extends NeonButton {
  const MonoButton({super.key, required super.label, super.icon, super.onPressed, super.gradient, super.width, super.height, super.isLoading, super.isOutlined, super.isSmall, super.color});
}
class MonoStatDisplay extends NeonStatDisplay {
  const MonoStatDisplay({super.key, required super.value, required super.label, super.icon, super.isLarge, super.color});
}
class MonoSectionHeader extends NeonSectionHeader {
  const MonoSectionHeader({super.key, required super.title, super.subtitle, super.actionLabel, super.onAction, super.titleColor});
}
class MonoEmptyState extends NeonEmptyState {
  const MonoEmptyState({super.key, required super.icon, required super.title, super.subtitle, super.actionLabel, super.onAction});
}
class MonoProgressRing extends NeonProgressRing {
  const MonoProgressRing({super.key, required super.progress, super.size, super.strokeWidth, super.backgroundColor, super.progressColor, super.child, super.showBorder, super.isAnimated});
}
class MonoIconButton extends NeonIconButton {
  const MonoIconButton({super.key, required super.icon, super.onPressed, super.backgroundColor, super.iconColor, super.size, super.showBorder, super.isGlow});
}
class MonoBottomSheet extends NeonBottomSheet {
  const MonoBottomSheet({super.key, required super.title, required super.child, super.height});
}
class MonoActivityBadge extends NeonActivityBadge {
  const MonoActivityBadge({super.key, required super.activityType, super.color});
}

class TrakColors extends NeonColors {
  static Color get primary => NeonColors.primary;
  static Color get primaryDark => NeonColors.primaryDark;
  static Color get secondary => NeonColors.secondary;
  static Color get accent => NeonColors.accent;
  static Color get background => NeonColors.background;
  static Color get backgroundSecondary => NeonColors.backgroundSecondary;
  static Color get surface => NeonColors.surface;
  static Color get surfaceElevated => NeonColors.surfaceElevated;
  static Color get textPrimary => NeonColors.textPrimary;
  static Color get textSecondary => NeonColors.textSecondary;
  static Color get textTertiary => NeonColors.textTertiary;
  static Color get textMuted => NeonColors.textMuted;
  static Color get border => NeonColors.border;
  static Color get divider => NeonColors.divider;
  static Color get success => NeonColors.success;
  static Color get warning => NeonColors.warning;
  static Color get error => NeonColors.error;
  static Color get info => NeonColors.primary;
  static Color get accentBlue => NeonColors.primary;
  static LinearGradient get primaryGradient => NeonColors.primaryGradient;
  static LinearGradient get secondaryGradient => LinearGradient(
    colors: [NeonColors.secondary, NeonColors.secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static LinearGradient get surfaceGradient => NeonColors.surfaceGradient;
  static LinearGradient get backgroundGradient => NeonColors.darkGradient;
}

class TrakTypography extends NeonTypography {}
class TrakSpacing extends NeonSpacing {}
class TrakAnimations extends NeonAnimations {}

class TrakShadows {
  static List<BoxShadow> get small => NeonShadows.small;
  static List<BoxShadow> get medium => NeonShadows.medium;
  static List<BoxShadow> get large => NeonShadows.large;
  
  static List<BoxShadow> glow(Color color, {double opacity = 0.3}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}

class TrakButton extends NeonButton {
  const TrakButton({super.key, required super.label, super.icon, super.onPressed, super.gradient, super.width, super.height, super.isLoading, super.isOutlined, super.isSmall, super.color});
}

// ========================================
// B&W THEME ACCESSOR - DYNAMIC COLOR PROVIDER
// ========================================
/// Provides theme-aware colors for both light and dark modes
class BWTheme {
  // Current theme mode
  static TrakThemeMode get mode => currentThemeMode;
  static bool get isDark => currentThemeMode == TrakThemeMode.dark;
  static bool get isLight => currentThemeMode == TrakThemeMode.light;
  
  // Primary brand color - White in dark mode, Black in light mode
  static Color get primary => isDark ? NeonColors.primary : LightModeColors.primary;
  static Color get primaryDark => isDark ? NeonColors.primaryDark : LightModeColors.primaryDark;
  static Color get primaryLight => isDark ? NeonColors.primaryLight : LightModeColors.primaryLight;
  
  // Secondary color - Black in dark mode, White in light mode
  static Color get secondary => isDark ? NeonColors.secondary : LightModeColors.secondary;
  static Color get secondaryDark => isDark ? NeonColors.secondaryDark : LightModeColors.secondaryDark;
  static Color get secondaryLight => isDark ? NeonColors.secondaryLight : LightModeColors.secondaryLight;
  
  // Accent
  static Color get accent => isDark ? NeonColors.accent : LightModeColors.accent;
  static Color get accentDark => isDark ? NeonColors.accentDark : LightModeColors.accentDark;
  static Color get accentLight => isDark ? NeonColors.accentLight : LightModeColors.accentLight;
  
  // Semantic colors
  static Color get success => isDark ? NeonColors.success : LightModeColors.success;
  static Color get warning => isDark ? NeonColors.warning : LightModeColors.warning;
  static Color get error => isDark ? NeonColors.error : LightModeColors.error;
  
  // Backgrounds - Inverted
  static Color get background => isDark ? NeonColors.background : LightModeColors.background;
  static Color get backgroundSecondary => isDark ? NeonColors.backgroundSecondary : LightModeColors.backgroundSecondary;
  static Color get surface => isDark ? NeonColors.surface : LightModeColors.surface;
  static Color get surfaceElevated => isDark ? NeonColors.surfaceElevated : LightModeColors.surfaceElevated;
  static Color get surfaceHighlight => isDark ? NeonColors.surfaceHighlight : LightModeColors.surfaceHighlight;
  
  // Text - Inverted
  static Color get textPrimary => isDark ? NeonColors.textPrimary : LightModeColors.textPrimary;
  static Color get textSecondary => isDark ? NeonColors.textSecondary : LightModeColors.textSecondary;
  static Color get textTertiary => isDark ? NeonColors.textTertiary : LightModeColors.textTertiary;
  static Color get textMuted => isDark ? NeonColors.textMuted : LightModeColors.textMuted;
  
  // Borders - Adjusted
  static Color get border => isDark ? NeonColors.border : LightModeColors.border;
  static Color get borderLight => isDark ? NeonColors.borderLight : LightModeColors.borderLight;
  static Color get borderAccent => isDark ? NeonColors.borderAccent : LightModeColors.borderAccent;
  static Color get divider => isDark ? NeonColors.divider : LightModeColors.divider;
  
  // Gradients - removed

  // Convenience helpers - shorthand for B&WTheme.color
  static Color color(Color Function() dark, Color Function() light) => isDark ? dark() : light();
  
  // Brightness for system UI
  static Brightness get brightness => isDark ? Brightness.dark : Brightness.light;
  static Brightness get systemBrightness => isDark ? Brightness.dark : Brightness.light;
}
