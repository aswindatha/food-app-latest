import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/dashboard/donor_dashboard_new.dart';
import 'screens/dashboard/volunteer_dashboard.dart';
import 'screens/dashboard/organization_dashboard.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const FoodApp());
}

class FoodApp extends StatelessWidget {
  const FoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: 'Food Donation App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: _router,
          );
        },
      ),
    );
  }

  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          final user = context.read<AuthProvider>().user;
          if (user == null) return const LoginScreen();
          
          switch (user.role) {
            case 'donor':
              return const DonorDashboardNew();
            case 'volunteer':
              return const VolunteerDashboard();
            case 'organization':
              return const OrganizationDashboard();
            default:
              return const DonorDashboardNew();
          }
        },
      ),
    ],
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = authProvider.isAuthenticated;
      
      // If not authenticated and not on auth pages, redirect to login
      if (!isAuthenticated && !['/login', '/register', '/splash'].contains(state.location)) {
        return '/login';
      }
      
      // If authenticated and on auth pages, redirect to dashboard
      if (isAuthenticated && ['/login', '/register', '/splash'].contains(state.location)) {
        return '/dashboard';
      }
      
      return null;
    },
  );
}
