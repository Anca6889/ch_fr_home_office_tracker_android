import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HomeOfficeApp());
}

class HomeOfficeApp extends StatelessWidget {
  const HomeOfficeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Office Tracking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          background:   clrBg,
          surface:      clrBgPanel,
          primary:      clrAccent,
          secondary:    clrOk,
          error:        clrDanger,
          onBackground: clrFg,
          onSurface:    clrFg,
          onPrimary:    clrBg,
        ),
        scaffoldBackgroundColor: clrBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: clrBgPanel,
          foregroundColor: clrFg,
          elevation: 0,
        ),
        dialogBackgroundColor: clrBgPanel,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: clrFg),
          bodySmall:  TextStyle(color: clrFgDim),
        ),
        iconTheme: const IconThemeData(color: clrFg),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
