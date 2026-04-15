import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

/// Screen that handles the redirect after email confirmation.
/// When a user clicks the confirmation link in their email,
/// they land here. The Supabase auth listener in AuthProvider
/// will detect the new session and navigate automatically.
class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final bool _hasError = false;
  String _statusMessage = 'Verifying your account...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Give the auth listener time to pick up the session
    _waitForAuth();
  }

  Future<void> _waitForAuth() async {
    // Wait for auth provider to detect the session from the URL
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
      setState(() {
        _statusMessage = 'You\'re verified! Redirecting...';
      });
      // AuthWrapper in main.dart will handle navigation
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } else {
      // If after waiting, still no session — show success message and go to login
      setState(() {
        _statusMessage = 'Email verified! Please log in.';
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundColor, AppTheme.surfaceColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated check icon
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _hasError
                          ? LinearGradient(
                              colors: [
                                AppTheme.errorColor.withValues(alpha: 0.2),
                                AppTheme.errorColor.withValues(alpha: 0.1),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withValues(alpha: 0.2),
                                AppTheme.accentColor.withValues(alpha: 0.1),
                              ],
                            ),
                    ),
                    child: Icon(
                      _hasError
                          ? Icons.error_outline_rounded
                          : Icons.verified_rounded,
                      size: 48,
                      color: _hasError
                          ? AppTheme.errorColor
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXL),

                // Status message
                Text(
                  _statusMessage,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppTheme.spacingMD),

                if (!_hasError) ...[
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],

                if (_hasError) ...[
                  const SizedBox(height: AppTheme.spacingLG),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Go to Login'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

