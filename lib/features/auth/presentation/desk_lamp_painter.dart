import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/theme/pbr_theme.dart';

class DeskLampPainter extends CustomPainter {
  final double lampState; // 0.0 (off) to 1.0 (fully lit)
  final double flicker;   // Micro-flicker factor during warm-up
  final LampStyle style;
  final bool isHoveringSwitch;
  final bool lowPower;

  DeskLampPainter({
    required this.lampState,
    required this.flicker,
    required this.style,
    this.isHoveringSwitch = false,
    this.lowPower = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveIntensity = (lampState * (1.0 - (flicker * 0.4))).clamp(0.0, 1.0);

    // 1. Draw Background Room Atmosphere & Wall Ambient
    _drawRoomBackground(canvas, size, effectiveIntensity);

    // Coordinates for lamp base and head
    final centerX = size.width * 0.5;
    final lampBaseY = size.height * 0.42;
    final lampBaseX = size.width < 600 ? centerX : size.width * 0.32;

    // 2. If lamp is on, draw volumetric light cone and desk reflection FIRST (behind the lamp)
    if (effectiveIntensity > 0.01) {
      _drawVolumetricLightCone(canvas, size, lampBaseX, lampBaseY, effectiveIntensity);
    }

    // 3. Render the selected 3D Lamp Model
    switch (style) {
      case LampStyle.deskLamp:
        _drawArchitectDeskLamp(canvas, lampBaseX, lampBaseY, effectiveIntensity);
        break;
      case LampStyle.vintageBulb:
        _drawVintageEdisonBulb(canvas, lampBaseX, lampBaseY, effectiveIntensity);
        break;
      case LampStyle.lantern:
        _drawIndustrialLantern(canvas, lampBaseX, lampBaseY, effectiveIntensity);
        break;
    }

    // 4. Draw Interactive Switch / Pull Chain
    _drawSwitchControl(canvas, lampBaseX, lampBaseY, effectiveIntensity);
  }

  void _drawRoomBackground(Canvas canvas, Size size, double intensity) {
    // Dark room base gradient
    final bgPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.25),
        size.height * 0.9,
        [
          Color.lerp(const Color(0xFF14171E), const Color(0xFF26201B), intensity)!,
          Color.lerp(const Color(0xFF090A0D), const Color(0xFF110E0C), intensity)!,
          const Color(0xFF050608),
        ],
        [0.0, 0.6, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Desk Horizon Line (Wooden / Slate Desk Surface)
    final deskY = size.height * 0.38;
    final deskRect = Rect.fromLTWH(0, deskY, size.width, size.height - deskY);

    final deskPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, deskY),
        Offset(size.width * 0.5, size.height),
        [
          Color.lerp(const Color(0xFF1B1713), const Color(0xFF382A1C), intensity)!,
          Color.lerp(const Color(0xFF0F0D0A), const Color(0xFF1A140E), intensity)!,
        ],
      );
    canvas.drawRect(deskRect, deskPaint);

    // Subtle wooden grain specular line at the desk edge
    final deskRimPaint = Paint()
      ..color = Color.lerp(
        Colors.white.withOpacity(0.04),
        PbrTheme.tungstenWarm.withOpacity(0.25),
        intensity,
      )!
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, deskY), Offset(size.width, deskY), deskRimPaint);
  }

  void _drawVolumetricLightCone(
    Canvas canvas,
    Size size,
    double lampX,
    double lampY,
    double intensity,
  ) {
    final bulbX = lampX + 35;
    final bulbY = lampY - 80;

    // Conical beam projection to the desk
    final conePath = Path()
      ..moveTo(bulbX - 16, bulbY + 10)
      ..lineTo(size.width * 0.5 + 240, size.height)
      ..lineTo(size.width * 0.5 - 240, size.height)
      ..close();

    // Volumetric dust/air scattering gradient
    final conePaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(bulbX, bulbY),
        size.height * 0.75,
        [
          PbrTheme.tungstenHot.withOpacity(0.32 * intensity),
          PbrTheme.tungstenWarm.withOpacity(0.18 * intensity),
          const Color(0x00FFB347),
        ],
        [0.0, 0.45, 1.0],
      )
      ..blendMode = BlendMode.screen;

    canvas.drawPath(conePath, conePaint);

    // Soft oval light pool directly reflecting off the desk surface
    final deskGlowCenter = Offset(size.width * 0.5, size.height * 0.65);
    final poolPaint = Paint()
      ..shader = ui.Gradient.radial(
        deskGlowCenter,
        280,
        [
          PbrTheme.tungstenHot.withOpacity(0.25 * intensity),
          PbrTheme.tungstenWarm.withOpacity(0.12 * intensity),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      )
      ..blendMode = BlendMode.screen;

    canvas.drawOval(
      Rect.fromCenter(center: deskGlowCenter, width: 480, height: 260),
      poolPaint,
    );

    // Bulb Filament Intense Bloom Center
    if (!lowPower) {
      final bloomPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(bulbX, bulbY),
          55,
          [
            Colors.white.withOpacity(0.95 * intensity),
            PbrTheme.tungstenHot.withOpacity(0.6 * intensity),
            PbrTheme.tungstenWarm.withOpacity(0.15 * intensity),
            Colors.transparent,
          ],
          [0.0, 0.25, 0.6, 1.0],
        )
        ..blendMode = BlendMode.screen;
      canvas.drawCircle(Offset(bulbX, bulbY), 50, bloomPaint);
    }
  }

  void _drawArchitectDeskLamp(
    Canvas canvas,
    double baseX,
    double baseY,
    double intensity,
  ) {
    final baseCenter = Offset(baseX, baseY);

    // 1. Lamp Base Cast Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: baseCenter.translate(0, 10),
        width: 100,
        height: 28,
      ),
      Paint()..color = Colors.black.withOpacity(0.55),
    );

    // 2. Heavy Round Brass Base
    final baseRect = Rect.fromCenter(center: baseCenter, width: 90, height: 24);
    final baseGradient = ui.Gradient.linear(
      baseCenter.translate(-45, 0),
      baseCenter.translate(45, 0),
      [
        const Color(0xFF332612),
        PbrTheme.brassGold,
        PbrTheme.brassBurnished,
        const Color(0xFF1E170A),
      ],
      [0.0, 0.35, 0.75, 1.0],
    );
    canvas.drawOval(baseRect, Paint()..shader = baseGradient);

    // 3. Articulated Brass Arm Joints
    final joint1 = baseCenter.translate(0, -6);
    final elbow = baseCenter.translate(-25, -60);
    final headJoint = baseCenter.translate(35, -85);

    final armPaint = Paint()
      ..shader = ui.Gradient.linear(
        joint1,
        headJoint,
        [PbrTheme.brassGold, PbrTheme.brassBurnished],
      )
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Lower arm parallel struts
    canvas.drawLine(joint1.translate(-3, 0), elbow.translate(-3, 0), armPaint);
    canvas.drawLine(joint1.translate(3, 0), elbow.translate(3, 0), armPaint);

    // Upper arm strut
    canvas.drawLine(elbow, headJoint, armPaint);

    // Joint Pins / Screws
    final screwPaint = Paint()..color = PbrTheme.brassBurnished;
    canvas.drawCircle(joint1, 6, screwPaint);
    canvas.drawCircle(elbow, 5.5, screwPaint);
    canvas.drawCircle(headJoint, 5, screwPaint);

    // 4. Lamp Shade (Hood)
    final shadePath = Path();
    final shadeCenter = headJoint.translate(6, 4);
    shadePath.moveTo(shadeCenter.dx - 22, shadeCenter.dy - 12);
    shadePath.lineTo(shadeCenter.dx + 26, shadeCenter.dy - 8);
    shadePath.lineTo(shadeCenter.dx + 34, shadeCenter.dy + 18);
    shadePath.lineTo(shadeCenter.dx - 28, shadeCenter.dy + 14);
    shadePath.close();

    final shadePaint = Paint()
      ..shader = ui.Gradient.linear(
        shadeCenter.translate(-30, -10),
        shadeCenter.translate(30, 20),
        [
          const Color(0xFF1B3828), // Deep British Racing Green
          const Color(0xFF0E2217),
          const Color(0xFF08140D),
        ],
      );
    canvas.drawPath(shadePath, shadePaint);

    // Metallic Rim around Shade
    final rimPaint = Paint()
      ..color = Color.lerp(PbrTheme.brassBurnished, PbrTheme.brassGold, intensity)!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(shadePath, rimPaint);

    // Glowing Bulb Element under the shade
    final bulbOffset = Offset(headJoint.dx + 4, headJoint.dy + 14);
    final bulbColor = Color.lerp(
      const Color(0x33555555),
      PbrTheme.tungstenHot,
      intensity,
    )!;
    canvas.drawCircle(bulbOffset, 9, Paint()..color = bulbColor);
  }

  void _drawVintageEdisonBulb(
    Canvas canvas,
    double baseX,
    double baseY,
    double intensity,
  ) {
    final baseCenter = Offset(baseX, baseY);

    // Antique wooden block base
    final blockRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: baseCenter.translate(0, 10), width: 80, height: 35),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      blockRect,
      Paint()
        ..shader = ui.Gradient.linear(
          baseCenter.translate(0, -5),
          baseCenter.translate(0, 25),
          [const Color(0xFF4A2F1B), const Color(0xFF26160A)],
        ),
    );

    // Brass Bulb Socket
    final socketRect = Rect.fromCenter(
      center: baseCenter.translate(0, -12),
      width: 32,
      height: 22,
    );
    canvas.drawRect(
      socketRect,
      Paint()
        ..shader = ui.Gradient.linear(
          baseCenter.translate(-16, -12),
          baseCenter.translate(16, -12),
          [PbrTheme.brassGold, PbrTheme.brassBurnished, const Color(0xFF4A3408)],
        ),
    );

    // Teardrop Glass Bulb Envelope
    final bulbCenter = baseCenter.translate(0, -55);
    final glassPath = Path()
      ..moveTo(bulbCenter.dx - 14, bulbCenter.dy + 30)
      ..cubicTo(
        bulbCenter.dx - 32, bulbCenter.dy + 10,
        bulbCenter.dx - 30, bulbCenter.dy - 30,
        bulbCenter.dx, bulbCenter.dy - 35,
      )
      ..cubicTo(
        bulbCenter.dx + 30, bulbCenter.dy - 35,
        bulbCenter.dx + 32, bulbCenter.dy + 10,
        bulbCenter.dx + 14, bulbCenter.dy + 30,
      )
      ..close();

    // Glass Reflection & Amber Tint
    final glassPaint = Paint()
      ..shader = ui.Gradient.radial(
        bulbCenter,
        35,
        [
          Color.lerp(const Color(0x15FFFFFF), const Color(0x44FFB347), intensity)!,
          Color.lerp(const Color(0x22111111), const Color(0x33FF9800), intensity)!,
        ],
      );
    canvas.drawPath(glassPath, glassPaint);

    // Glass Contour Stroke
    canvas.drawPath(
      glassPath,
      Paint()
        ..color = Color.lerp(Colors.white.withOpacity(0.15), PbrTheme.tungstenHot.withOpacity(0.6), intensity)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Internal Squirrel-Cage Filament Wires
    final filamentPath = Path()
      ..moveTo(bulbCenter.dx - 8, bulbCenter.dy + 20)
      ..lineTo(bulbCenter.dx - 6, bulbCenter.dy - 12)
      ..lineTo(bulbCenter.dx, bulbCenter.dy - 22)
      ..lineTo(bulbCenter.dx + 6, bulbCenter.dy - 12)
      ..lineTo(bulbCenter.dx + 8, bulbCenter.dy + 20);

    final filamentColor = Color.lerp(
      const Color(0xFF444444),
      PbrTheme.tungstenCore,
      intensity,
    )!;

    final filamentPaint = Paint()
      ..color = filamentColor
      ..strokeWidth = intensity > 0.3 ? 2.5 : 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(filamentPath, filamentPaint);
  }

  void _drawIndustrialLantern(
    Canvas canvas,
    double baseX,
    double baseY,
    double intensity,
  ) {
    final center = Offset(baseX, baseY - 35);

    // Lantern Base Tray
    canvas.drawRect(
      Rect.fromCenter(center: center.translate(0, 45), width: 75, height: 14),
      Paint()..color = const Color(0xFF2B2520),
    );

    // Four Metal Pillars
    final pillarPaint = Paint()
      ..color = const Color(0xFF453B32)
      ..strokeWidth = 3.5;
    canvas.drawLine(center.translate(-30, -35), center.translate(-30, 42), pillarPaint);
    canvas.drawLine(center.translate(30, -35), center.translate(30, 42), pillarPaint);
    canvas.drawLine(center.translate(-12, -35), center.translate(-12, 42), pillarPaint);
    canvas.drawLine(center.translate(12, -35), center.translate(12, 42), pillarPaint);

    // Lantern Pyramid Top Roof
    final roofPath = Path()
      ..moveTo(center.dx - 36, center.dy - 35)
      ..lineTo(center.dx, center.dy - 65)
      ..lineTo(center.dx + 36, center.dy - 35)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFF3B3026));

    // Top Hanging Ring
    canvas.drawCircle(
      center.translate(0, -72),
      9,
      Paint()
        ..color = PbrTheme.brassBurnished
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Candle / Center Glow
    final candleFlame = Offset(center.dx, center.dy + 5);
    final flameColor = Color.lerp(
      const Color(0xFF333333),
      PbrTheme.tungstenHot,
      intensity,
    )!;
    canvas.drawOval(
      Rect.fromCenter(center: candleFlame, width: 14, height: 28),
      Paint()..color = flameColor,
    );
  }

  void _drawSwitchControl(
    Canvas canvas,
    double lampX,
    double lampY,
    double intensity,
  ) {
    // Tactile toggle switch located on lamp base
    final switchCenter = Offset(lampX + 22, lampY);

    // Switch bevel base ring
    canvas.drawCircle(
      switchCenter,
      8,
      Paint()
        ..color = isHoveringSwitch ? PbrTheme.brassGold : PbrTheme.brassBurnished
        ..style = PaintingStyle.fill,
    );

    // Switch knob state
    final knobColor = intensity > 0.5 ? PbrTheme.tungstenHot : const Color(0xFF222222);
    canvas.drawCircle(
      switchCenter.translate(intensity > 0.5 ? 2 : -2, 0),
      5,
      Paint()..color = knobColor,
    );

    // Desktop hover halo indication
    if (isHoveringSwitch) {
      canvas.drawCircle(
        switchCenter,
        14,
        Paint()
          ..color = PbrTheme.tungstenWarm.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DeskLampPainter oldDelegate) {
    return oldDelegate.lampState != lampState ||
        oldDelegate.flicker != flicker ||
        oldDelegate.style != style ||
        oldDelegate.isHoveringSwitch != isHoveringSwitch ||
        oldDelegate.lowPower != lowPower;
  }
}
