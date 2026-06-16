import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'data/local/local_database.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/tickets_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.instance.database;
  runApp(const LamdApp());
}

class LamdApp extends StatelessWidget {
  const LamdApp({super.key});

  static const _tabRoutes = {'/home', '/tickets', '/profile'};

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fixit LAMD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final Widget page = switch (settings.name) {
          '/login' => const LoginScreen(),
          '/register' => const RegisterScreen(),
          '/home' => const HomeScreen(),
          '/tickets' => const TicketsScreen(),
          '/profile' => const ProfileScreen(),
          _ => const SplashScreen(),
        };

        // Tab routes use instant (zero-duration) transition
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
