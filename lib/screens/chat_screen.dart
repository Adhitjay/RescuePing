import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    await context.read<AppState>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final messages = state.messages;
    final scheme = Theme.of(context).colorScheme;
    final connected = state.peers.where((p) => p.isConnected).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.satellite_alt_rounded, color: scheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMMS_LINK',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2.0),
                ),
                Text(
                  'UPLINK: $connected NODES • TTL: ${state.meshHopLimit}',
                  style: TextStyle(
                    color: scheme.primary.withValues(alpha: 0.7),
                    fontFamily: 'monospace',
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: scheme.primary.withValues(alpha: 0.2), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.terminal_rounded, size: 48, color: scheme.primary.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'NO TRANSMISSIONS DETECTED',
                          style: TextStyle(color: scheme.primary.withValues(alpha: 0.4), fontFamily: 'monospace', letterSpacing: 1.5, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      // MessageBubble was styled in the previous step
                      return MessageBubble(message: m);
                    },
                  ),
          ),
          
          // Terminal Input Area
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              border: Border(top: BorderSide(color: scheme.primary.withValues(alpha: 0.2))),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Text(
                      '>',
                      style: TextStyle(color: scheme.primary, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Transmit payload...',
                          hintStyle: const TextStyle(color: Colors.white24, fontFamily: 'monospace'),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        border: Border.all(color: scheme.primary.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: IconButton(
                        onPressed: _send,
                        icon: Icon(Icons.send_rounded, color: scheme.primary, size: 20),
                        tooltip: 'TX DATA',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}