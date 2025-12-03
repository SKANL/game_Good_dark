import 'package:flutter/material.dart';

class VirtualJoystick extends StatefulWidget {
  const VirtualJoystick({
    super.key,
    required this.onChange,
    this.size = 120.0,
    this.knobSize = 50.0,
  });

  final ValueChanged<Offset> onChange;
  final double size;
  final double knobSize;

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _delta = Offset.zero;

  void _updateDelta(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final newDelta = localPosition - center;
    final radius = widget.size / 2;

    // Limit the knob to the radius
    final dist = newDelta.distance;
    final limitedDelta = dist > radius
        ? Offset.fromDirection(newDelta.direction, radius)
        : newDelta;

    setState(() {
      _delta = limitedDelta;
    });

    // Normalize output (-1.0 to 1.0)
    final normalized = Offset(
      limitedDelta.dx / radius,
      limitedDelta.dy / radius,
    );
    widget.onChange(normalized);
  }

  void _onDragEnd() {
    setState(() {
      _delta = Offset.zero;
    });
    widget.onChange(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.size / 2;
    final knobRadius = widget.knobSize / 2;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onPanStart: (details) => _updateDelta(details.localPosition),
        onPanUpdate: (details) => _updateDelta(details.localPosition),
        onPanEnd: (_) => _onDragEnd(),
        onPanCancel: _onDragEnd,
        child: Stack(
          children: [
            // Background
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x6600FFFF),
                border: Border.all(color: const Color(0xAA00FFFF), width: 2),
              ),
            ),
            // Knob
            Positioned(
              left: radius + _delta.dx - knobRadius,
              top: radius + _delta.dy - knobRadius,
              child: Container(
                width: widget.knobSize,
                height: widget.knobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xAA00FFFF),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 255, 255, 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
