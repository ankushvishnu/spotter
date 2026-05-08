import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/auth_callback_screen.dart';
import 'screens/home/home_screen_modern.dart';
import 'screens/trainers/trainer_onboarding_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/trainer_service.dart';
import 'services/booking_service.dart';
import 'services/messaging_service.dart';
import 'services/profile_service.dart';
import 'services/support_service.dart';
import 'services/goals_service.dart';
import 'services/notification_service.dart';
import 'screens/splash/video_splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize Notifications
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider<TrainerService>(create: (_) => TrainerService()),
        Provider<BookingService>(create: (_) => BookingService()),
        Provider<MessagingService>(create: (_) => MessagingService()),
        Provider<ProfileService>(create: (_) => ProfileService()),
        Provider<SupportService>(create: (_) => SupportService()),
        Provider<GoalsService>(create: (_) => GoalsService()),
      ],
      child: MaterialApp(
        title: 'Spotter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const VideoSplashScreen(),
        onGenerateRoute: (settings) {
          // Handle the /auth-callback route from email confirmation links
          if (settings.name == '/auth-callback') {
            return MaterialPageRoute(
              builder: (_) => const AuthCallbackScreen(),
            );
          }
          return null;
        },
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
          child: const Icon(
            Icons.center_focus_strong_rounded,
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
        ),
        const SizedBox(height: AppTheme.spacingSM),

        // Loading indicator with gradient
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
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
          if (!authProvider.user!.isOnboarded) {
             return authProvider.user!.role == 'trainer' 
                 ? _TrainerProfileGate(userId: authProvider.user!.id)
                 : const OnboardingScreen();
          }
          return const HomeScreen();
        }

        // Deferred Authentication: Unauthenticated users land on HomeScreen to explore
        return const HomeScreen();
      },
    );
  }
}

/// Checks if a trainer user has a completed profile.
/// If not, shows trainer onboarding before HomeScreen.
class _TrainerProfileGate extends StatefulWidget {
  final String userId;
  const _TrainerProfileGate({required this.userId});

  @override
  State<_TrainerProfileGate> createState() => _TrainerProfileGateState();
}

class _TrainerProfileGateState extends State<_TrainerProfileGate> {
  final _supabase = SupabaseConfig.client;
  bool _checking = true;
  bool _needsTrainerSetup = false;

  @override
  void initState() {
    super.initState();
    _checkTrainerProfile();
  }

  Future<void> _checkTrainerProfile() async {
    try {
      // 1. Get user role
      final userRow = await _supabase
          .from('users')
          .select('role')
          .eq('id', widget.userId)
          .maybeSingle();

      if (userRow?['role'] == 'trainer') {
        // 2. Check if a trainer record exists in the `trainers` table
        final trainerRow = await _supabase
            .from('trainers')
            .select('user_id')
            .eq('user_id', widget.userId)
            .maybeSingle();

        if (trainerRow == null) {
          setState(() {
            _needsTrainerSetup = true;
            _checking = false;
          });
          return;
        }
      }
    } catch (_) {
      // On error, let them through to home
    }

    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_needsTrainerSetup) {
      return PopScope(
        // Prevent going back past onboarding
        canPop: false,
        child: TrainerOnboardingScreen(
          isEditing: false,
          // After completing onboarding, go to home
          onComplete: () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          },
        ),
      );
    }

    return const HomeScreen();
  }
}
