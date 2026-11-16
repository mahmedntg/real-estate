import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

class PropertyVideo extends StatefulWidget {
  const PropertyVideo({super.key, required this.url});

  final String url;

  @override
  State<PropertyVideo> createState() => _PropertyVideoState();
}

class _PropertyVideoState extends State<PropertyVideo> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(Uri.parse(widget.url));
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: Colors.black,
        child: ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _controller,
          builder: (context, value, child) {
            if (_failed) {
              return const AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(
                  child: Icon(
                    Icons.videocam_off_outlined,
                    color: Colors.white70,
                    size: 36,
                  ),
                ),
              );
            }
            if (!value.isInitialized) {
              return const AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return AspectRatio(
              aspectRatio: value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggle,
                    ),
                  ),
                  if (!value.isPlaying)
                    IconButton.filled(
                      onPressed: _toggle,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.45),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.play_arrow),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.only(top: 6),
                      colors: VideoProgressColors(playedColor: colors.primary),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
