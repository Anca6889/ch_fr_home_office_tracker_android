import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HomeOfficeApp());
}

class HomeOfficeApp extends StatefulWidget {
  const HomeOfficeApp({super.key});

  @override
  State<HomeOfficeApp> createState() => _HomeOfficeAppState();
}

class _HomeOfficeAppState extends State<HomeOfficeApp> {
  bool _isDark = true;

  void _toggleTheme() => setState(() => _isDark = !_isDark);

  ThemeData _buildTheme(AppColors c, bool isDark) => ThemeData(
        colorScheme: isDark
            ? ColorScheme.dark(
                background: c.bg,
                surface:    c.bgPanel,
                primary:    c.accent,
                secondary:  c.ok,
                error:      c.danger,
                onBackground: c.fg,
                onSurface:  c.fg,
                onPrimary:  c.bg,
              )
            : ColorScheme.light(
                background: c.bg,
                surface:    c.bgPanel,
                primary:    c.accent,
                secondary:  c.ok,
                error:      c.danger,
                onBackground: c.fg,
                onSurface:  c.fg,
                onPrimary:  Colors.white,
              ),
        scaffoldBackgroundColor: c.bg,
        appBarTheme: AppBarTheme(
          backgroundColor: c.bgPanel,
          foregroundColor: c.fg,
          elevation: 0,
        ),
        dialogBackgroundColor: c.bgPanel,
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: c.fg),
          bodySmall:  TextStyle(color: c.fgDim),
        ),
        iconTheme: IconThemeData(color: c.fg),
        useMaterial3: true,
      );

  @override
  Widget build(BuildContext context) {
    final colors = _isDark ? darkColors : lightColors;
    return AppTheme(
      colors:   colors,
      isDark:   _isDark,
      onToggle: _toggleTheme,
      child: MaterialApp(
        title: 'Home Office Tracking',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(colors, _isDark),
        home: const HomeScreen(),
      ),
    );
  }
}
