import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import 'profile_setup_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _selectRole(BuildContext context, UserRole role) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ProfileSetupScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Deep matte black
      body: Stack(
        children: [
          // Background Tech Grid Pattern
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter(color: scheme.primary)),
          ),

          // Foreground Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Impressive Animated Tech Logo
                      const _PulsingLogo(),

                      const SizedBox(height: 32),

                      // Glitch-style Title
                      Stack(
                        children: [
                          Text(
                            'RESCUE PING',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6.0,
                                  color: scheme.primary.withOpacity(0.5),
                                  fontSize: 26,
                                ),
                          ),
                          Positioned(
                            left: 2,
                            top: -1,
                            child: Text(
                              'RESCUE PING',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 6.0,
                                    color: Colors.white,
                                    fontSize: 26,
                                  ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Decorative status bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.1),
                          border: Border.all(
                            color: scheme.primary.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: scheme.primary,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'SYSTEM ONLINE // AWAITING CONFIG',
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: scheme.primary.withOpacity(0.2),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'SELECT OPERATING MODE',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white54,
                                letterSpacing: 2.0,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: scheme.primary.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Highly Detailed Role Cards
                      _TechRoleCard(
                        id: 'OP-01',
                        icon: Icons.shield_rounded,
                        title: 'COMMAND / RESCUER',
                        subtitle:
                            'Locate targets & deploy assistance to distress nodes',
                        onTap: () => _selectRole(context, UserRole.rescuer),
                      ),

                      const SizedBox(height: 16),

                      _TechRoleCard(
                        id: 'OP-02',
                        icon: Icons.sos_rounded,
                        title: 'DISTRESS BEACON',
                        subtitle:
                            'Broadcast emergency packets & await extraction',
                        onTap: () => _selectRole(context, UserRole.needHelp),
                      ),

                      const SizedBox(height: 40),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: scheme.primary.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                        ),
                        child: const Text(
                          'DATA SECURE. MODE CAN BE RECONFIGURED LATER IN SETTINGS.',
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 9,
                            letterSpacing: 1.0,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A highly detailed, modern tech card with gradients, glowing accents, and structural details.
class _TechRoleCard extends StatefulWidget {
  const _TechRoleCard({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_TechRoleCard> createState() => _TechRoleCardState();
}

class _TechRoleCardState extends State<_TechRoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) {
          setState(() => _isHovered = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(
            0.0,
            _isHovered ? -2.0 : 0.0,
            0.0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            // Sleek structural gradient instead of flat color
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _isHovered
                    ? primary.withOpacity(0.15)
                    : const Color(0xFF161616),
                const Color(0xFF0F0F0F),
              ],
            ),
            border: Border.all(
              color: _isHovered
                  ? primary.withOpacity(0.8)
                  : primary.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              // Glowing accent edge
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: _isHovered ? 4.0 : 2.0,
                  decoration: BoxDecoration(
                    color: primary,
                    boxShadow: _isHovered
                        ? [BoxShadow(color: primary, blurRadius: 8)]
                        : [],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Structural Icon Container
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF050505),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: primary.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            widget.icon,
                            size: 26,
                            color: _isHovered ? Colors.white : primary,
                          ),
                          if (_isHovered)
                            Icon(
                              widget.icon,
                              size: 26,
                              color: primary.withOpacity(0.5),
                            ), // Glow layer
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Main Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '[ ${widget.id} ]',
                                style: TextStyle(
                                  color: primary.withOpacity(0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const Spacer(),
                              // Decorative tech lines
                              Row(
                                children: List.generate(
                                  3,
                                  (index) => Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.only(left: 2),
                                    color: primary.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _isHovered
                                  ? Colors.white
                                  : const Color(0xFFEEEEEE),
                              letterSpacing: 1.2,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),
                    // Action indicator
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.double_arrow_rounded,
                        size: 16,
                        color: _isHovered ? primary : primary.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pulsing, multi-layered radar animation
class _PulsingLogo extends StatefulWidget {
  const _PulsingLogo();

  @override
  State<_PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<_PulsingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer expanding pulse
              Container(
                width: 140 * _controller.value,
                height: 140 * _controller.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primary.withOpacity((1.0 - _controller.value) * 0.5),
                    width: 2,
                  ),
                ),
              ),
              // Inner glowing core
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [primary.withOpacity(0.2), const Color(0xFF0A0A0A)],
                  ),
                  border: Border.all(
                    color: primary.withOpacity(0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Crosshair lines
                    Container(
                      width: 90,
                      height: 1,
                      color: primary.withOpacity(0.2),
                    ),
                    Container(
                      width: 1,
                      height: 90,
                      color: primary.withOpacity(0.2),
                    ),
                    // Center Icon
                    Icon(Icons.radar_rounded, size: 42, color: primary),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Background grid painter to give a tactical blueprint/HUD feel.
class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
          .withOpacity(0.03) // Very subtle
      ..strokeWidth = 1.0;

    const spacing = 30.0;

    // Vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    // Horizontal lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw some subtle crosshairs at random intersections
    final crosshairPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 2.0;

    void drawCrosshair(double x, double y) {
      canvas.drawLine(Offset(x - 5, y), Offset(x + 5, y), crosshairPaint);
      canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), crosshairPaint);
    }

    drawCrosshair(spacing * 3, spacing * 4);
    drawCrosshair(size.width - spacing * 4, spacing * 8);
    drawCrosshair(spacing * 5, size.height - spacing * 5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
