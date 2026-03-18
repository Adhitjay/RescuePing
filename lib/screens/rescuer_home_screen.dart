import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sos_status.dart';
import '../services/app_state.dart';
import '../services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_screen.dart';
import 'discovery_screen.dart';
import 'profile_setup_screen.dart';
import 'rescuer_map_screen.dart';
import 'role_selection_screen.dart';

/// Home screen for rescuers — Dashboard with SOS list, Chat, and Mesh tabs.
class RescuerHomeScreen extends StatefulWidget {
  const RescuerHomeScreen({super.key});

  @override
  State<RescuerHomeScreen> createState() => _RescuerHomeScreenState();
}

class _RescuerHomeScreenState extends State<RescuerHomeScreen> {
  int _tabIndex = 0;

  static const _tabs = [
    _Tab(icon: Icons.dashboard_rounded, label: 'COMMAND'),
    _Tab(icon: Icons.chat_rounded, label: 'COMMS'),
    _Tab(icon: Icons.radar_rounded, label: 'RADAR'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          _RescuerDashboard(),
          ChatScreen(),
          DiscoveryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0A0A0A),
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(icon: Icon(t.icon), label: t.label),
            )
            .toList(),
      ),
    );
  }
}

class _Tab {
  const _Tab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Rescuer dashboard — shows active SOS alerts with actions.
class _RescuerDashboard extends StatelessWidget {
  const _RescuerDashboard();

  void _switchRole(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), 
          side: BorderSide(color: scheme.primary)
        ),
        icon: Icon(
          Icons.swap_horiz_rounded,
          size: 40,
          color: scheme.primary,
        ),
        title: Text('RECONFIGURE ROLE', style: TextStyle(fontFamily: 'monospace', color: scheme.primary, fontWeight: FontWeight.w900)),
        content: const Text(
          'This resets profile data and initiates role selection protocol.\n\nProceed?',
          style: TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ABORT', style: TextStyle(fontFamily: 'monospace', color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AppState>().resetApp();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const RoleSelectionScreen(),
                ),
                (_) => false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('PROCEED', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final alerts = state.activeAlerts;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.shield_rounded, color: scheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'TACTICAL_COMMAND',
              style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: scheme.primary, fontSize: 16, letterSpacing: 1.5),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: scheme.primary.withValues(alpha: 0.2), height: 1.0),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.settings_outlined, color: scheme.primary),
            color: const Color(0xFF161616),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
            ),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const ProfileSetupScreen(isEditing: true),
                    ),
                  );
                case 'switch':
                  _switchRole(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.terminal_rounded, color: scheme.primary),
                  title: const Text('EDIT_CONFIG', style: TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'switch',
                child: ListTile(
                  leading: Icon(Icons.swap_horiz_rounded, color: scheme.primary),
                  title: const Text('SWITCH_ROLE', style: TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Hero stats card ────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _GlowingStat(
                              icon: Icons.hub_rounded,
                              value: '${state.peers.length}',
                              label: 'NET NODES',
                              color: scheme.primary,
                            ),
                            _GlowingStat(
                              icon: Icons.satellite_alt_rounded,
                              value: '${state.peers.where((p) => p.isConnected).length}',
                              label: 'UPLINK',
                              color: scheme.primary,
                            ),
                            _GlowingStat(
                              icon: Icons.warning_amber_rounded,
                              value: '${alerts.length}',
                              label: 'CRITICAL',
                              color: alerts.isNotEmpty ? const Color(0xFFFF1744) : Colors.white30,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ─── Section header ─────────────────────────
                  Row(
                    children: [
                      Text(
                        'ACTIVE TARGETS',
                        style: TextStyle(
                          color: scheme.primary, 
                          fontWeight: FontWeight.w900, 
                          fontFamily: 'monospace',
                          letterSpacing: 2.0, 
                          fontSize: 12
                        ),
                      ),
                      const Spacer(),
                      if (alerts.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFFF1744).withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(2),
                            color: const Color(0xFFFF1744).withValues(alpha: 0.1),
                          ),
                          child: Text(
                            '${alerts.length} SIGNAL(S)',
                            style: const TextStyle(
                              color: Color(0xFFFF1744),
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ─── Alert cards ────────────────────────────────────
          if (alerts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radar_rounded, size: 48, color: scheme.primary.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'SECTOR CLEAR',
                      style: TextStyle(
                        color: scheme.primary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Monitoring mesh network...',
                      style: TextStyle(
                        color: Colors.white54,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: alerts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _AlertCard(beacon: alerts[index]);
                },
              ),
            ),
            
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _GlowingStat extends StatelessWidget {
  const _GlowingStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.5)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.beacon});
  final SosBeacon beacon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color levelColor;
    switch (beacon.level) {
      case SosLevel.trapped:
        levelColor = const Color(0xFFFF1744);
      case SosLevel.injured:
        levelColor = const Color(0xFFFF9100);
      case SosLevel.needHelp:
        levelColor = const Color(0xFFFFEA00);
      case SosLevel.safe:
        levelColor = scheme.primary;
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RescuerMapScreen(beacon: beacon),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          border: Border(left: BorderSide(color: levelColor, width: 4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beacon.senderNickname.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: levelColor.withValues(alpha: 0.2),
                        child: Text(
                          beacon.level.label.toUpperCase(),
                          style: TextStyle(
                            color: levelColor,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: scheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  if (beacon.hasLocation) ...[
                    Icon(Icons.location_on_rounded, size: 14, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${beacon.latitude!.toStringAsFixed(4)}, ${beacon.longitude!.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.primary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.location_off_rounded, size: 14, color: Color(0xFFFF1744)),
                    const SizedBox(width: 4),
                    const Text(
                      'NO GPS FIX',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF1744),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (beacon.bloodGroup.isNotEmpty) ...[
                    Icon(Icons.bloodtype_rounded, size: 14, color: const Color(0xFFFF1744)),
                    const SizedBox(width: 4),
                    Text(
                      beacon.bloodGroup,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Icon(Icons.people_rounded, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    '${beacon.peopleCount}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            if (beacon.hasLocation) ...[
              const SizedBox(height: 16),
              _DirectionsButton(beacon: beacon),
            ],
          ],
        ),
      ),
    );
  }
}

class _DirectionsButton extends StatefulWidget {
  const _DirectionsButton({required this.beacon});
  final SosBeacon beacon;

  @override
  State<_DirectionsButton> createState() => _DirectionsButtonState();
}

class _DirectionsButtonState extends State<_DirectionsButton> {
  final LocationService _location = LocationService();
  bool _launching = false;

  Future<void> _openMaps() async {
    setState(() => _launching = true);

    final pos = await _location.getLocationOnce();
    final destLat = widget.beacon.latitude!;
    final destLng = widget.beacon.longitude!;

    Uri mapsUri;
    if (pos != null) {
      mapsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${pos.latitude},${pos.longitude}'
        '&destination=$destLat,$destLng'
        '&travelmode=driving',
      );
    } else {
      mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$destLat,$destLng',
      );
    }

    try {
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      } else {
        _showError();
      }
    } catch (e) {
      _showError();
    }

    if (mounted) setState(() => _launching = false);
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFFFF1744),
        content: Text('ERR: NAV_SYSTEM OFFLINE OR MAPS NOT INSTALLED', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.black)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    if (_launching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary)),
        )
      );
    }
    
    return OutlinedButton.icon(
      onPressed: _openMaps,
      icon: Icon(Icons.satellite_alt_rounded, size: 16, color: scheme.primary),
      label: Text('ROUTE TO TARGET', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: scheme.primary, letterSpacing: 1.0)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: scheme.primary.withValues(alpha: 0.1),
      ),
    );
  }
}