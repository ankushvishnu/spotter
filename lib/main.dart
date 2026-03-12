import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen_modern.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Spotter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Widget _buildEnergeticLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated Logo
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.8, end: 1.2),
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Icon(
            Icons.fitness_center_rounded,
            size: 60,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLG),

        // Pulsing text
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
          builder: (context, opacity, child) {
            return Opacity(
              opacity: opacity,
              child: child,
            );
          },
          child: Text(
            'Spotter',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),

        // Loading indicator with gradient
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),

        // Animated dots
        SizedBox(
          width: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: _buildEnergeticLoading(),
            ),
          );
        }

        if (authProvider.user != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}