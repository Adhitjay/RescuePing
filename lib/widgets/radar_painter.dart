import 'dart:math';

import 'package:flutter/material.dart';

import '../models/peer_device.dart';
import '../models/sos_status.dart';

class RadarBlip {
  const RadarBlip({
    required this.id,
    required this.label,
    required this.angle,
    required this.distance,
    required this.color,
    this.beacon,
    this.isConnected = false,
  });

  final String id;
  final String label;
  final double angle;
  final double distance;
  final Color color;
  final SosBeacon? beacon;
  final bool isConnected;
}

class RadarPainter extends CustomPainter {
  RadarPainter({
    required this.sweepAngle,
    required this.blips,
    required this.ringColor,
    required this.sweepColor,
  });

  final double sweepAngle;
  final List<RadarBlip> blips;
  final Color ringColor;
  final Color sweepColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    // ─── Background circle (Pure Matte Black) ────────────────────────
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFF050505),
    );

    // ─── Range rings (Tech Lines) ────────────────────────────────────
    final ringPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4), ringPaint);
    }

    // Cross-hair lines
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), ringPaint);
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), ringPaint);

    // ─── Sweep line ─────────────────────────────────────────────────
    final sweepEnd = Offset(
      center.dx + radius * sin(sweepAngle),
      center.dy - radius * cos(sweepAngle),
    );
    final sweepPaint = Paint()
      ..color = sweepColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, sweepEnd, sweepPaint);

    // Sweep trail (fading arc)
    final trailPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: sweepAngle - pi / 2, // Wider tail
        endAngle: sweepAngle,
        colors: [
          sweepColor.withValues(alpha: 0),
          sweepColor.withValues(alpha: 0.4),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, trailPaint);

    // ─── Center dot (you) ──────────────────────────────────────────
    // Square instead of circle for tactical feel
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 6, height: 6),
      Paint()..color = sweepColor,
    );
    // Outer glow for center
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 14, height: 14),
      Paint()
        ..color = sweepColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ─── Blips ─────────────────────────────────────────────────────
    for (final blip in blips) {
      final blipRadius = radius * blip.distance.clamp(0.05, 0.92);
      final bx = center.dx + blipRadius * sin(blip.angle);
      final by = center.dy - blipRadius * cos(blip.angle);

      // Pulse Glow
      canvas.drawCircle(
        Offset(bx, by),
        12,
        Paint()..color = blip.color.withValues(alpha: 0.2),
      );

      // Core Dot
      canvas.drawRect(
        Rect.fromCenter(center: Offset(bx, by), width: 6, height: 6),
        Paint()..color = blip.color,
      );
      
      // Label line
      canvas.drawLine(
        Offset(bx + 4, by - 4),
        Offset(bx + 12, by - 12),
        Paint()
          ..color = blip.color.withValues(alpha: 0.5)
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle || oldDelegate.blips.length != blips.length;
  }
}

List<RadarBlip> buildRadarBlips({
  required List<PeerDevice> peers,
  required List<SosBeacon> beacons,
  required String localDeviceId,
}) {
  final blips = <RadarBlip>[];
  final beaconDeviceIds = <String>{};

  // SOS beacons
  for (final b in beacons) {
    if (b.senderDeviceId == localDeviceId) continue;
    beaconDeviceIds.add(b.senderDeviceId);

    final angle = _stableAngle(b.senderDeviceId);
    final distance = b.hasLocation ? 0.4 : 0.8;

    blips.add(RadarBlip(
      id: b.senderDeviceId,
      label: b.senderNickname,
      angle: angle,
      distance: distance,
      color: _sosColor(b.level),
      beacon: b,
    ));
  }

  // Peers
  for (final p in peers) {
    if (beaconDeviceIds.contains(p.peerId)) continue;

    final angle = _stableAngle(p.peerId);
    final distance = p.isConnected ? 0.3 : 0.7;

    blips.add(RadarBlip(
      id: p.peerId,
      label: p.displayName,
      angle: angle,
      distance: distance,
      color: p.isConnected ? const Color(0xFF00E676) : Colors.white30,
      isConnected: p.isConnected,
    ));
  }

  return blips;
}

double _stableAngle(String id) {
  var hash = 0;
  for (var i = 0; i < id.length; i++) {
    hash = (hash * 31 + id.codeUnitAt(i)) & 0x7FFFFFFF;
  }
  return (hash % 360) * pi / 180;
}

Color _sosColor(SosLevel level) {
  switch (level) {
    case SosLevel.trapped:
      return const Color(0xFFFF1744); // Neon Red
    case SosLevel.injured:
      return const Color(0xFFFF9100); // Neon Orange
    case SosLevel.needHelp:
      return const Color(0xFFFFEA00); // Neon Yellow
    case SosLevel.safe:
      return const Color(0xFF00E676); // Neon Green
  }
}