import 'package:flutter/material.dart';

import '../models/peer_device.dart';

class PeerTile extends StatelessWidget {
  const PeerTile({super.key, required this.peer, required this.onTap});

  final PeerDevice peer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final isConnected = peer.isConnected;
    final borderColor = isConnected ? scheme.primary : Colors.white24;
    final bgColor = isConnected ? scheme.primary.withValues(alpha: 0.1) : const Color(0xFF121212);
    final iconColor = isConnected ? scheme.primary : Colors.white54;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: isConnected ? 1.5 : 1.0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Node Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    isConnected ? Icons.satellite_alt_rounded : Icons.device_unknown_rounded,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Node Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peer.displayName.toUpperCase(),
                        style: TextStyle(
                          color: isConnected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 1.0,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MAC/ID: ${peer.peerId}',
                        style: TextStyle(
                          color: isConnected ? scheme.primary.withValues(alpha: 0.7) : Colors.white30,
                          fontFamily: 'monospace',
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Action Button Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isConnected ? scheme.primary : Colors.transparent,
                    border: Border.all(color: isConnected ? scheme.primary : Colors.white30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    isConnected ? 'UPLINKED' : 'CONNECT',
                    style: TextStyle(
                      color: isConnected ? Colors.black : Colors.white54,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}