import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sos_status.dart';
import '../services/app_state.dart';
import '../widgets/sos_beacon_card.dart';
import '../widgets/sos_button.dart';
import 'chat_screen.dart';
import 'discovery_screen.dart';
import 'profile_setup_screen.dart';
import 'role_selection_screen.dart';

/// Main home screen for trapped persons — 3 tabs: Home, Chat, Mesh.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  static const _tabs = [
    _Tab(icon: Icons.terminal_rounded, label: 'SYS_DASH'),
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
          _DashboardTab(),
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

/// The main dashboard tab for trapped persons.
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  StreamSubscription<String>? _rescueConfirmSub;

  @override
  void initState() {
    super.initState();
    // Listen for incoming rescue confirmations.
    Future.microtask(() {
      if (!mounted) return;
      final state = context.read<AppState>();
      _rescueConfirmSub = state.rescueConfirmReceived.listen((rescuerName) {
        if (!mounted) return;
        _showRescueConfirmDialog(rescuerName);
      });
    });
  }

  @override
  void dispose() {
    _rescueConfirmSub?.cancel();
    super.dispose();
  }

  void _showRescueConfirmDialog(String rescuerName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), 
          side: BorderSide(color: Theme.of(context).colorScheme.primary)
        ),
        icon: Icon(
          Icons.health_and_safety_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          'RESCUE CONFIRMATION', 
          style: TextStyle(fontFamily: 'monospace', color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.0)
        ),
        content: Text(
          '${rescuerName.toUpperCase()} has marked you as rescued.\n\n'
          'Confirm safety status to halt SOS broadcast.',
          style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DENY', style: TextStyle(fontFamily: 'monospace', color: Colors.white54)),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().confirmRescued();
            },
            icon: const Icon(Icons.check_rounded, color: Colors.black),
            label: const Text('CONFIRM SECURE', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900)),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  void _alertOthers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SosLevelPicker(
        onSelected: (level) {
          context.read<AppState>().alertOthers(level: level);
        },
      ),
    );
  }

  void _quickAlert(BuildContext context) {
    final state = context.read<AppState>();
    if (state.isSosActive) {
      state.cancelAlert();
    } else {
      state.alertOthers(level: SosLevel.needHelp);
    }
  }

  void _selfConfirmRescue() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), 
          side: BorderSide(color: Theme.of(context).colorScheme.primary)
        ),
        icon: Icon(
          Icons.verified_user_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          'CANCEL BEACON', 
          style: TextStyle(fontFamily: 'monospace', color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)
        ),
        content: const Text(
          'Confirm safe status?\n\n'
          'This halts broadcast and resets profile state.',
          style: TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ABORT', style: TextStyle(fontFamily: 'monospace', color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().confirmRescued();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('CONFIRM', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    final alertCount = state.activeAlerts.length;

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
              child: Icon(Icons.sos_rounded, color: scheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'DISTRESS_NODE',
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
            child: Column(
              children: [
                const SizedBox(height: 32),

                // ─── SOS Button ───────────────────────────────────
                SosButton(
                  isActive: state.isSosActive,
                  currentLevel: state.currentSosLevel,
                  onTap: () => _quickAlert(context),
                  onLongPress: () => _alertOthers(context),
                ),

                const SizedBox(height: 24),

                // ─── Status text ──────────────────────────────────
                if (state.isSosActive) ...[
                  Text(
                    'BEACON ACTIVE: ${state.currentSosLevel.label.toUpperCase()}',
                    style: const TextStyle(
                      color: Color(0xFFFF1744),
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () => state.cancelAlert(),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('ABORT TRANSMISSION', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF1744)),
                  ),
                  const SizedBox(height: 16),
                  
                  // ─── "I've Been Rescued" button ──────────────
                  OutlinedButton.icon(
                    onPressed: _selfConfirmRescue,
                    icon: Icon(Icons.security_rounded, color: scheme.primary, size: 20),
                    label: Text('MARK AS SECURED', style: TextStyle(fontFamily: 'monospace', color: scheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: scheme.primary, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      backgroundColor: scheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ] else ...[
                  Text(
                    'TAP TO TRANSMIT SOS',
                    style: TextStyle(
                      color: scheme.primary.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontFamily: 'monospace',
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HOLD TO CONFIGURE',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // ─── Stats bar ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          icon: Icons.hub_rounded,
                          value: '${state.peers.length}',
                          label: 'NODES',
                        ),
                        _StatItem(
                          icon: Icons.satellite_alt_rounded,
                          value: '${state.peers.where((p) => p.isConnected).length}',
                          label: 'UPLINK',
                        ),
                        _StatItem(
                          icon: Icons.warning_rounded,
                          value: '$alertCount',
                          label: 'ALERTS',
                          color: alertCount > 0 ? const Color(0xFFFF1744) : null,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ─── Section header ───────────────────────────────
                if (state.activeAlerts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF1744), size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'EXTERNAL BEACONS DETECTED',
                          style: TextStyle(
                            color: Color(0xFFFF1744),
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            letterSpacing: 1.5
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ─── Alert cards ─────────────────────────────────────────
          if (state.activeAlerts.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: state.activeAlerts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return SosBeaconCard(beacon: state.activeAlerts[index]);
                },
              ),
            ),
            
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c.withValues(alpha: 0.5)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            fontSize: 24,
            color: c,
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