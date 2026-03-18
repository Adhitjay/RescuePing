import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/sos_status.dart';
import '../services/app_state.dart';
import '../services/location_service.dart';

/// Full-screen details + directions for a specific SOS alert.
class RescuerMapScreen extends StatefulWidget {
  const RescuerMapScreen({super.key, required this.beacon});

  final SosBeacon beacon;

  @override
  State<RescuerMapScreen> createState() => _RescuerMapScreenState();
}

class _RescuerMapScreenState extends State<RescuerMapScreen> {
  final LocationService _location = LocationService();
  bool _launching = false;

  Future<void> _openMaps() async {
    if (!widget.beacon.hasLocation) return;

    setState(() => _launching = true);

    final pos = await _location.getLocationOnce();
    final destLat = widget.beacon.latitude!;
    final destLng = widget.beacon.longitude!;

    Uri mapsUri;
    if (pos != null) {
      // Use standard Google Maps Directions API URL format
      mapsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${pos.latitude},${pos.longitude}'
        '&destination=$destLat,$destLng'
        '&travelmode=driving',
      );
    } else {
      // Fallback to just opening the location if user's own GPS fails
      mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$destLat,$destLng');
    }

    try {
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      } else {
        _showNavError();
      }
    } catch (e) {
      _showNavError();
    }

    if (mounted) setState(() => _launching = false);
  }

  void _showNavError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFFFF1744),
        content: Text('ERR: NAV_SYSTEM OFFLINE OR MAPS NOT INSTALLED', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.black)),
      ),
    );
  }

  void _markRescued() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616), // Moved inside AlertDialog
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), 
          side: BorderSide(color: Theme.of(context).colorScheme.primary)
        ), // Moved inside AlertDialog
        title: Text(
          'CONFIRM EXTRACTION', 
          style: TextStyle(fontFamily: 'monospace', color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)
        ),
        content: Text(
          'Target: ${widget.beacon.senderNickname.toUpperCase()}\n\n'
          'Confirm visual on target and transmit SECURE code to node?',
          style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ABORT', style: TextStyle(fontFamily: 'monospace', color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().markAsRescued(widget.beacon.senderDeviceId);
              Navigator.pop(context); // Go back to command dash
            },
            child: const Text('CONFIRM SECURE', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(SosLevel level, ColorScheme scheme) {
    switch (level) {
      case SosLevel.trapped:
        return const Color(0xFFFF1744);
      case SosLevel.injured:
        return const Color(0xFFFF9100);
      case SosLevel.needHelp:
        return const Color(0xFFFFEA00);
      case SosLevel.safe:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final beacon = widget.beacon;
    final levelColor = _getLevelColor(beacon.level, scheme);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        iconTheme: IconThemeData(color: scheme.primary),
        title: Text('TARGET_DATA: ${beacon.senderNickname.toUpperCase()}', style: TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w900, color: scheme.primary, letterSpacing: 1.0)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: scheme.primary.withValues(alpha: 0.2), height: 1.0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── Severity header ─────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border.all(color: levelColor, width: 2),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: levelColor.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: -5)],
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 40, color: levelColor),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLASS: ${beacon.level.label.toUpperCase()}',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: levelColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SOULS IN SECTOR: ${beacon.peopleCount}',
                        style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 11, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Details card ───────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '> PAYLOAD_DATA',
                  style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: scheme.primary, letterSpacing: 1.5, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.badge_outlined, label: 'ID', value: beacon.senderNickname.toUpperCase()),
                
                if (beacon.bloodGroup != null && beacon.bloodGroup!.isNotEmpty)
                  _InfoRow(icon: Icons.water_drop_rounded, label: 'TYPE', value: beacon.bloodGroup!),
                  
                if (beacon.hasLocation) ...[
                  _InfoRow(icon: Icons.my_location_rounded, label: 'LAT', value: beacon.latitude!.toStringAsFixed(6)),
                  _InfoRow(icon: Icons.location_searching_rounded, label: 'LNG', value: beacon.longitude!.toStringAsFixed(6)),
                ],
                
                if (beacon.message != null && beacon.message!.isNotEmpty)
                  _InfoRow(icon: Icons.message_rounded, label: 'MSG', value: beacon.message!),
                  
                _InfoRow(icon: Icons.schedule_rounded, label: 'TX_TIME', value: _formatTime(beacon.timestampMs)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ─── Action buttons ─────────────────────────
          if (beacon.hasLocation)
            FilledButton(
              onPressed: _launching ? null : _openMaps,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary.withValues(alpha: 0.1),
                foregroundColor: scheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: scheme.primary, width: 1.5)),
              ),
              child: _launching
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.satellite_alt_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('INITIATE ROUTING [MAPS]', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0)),
                      ],
                    ),
            ),

          if (!beacon.hasLocation)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                border: Border.all(color: const Color(0xFFFF1744).withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gps_off_rounded, color: Color(0xFFFF1744)),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'NO TELEMETRY DATA. TARGET LOCATION UNKNOWN.',
                      style: TextStyle(fontFamily: 'monospace', color: Colors.white54, fontSize: 11, letterSpacing: 1.0),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          FilledButton(
            onPressed: _markRescued,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_rounded, size: 20),
                SizedBox(width: 12),
                Text('CONFIRM TARGET SECURED', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'JUST NOW';
    if (diff.inMinutes < 60) return 'T-MINUS ${diff.inMinutes}M';
    if (diff.inHours < 24) return 'T-MINUS ${diff.inHours}H';
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: scheme.primary.withValues(alpha: 0.5)),
          const SizedBox(width: 16),
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white54, letterSpacing: 1.0)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}