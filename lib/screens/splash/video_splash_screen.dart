import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../main.dart';
import '../../config/theme.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  VideoPlayerController? _controller;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _playVideo();
  }

  Future<void> _playVideo() async {
    final ctrl = VideoPlayerController.asset('assets/images/Spotter.mp4');

    try {
      await ctrl.initialize();

      if (!mounted) {
        ctrl.dispose();
        return;
      }

      setState(() {
        _controller = ctrl;
        _isVideoInitialized = true;
      });

      await ctrl.setVolume(0);
      await ctrl.play();

      // Listen only to completion: position reaches the video duration.
      ctrl.addListener(() {
        if (_hasNavigated) return;
        final pos = ctrl.value.position;
        final dur = ctrl.value.duration;
        // Only navigate once the video has actually run to its end.
        if (dur.inMilliseconds > 0 && pos >= dur - const Duration(milliseconds: 200)) {
          _doNavigate();
        }
      });
    } catch (_) {
      // Video unavailable or unsupported platform — skip straight to app.
      _doNavigate();
    }
  }

  void _doNavigate() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video (cover)
          if (_isVideoInitialized && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),

          // Skip button – top-right
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: TextButton(
              onPressed: _doNavigate,
              child: const Text('Skip', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
