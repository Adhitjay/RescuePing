import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sos_status.dart';
import '../services/app_state.dart';
import '../widgets/radar_painter.dart';
import '../widgets/sos_beacon_card.dart';

/// Full-screen rescue radar.
class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  void _showBeaconDetails(SosBeacon beacon) {
    final scheme = Theme.of(context).colorScheme;
    
    Color levelColor;
    switch (beacon.level) {
      case SosLevel.trapped: levelColor = const Color(0xFFFF1744); break;
      case SosLevel.injured: levelColor = const Color(0xFFFF9100); break;
      case SosLevel.needHelp: levelColor = const Color(0xFFFFEA00); break;
      case SosLevel.safe: levelColor = scheme.primary; break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border(
            top: BorderSide(color: levelColor, width: 3),
            left: BorderSide(color: levelColor.withValues(alpha: 0.3), width: 1),
            right: BorderSide(color: levelColor.withValues(alpha: 0.3), width: 1),
          ),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          boxShadow: [
            BoxShadow(color: levelColor.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5, offset: const Offset(0, -5))
          ]
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.satellite_alt_rounded, color: levelColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'TARGET_DATA // ${beacon.senderNickname.toUpperCase()}',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  _DetailRow(icon: Icons.warning_rounded, label: 'CLASS', value: beacon.level.label.toUpperCase(), color: levelColor),
                  if (beacon.bloodGroup.isNotEmpty)
                    _DetailRow(icon: Icons.bloodtype_rounded, label: 'TYPE', value: beacon.bloodGroup),
                  _DetailRow(icon: Icons.people_alt_rounded, label: 'SOULS', value: '${beacon.peopleCount}'),
                  if (beacon.hasLocation)
                    _DetailRow(
                      icon: Icons.location_on_rounded,
                      label: 'COORDS',
                      value: '${beacon.latitude!.toStringAsFixed(5)}, ${beacon.longitude!.toStringAsFixed(5)}',
                    ),
                  if (beacon.message.isNotEmpty)
                    _DetailRow(icon: Icons.message_rounded, label: 'MSG', value: beacon.message),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('CLOSE CONNECTION', style: TextStyle(fontFamily: 'monospace', color: scheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    final blips = buildRadarBlips(
      peers: state.peers,
      beacons: state.activeAlerts, // Ensuring we use activeAlerts which usually contains nearby beacons
      localDeviceId: state.deviceId ?? '',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        iconTheme: IconThemeData(color: scheme.primary),
        title: Row(
          children: [
            Icon(Icons.radar_rounded, color: scheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              'RADAR_SWEEP', 
              style: TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w900, color: scheme.primary, letterSpacing: 1.5)
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: scheme.primary.withValues(alpha: 0.2), height: 1.0),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
            ),
            child: IconButton(
              icon: Icon(Icons.sync_rounded, size: 20, color: scheme.primary),
              tooltip: 'RE-SCAN',
              onPressed: () => state.restartDiscovery(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Radar ─────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final radarSize = min(constraints.maxWidth, constraints.maxHeight);
                  return Center(
                    child: GestureDetector(
                      onTapUp: (details) => _handleRadarTap(details, radarSize, blips),
                      child: AnimatedBuilder(
                        animation: _sweepController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: Size(radarSize, radarSize),
                            painter: RadarPainter(
                              sweepAngle: _sweepController.value * 2 * pi,
                              blips: blips,
                              ringColor: scheme.primary,
                              sweepColor: scheme.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ─── Legend + stats ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LegendDot(color: scheme.primary, label: 'SAFE/NODE'),
                  _LegendDot(color: const Color(0xFFFFEA00), label: 'HELP'),
                  _LegendDot(color: const Color(0xFFFF9100), label: 'INJURED'),
                  _LegendDot(color: const Color(0xFFFF1744), label: 'TRAPPED'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ─── Active alerts list ────────────────────────────
          if (state.activeAlerts.isNotEmpty)
            Expanded(
              flex: 2,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: state.activeAlerts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final beacon = state.activeAlerts[index];
                  return SosBeaconCard(
                    beacon: beacon,
                    onTap: () => _showBeaconDetails(beacon),
                  );
                },
              ),
            )
          else
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.blur_circular_rounded,
                      size: 40,
                      color: scheme.primary.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SECTOR CLEAR',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        fontSize: 16
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.peers.length} NODES DETECTED ON MESH',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.white54,
                        letterSpacing: 1.0
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleRadarTap(
    TapUpDetails details,
    double radarSize,
    List<RadarBlip> blips,
  ) {
    final center = Offset(radarSize / 2, radarSize / 2);
    final radius = radarSize / 2 - 8;
    final tapPos = details.localPosition;

    for (final blip in blips) {
      final blipRadius = radius * blip.distance.clamp(0.05, 0.92);
      final bx = center.dx + blipRadius * sin(blip.angle);
      final by = center.dy - blipRadius * cos(blip.angle);

      final dist = (tapPos - Offset(bx, by)).distance;
      if (dist < 30 && blip.beacon != null) { // Slightly increased tap target area
        _showBeaconDetails(blip.beacon!);
        return;
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayColor = color ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? scheme.primary.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              label, 
              style: TextStyle(
                fontFamily: 'monospace', 
                fontWeight: FontWeight.bold, 
                fontSize: 11, 
                color: color ?? Colors.white54, 
                letterSpacing: 1.0
              )
            ),
          ),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(
                fontFamily: 'monospace', 
                fontSize: 12, 
                color: displayColor,
                fontWeight: color != null ? FontWeight.w900 : FontWeight.normal
              )
            )
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle, // Squared for tech look
            color: color,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1)
            ]
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}