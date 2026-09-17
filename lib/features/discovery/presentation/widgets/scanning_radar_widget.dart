import 'package:flutter/material.dart';

class ScanningRadarWidget extends StatefulWidget {
  final double size;
  final bool isScanning;

  const ScanningRadarWidget({
    super.key,
    this.size = 140.0,
    this.isScanning = true,
  });

  @override
  State<ScanningRadarWidget> createState() => _ScanningRadarWidgetState();
}

class _ScanningRadarWidgetState extends State<ScanningRadarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.isScanning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ScanningRadarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isScanning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _RadarPainter(
              progress: widget.isScanning ? _controller.value : 0.0,
              color: primaryColor,
              isScanning: widget.isScanning,
            ),
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: Icon(
                  widget.isScanning ? Icons.wifi_tethering : Icons.wifi_off,
                  color: primaryColor,
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isScanning;

  _RadarPainter({
    required this.progress,
    required this.color,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw static base ring
    final basePaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, maxRadius * 0.7, basePaint);
    canvas.drawCircle(center, maxRadius * 0.95, basePaint);

    if (!isScanning) return;

    // Draw expanding animated rings
    const int waveCount = 3;
    for (int i = 0; i < waveCount; i++) {
      final waveProgress = (progress + (i / waveCount)) % 1.0;
      final currentRadius = 24 + (maxRadius - 24) * waveProgress;
      final opacity = (1.0 - waveProgress).clamp(0.0, 1.0) * 0.45;

      final wavePaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, currentRadius, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.color != color;
  }
}
