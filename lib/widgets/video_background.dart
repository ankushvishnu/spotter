import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackground extends StatefulWidget {
  final String videoPath;
  final Widget? child;
  final bool loop;
  final double playbackSpeed;

  const VideoBackground({
    super.key,
    required this.videoPath,
    this.child,
    this.loop = true,
    this.playbackSpeed = 1.0,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  late VideoPlayerController _controller;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..setPlaybackSpeed(widget.playbackSpeed)
      ..setVolume(0.0) // Mute for background
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInit = true;
          });
          _controller.setLooping(widget.loop);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return Container(
        color: Colors.black, // Fallback color while loading
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
        // Adding a slight dark overlay to make text/UI more readable
        Container(
          color: Colors.black.withValues(alpha: 0.4),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
