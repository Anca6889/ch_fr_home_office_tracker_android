import 'package:flutter/material.dart';

// ── Color palette ─────────────────────────────────────────────────────────────

class AppColors {
  final Color bg;
  final Color bgPanel;
  final Color bgCell;
  final Color bgCellWk;
  final Color bgToday;
  final Color fg;
  final Color fgDim;
  final Color ok;
  final Color danger;
  final Color accent;
  final Color separator;
  final Color statusOkBg;
  final Color statusDangerBg;

  const AppColors({
    required this.bg,
    required this.bgPanel,
    required this.bgCell,
    required this.bgCellWk,
    required this.bgToday,
    required this.fg,
    required this.fgDim,
    required this.ok,
    required this.danger,
    required this.accent,
    required this.separator,
    required this.statusOkBg,
    required this.statusDangerBg,
  });
}

const darkColors = AppColors(
  bg:              Color(0xFF1A1B2E),
  bgPanel:         Color(0xFF252640),
  bgCell:          Color(0xFF2E2F50),
  bgCellWk:        Color(0xFF1E1F35),
  bgToday:         Color(0xFF3A3B6A),
  fg:              Color(0xFFD0D3F0),
  fgDim:           Color(0xFF6C6F9C),
  ok:              Color(0xFF5CBF8A),
  danger:          Color(0xFFE85C6A),
  accent:          Color(0xFF7EB8F0),
  separator:       Color(0xFF3A3B5C),
  statusOkBg:      Color(0xFF1B4332),
  statusDangerBg:  Color(0xFF4A0A14),
);

const lightColors = AppColors(
  bg:              Color(0xFFF5F6FA),
  bgPanel:         Color(0xFFFFFFFF),
  bgCell:          Color(0xFFEEEFF8),
  bgCellWk:        Color(0xFFE4E5EF),
  bgToday:         Color(0xFFD6E4F7),
  fg:              Color(0xFF1A1B2E),
  fgDim:           Color(0xFF6C6F9C),
  ok:              Color(0xFF27AE60),
  danger:          Color(0xFFD63649),
  accent:          Color(0xFF2A6FBA),
  separator:       Color(0xFFCCCEE0),
  statusOkBg:      Color(0xFFD5F5E3),
  statusDangerBg:  Color(0xFFFAD7DA),
);

// ── InheritedWidget ───────────────────────────────────────────────────────────

class AppTheme extends InheritedWidget {
  final AppColors colors;
  final bool isDark;
  final VoidCallback onToggle;

  const AppTheme({
    super.key,
    required this.colors,
    required this.isDark,
    required this.onToggle,
    required super.child,
  });

  static AppTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppTheme>()!;

  @override
  bool updateShouldNotify(AppTheme old) => old.isDark != isDark;
}
