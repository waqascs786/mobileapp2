import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/courses/course_detail_screen.dart';
import 'screens/lessons/lesson_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/wishlist/wishlist_screen.dart';
import 'screens/settings/settings_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class PagePilotApp extends StatelessWidget {
  const PagePilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        return MaterialApp(
          title: AppConfig.instance.appName,
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: ThemeMode.system,
          initialRoute: SplashScreen.route,
          routes: {
            SplashScreen.route: (_) => const SplashScreen(),
            HomeScreen.route: (_) => const HomeScreen(),
            LoginScreen.route: (_) => const LoginScreen(),
            RegisterScreen.route: (_) => const RegisterScreen(),
            CourseDetailScreen.route: (_) => const CourseDetailScreen(courseId: '0'),
            LessonScreen.route: (_) => const LessonScreen(courseId: '0', courseTitle: ''),
            QuizScreen.route: (_) => const QuizScreen(quizId: '0', courseTitle: ''),
            ProfileScreen.route: (_) => const ProfileScreen(),
            WishlistScreen.route: (_) => const WishlistScreen(),
            SettingsScreen.route: (_) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
