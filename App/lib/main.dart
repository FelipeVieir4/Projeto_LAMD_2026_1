import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'data/local/local_database.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.instance.database;
  runApp(const LamdApp());
}

class LamdApp extends StatelessWidget {
  const LamdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAMD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
