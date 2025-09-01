import 'package:dbuddy/Screens/dash_board_screen.dart';
import 'package:dbuddy/Screens/notification_screen.dart';
import 'package:dbuddy/Screens/profile_screen.dart';
import 'package:dbuddy/Screens/scan_screen.dart';
import 'package:dbuddy/Screens/signin_screen.dart';
import 'package:dbuddy/Screens/signup_screen.dart';
import 'package:dbuddy/Screens/splash_logo_screen.dart' hide DashboardScreen;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 0, 0),
        ),
      ),
      home: const SplashLogoScreen(),
      routes: {
        '/signup_screen': (context) => const SignupScreen(),
        '/signin_screen': (context) => const SigninScreen(),
        '/scan_screen': (context) =>
            const ScanScreen(), // Placeholder for camera screen
        '/splash_logo_screen': (context) => const SplashLogoScreen(),
        '/profile_screen': (context) => const ProfileScreen(),
        '/dashboard_screen': (context) => const DashboardScreen(),
        '/notification_screen': (context) => const NotificationScreen(),
      },
    );
  }
}
