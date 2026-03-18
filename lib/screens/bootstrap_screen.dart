import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../services/app_state.dart';
import 'home_screen.dart';
import 'rescuer_home_screen.dart';
import 'role_selection_screen.dart';

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    Future.microtask(() {
      if (!mounted) return;
      context.read<AppState>().init();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    if (!state.isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.5 * _pulseController.value),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.2 * _pulseController.value),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(Icons.radar_rounded, color: scheme.primary, size: 48),
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 150,
                child: LinearProgressIndicator(
                  backgroundColor: scheme.primary.withValues(alpha: 0.1),
                  color: scheme.primary,
                  minHeight: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'INITIALIZING MESH PROTOCOLS...',
                style: TextStyle(
                  color: scheme.primary,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No profile / nickname yet → show role selection.
    if (state.nickname == null || state.nickname!.isEmpty) {
      return const RoleSelectionScreen();
    }

    // Route by role.
    if (state.userRole == UserRole.rescuer) {
      return const RescuerHomeScreen();
    }

    // Default: trapped person / need help.
    return const HomeScreen();
  }
}