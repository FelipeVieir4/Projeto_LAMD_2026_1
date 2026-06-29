import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'data/local/local_database.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/pending_screen.dart';
import 'screens/jobs_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.instance.database;
  runApp(const LamdParceiroApp());
}

class LamdParceiroApp extends StatelessWidget {
  const LamdParceiroApp({super.key});

  static const _tabRoutes = {'/pending', '/jobs', '/profile'};

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fixit Parceiro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final Widget page = switch (settings.name) {
          '/login' => const LoginScreen(),
          '/register' => const RegisterScreen(),
          '/pending' => const PendingScreen(),
          '/jobs' => const JobsScreen(),
          '/profile' => const ProfileScreen(),
          _ => const SplashScreen(),
        };

        if (_tabRoutes.contains(settings.name)) {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (ctx, a1, a2) => page,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          );
        }
        return MaterialPageRoute(settings: settings, builder: (_) => page);
      },
    );
  }
}
