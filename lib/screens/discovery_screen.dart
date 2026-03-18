import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/peer_tile.dart';
import 'chat_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  bool _permissionsRequested = false;
  bool _hadMissingPermissions = false;

  late final _LifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = _LifecycleObserver(onResumed: _onResumed);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_permissionsRequested) {
      _permissionsRequested = true;
      Future.microtask(() async {
        await _requestPermissionsIfNeeded();
        if (!mounted) return;
        await context.read<AppState>().startTransport();
      });
    }
  }

  Future<void> _requestPermissionsIfNeeded() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    final bluetoothOk =
        (statuses[Permission.bluetoothScan]?.isGranted ?? false) &&
        (statuses[Permission.bluetoothConnect]?.isGranted ?? false) &&
        (statuses[Permission.bluetoothAdvertise]?.isGranted ?? false);

    final locationOk = (statuses[Permission.location]?.isGranted ?? false);

    final discoveryOk = bluetoothOk && locationOk;

    final locationServiceOn =
        await Permission.locationWhenInUse.serviceStatus ==
        ServiceStatus.enabled;

    _hadMissingPermissions = !discoveryOk || !locationServiceOn;

    if (!mounted) return;

    if (!discoveryOk) {
      final permanentlyDenied = statuses.values.any(
        (s) => s.isPermanentlyDenied,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFF1744),
          content: const Text(
            'ERR: BLUETOOTH/LOCATION PERMISSIONS DENIED.',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: Colors.black),
          ),
          duration: const Duration(seconds: 6),
          action: permanentlyDenied
              ? SnackBarAction(label: 'SETTINGS', textColor: Colors.black, onPressed: openAppSettings)
              : null,
        ),
      );
    } else if (!locationServiceOn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFFEA00),
          content: const Text(
            'WARN: GPS OFFLINE. ENABLE LOCATION SERVICES.',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: Colors.black),
          ),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'SETTINGS',
            textColor: Colors.black,
            onPressed: openAppSettings,
          ),
        ),
      );
    }
  }

  Future<void> _onResumed() async {
    if (!mounted) return;
    if (!_hadMissingPermissions) return;

    await _requestPermissionsIfNeeded();
    if (!mounted) return;

    final state = context.read<AppState>();
    await state.stopTransport();
    await state.startTransport();
  }

  void _openChat() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    final connectedCount = state.peers.where((p) => p.isConnected).length;
    final discoveredCount = state.peers.length;
    final isRunning = state.transport?.isRunning == true;

    const transportLabel = 'NEARBY_CONNECTIONS_API';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Row(
          children: [
            Icon(Icons.hub_rounded, color: scheme.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              'MESH_TOPOLOGY',
              style: TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: scheme.primary),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: scheme.primary.withValues(alpha: 0.2), height: 1.0),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MeshHeroHeader(
                    nickname: state.nickname ?? 'UNKNOWN_NODE',
                    transportLabel: transportLabel,
                    isRunning: isRunning,
                    isConnecting: state.isConnecting,
                    connectedCount: connectedCount,
                    discoveredCount: discoveredCount,
                    hopLimit: state.meshHopLimit,
                  ),
                  const SizedBox(height: 16),
                  
                  // Diagnostic Terminal
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        iconColor: scheme.primary,
                        collapsedIconColor: scheme.primary.withValues(alpha: 0.5),
                        title: Text(
                          '> SYSTEM_DIAGNOSTICS',
                          style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: scheme.primary, fontSize: 13),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          _TransportLogs(logs: state.transportLogs),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Scanning Header
                  Row(
                    children: [
                      Text(
                        'LOCAL_NODES',
                        style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.5, fontSize: 12),
                      ),
                      const Spacer(),
                      if (isRunning && !state.isConnecting) ...[
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SCANNING...',
                          style: TextStyle(fontFamily: 'monospace', color: scheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: scheme.primary.withValues(alpha: 0.2), height: 1),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          
          if (state.peers.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRunning ? Icons.radar_rounded : Icons.wifi_off_rounded,
                      size: 48,
                      color: isRunning ? scheme.primary.withValues(alpha: 0.5) : const Color(0xFFFF1744).withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRunning ? 'AWAITING NODE DETECTION...' : 'TRANSPORT OFFLINE',
                      style: TextStyle(fontFamily: 'monospace', color: isRunning ? scheme.primary : const Color(0xFFFF1744), fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Verify Bluetooth & Location arrays are active.',
                      style: TextStyle(fontFamily: 'monospace', color: Colors.white30, fontSize: 10),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: state.peers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final peer = state.peers[index];
                  // Assuming PeerTile renders well in dark mode, wrapping in a styled container
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      border: Border.all(color: peer.isConnected ? scheme.primary : scheme.primary.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: PeerTile(
                      peer: peer,
                      onTap: peer.isConnected
                          ? () => context.read<AppState>().disconnectPeer(peer.peerId)
                          : () => context.read<AppState>().connectToPeer(peer.peerId),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChat,
        backgroundColor: scheme.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: scheme.primary),
        ),
        label: Text('COMMS', style: TextStyle(fontFamily: 'monospace', color: scheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        icon: Icon(Icons.chat_rounded, color: scheme.primary, size: 18),
      ),
    );
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  _LifecycleObserver({required this.onResumed});

  final Future<void> Function() onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}

class _MeshHeroHeader extends StatelessWidget {
  const _MeshHeroHeader({
    required this.nickname,
    required this.transportLabel,
    required this.isRunning,
    required this.isConnecting,
    required this.connectedCount,
    required this.discoveredCount,
    required this.hopLimit,
  });

  final String nickname;
  final String transportLabel;
  final bool isRunning;
  final bool isConnecting;
  final int connectedCount;
  final int discoveredCount;
  final int hopLimit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.4), width: 1.5),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(color: scheme.primary.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: -5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              border: Border(bottom: BorderSide(color: scheme.primary.withValues(alpha: 0.4))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${nickname.toUpperCase()}',
                  style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: scheme.primary, letterSpacing: 1.5, fontSize: 13),
                ),
                _StatusPill(
                  label: isRunning ? (isConnecting ? 'INITIATING' : 'ONLINE') : 'OFFLINE',
                  color: isRunning ? scheme.primary : const Color(0xFFFF1744),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings_input_antenna_rounded, size: 14, color: Colors.white54),
                    const SizedBox(width: 8),
                    Text(
                      'PROTOCOL: $transportLabel',
                      style: const TextStyle(fontFamily: 'monospace', color: Colors.white54, fontSize: 10, letterSpacing: 1.0),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _StatBox(label: 'UPLINK', value: '$connectedCount', color: scheme.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatBox(label: 'DETECTED', value: '$discoveredCount', color: Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatBox(label: 'TTL_HOPS', value: '$hopLimit', color: const Color(0xFFFFEA00))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 18, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.white54, letterSpacing: 1.0)),
        ],
      ),
    );
  }
}

class _TransportLogs extends StatelessWidget {
  const _TransportLogs({required this.logs});

  final List<String> logs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: logs.isEmpty
          ? const Text('> Awaiting events...', style: TextStyle(fontFamily: 'monospace', color: Colors.white30, fontSize: 11))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: logs.take(10).map((l) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '> $l',
                    style: TextStyle(fontFamily: 'monospace', color: scheme.primary.withValues(alpha: 0.8), fontSize: 10),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: color),
      ),
    );
  }
}