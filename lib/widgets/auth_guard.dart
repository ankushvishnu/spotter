import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

class AuthGuard {
  /// Checks if the user is authenticated. 
  /// If not, shows an elegant modal to sign in.
  /// If yes, executes the `onAuthenticated` callback.
  static void protect(BuildContext context, {required VoidCallback onAuthenticated, String intent = 'do this'}) {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.user != null) {
      onAuthenticated();
    } else {
      _showAuthPrompt(context, intent);
    }
  }

  static void _showAuthPrompt(BuildContext context, String intent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AuthPromptModal(intent: intent),
    );
  }
}

class _AuthPromptModal extends StatelessWidget {
  final String intent;
  
  const _AuthPromptModal({required this.intent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        // Optional: Add mesh or glass effect here later
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Icon(Icons.lock_person_rounded, size: 64, color: Theme.of(context).primaryColor),
          const SizedBox(height: 24),
          Text(
            'Sign In Required',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'You need to sign in to $intent. It only takes a second!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // dismiss modal
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Sign In or Create Account'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now, keep exploring'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

