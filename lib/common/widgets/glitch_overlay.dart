import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shaders/flutter_shaders.dart'; // Assuming package is available or using raw FragmentProgram

class GlitchOverlay extends StatefulWidget {
  final Widget child;
  final double intensity; // 0.0 to 1.0

  const GlitchOverlay({
    super.key,
    required this.child,
    this.intensity = 0.0,
  });

  @override
  State<GlitchOverlay> createState() => _GlitchOverlayState();
}

class _GlitchOverlayState extends State<GlitchOverlay>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _time = 0.0;
  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0;
      });
    });
    _ticker.start();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'lib/shaders/glitch.frag',
      );
      setState(() {
        _program = program;
      });
    } catch (e) {
      debugPrint('Error loading glitch shader: $e');
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null || widget.intensity <= 0.01) {
      return widget.child;
    }

    return ShaderBuilder(
      program: _program!,
      child: widget.child,
      builder: (context, shader, child) {
        return AnimatedSampler(
          (ui.Image image, Size size, Canvas canvas) {
            shader
              ..setFloat(0, _time) // uTime
              ..setFloat(1, size.width) // uResolution.x
              ..setFloat(2, size.height) // uResolution.y
              ..setFloat(3, widget.intensity) // uIntensity
              ..setImageSampler(0, image); // uTexture

            canvas.drawRect(
              Offset.zero & size,
              Paint()..shader = shader,
            );
          },
          child: child!,
        );
      },
    );
  }
}

// Helper widgets to simplify shader usage without external package dependency if needed
// But assuming standard Flutter 3.7+ shader support
class ShaderBuilder extends StatelessWidget {
  final ui.FragmentProgram program;
  final Widget child;
  final Widget Function(BuildContext, ui.FragmentShader, Widget?) builder;

  const ShaderBuilder({
    super.key,
    required this.program,
    required this.child,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, program.fragmentShader(), child);
  }
}
