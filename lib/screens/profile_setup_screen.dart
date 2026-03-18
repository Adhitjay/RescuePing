import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../services/app_state.dart';
import 'home_screen.dart';
import 'rescuer_home_screen.dart';

/// Rich onboarding screen — collects emergency profile info.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
    this.isEditing = false,
    this.role,
  });

  /// When true, we came from settings — show a back button.
  final bool isEditing;

  /// Role selected from RoleSelectionScreen (null when editing).
  final UserRole? role;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nicknameController = TextEditingController();
  final _medicalController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  String _bloodGroup = '';
  int _peopleCount = 1;
  late UserRole _role;

  static const _bloodGroups = [
    '',
    'A+',
    'A−',
    'B+',
    'B−',
    'AB+',
    'AB−',
    'O+',
    'O−',
  ];

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    if (profile != null) {
      _nicknameController.text = profile.nickname;
      _medicalController.text = profile.medicalNotes;
      _contactNameController.text = profile.emergencyContactName;
      _contactPhoneController.text = profile.emergencyContactPhone;
      _bloodGroup = profile.bloodGroup;
      _peopleCount = profile.peopleCount;
      _role = profile.role;
    } else {
      final nick = context.read<AppState>().nickname;
      if (nick != null) _nicknameController.text = nick;
      _role = widget.role ?? UserRole.needHelp;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _medicalController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  bool get _isRescuer => _role == UserRole.rescuer;

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFF1744),
          content: const Text('ERROR: IDENTIFIER REQUIRED', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        ),
      );
      return;
    }

    final profile = UserProfile(
      nickname: nickname,
      role: _role,
      bloodGroup: _isRescuer ? '' : _bloodGroup,
      medicalNotes: _isRescuer ? '' : _medicalController.text.trim(),
      emergencyContactName:
          _isRescuer ? '' : _contactNameController.text.trim(),
      emergencyContactPhone:
          _isRescuer ? '' : _contactPhoneController.text.trim(),
      peopleCount: _isRescuer ? 1 : _peopleCount,
    );

    await context.read<AppState>().saveProfile(profile);

    if (!mounted) return;

    if (widget.isEditing) {
      Navigator.of(context).pop();
    } else {
      // Route to the correct home based on role.
      final Widget home = _isRescuer
          ? const RescuerHomeScreen()
          : const HomeScreen();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => home),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text(
          widget.isEditing ? 'SYS_CONFIG // EDIT' : 'SYS_CONFIG // SETUP',
          style: TextStyle(fontFamily: 'monospace', fontSize: 16, letterSpacing: 1.5, color: scheme.primary),
        ),
        automaticallyImplyLeading: widget.isEditing,
        iconTheme: IconThemeData(color: scheme.primary),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ─── Header ───────────────────────────────────
              if (!widget.isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    border: Border.all(color: scheme.primary.withValues(alpha: 0.3), width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isRescuer ? Icons.shield_rounded : Icons.sos_rounded,
                        size: 40,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isRescuer ? 'COMMAND PROFILE' : 'DISTRESS PROFILE',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isRescuer
                                  ? 'Establish rescuer identity for mesh nodes.'
                                  : 'Data encrypted. Transmitted only during SOS broadcast.',
                              style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ─── Nickname ────────────────────────────────────
              _TechFormSection(
                title: 'IDENTITY_MATRIX',
                icon: Icons.badge_outlined,
                child: TextField(
                  controller: _nicknameController,
                  autofocus: !widget.isEditing,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                  decoration: _techInputDecoration(
                    scheme,
                    _isRescuer ? 'e.g. ALPHA-1' : 'e.g. CIV-01',
                    Icons.terminal_rounded,
                  ),
                ),
              ),

              // ─── Trapped person-only fields ─────────────────
              if (!_isRescuer) ...[
                const SizedBox(height: 16),

                // Blood group & people count
                _TechFormSection(
                  title: 'BIOMETRIC_DATA',
                  icon: Icons.fingerprint_rounded,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _bloodGroup,
                        dropdownColor: const Color(0xFF161616),
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                        decoration: _techInputDecoration(scheme, 'Blood Type (Optional)', Icons.water_drop_rounded),
                        items: _bloodGroups.map((g) {
                          return DropdownMenuItem(
                            value: g,
                            child: Text(g.isEmpty ? 'UNSPECIFIED' : g),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _bloodGroup = v ?? ''),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212),
                          border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.people_alt_rounded, size: 20, color: scheme.primary.withValues(alpha: 0.7)),
                            const SizedBox(width: 12),
                            const Text('SOULS ON BOARD:', style: TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12)),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline, color: _peopleCount > 1 ? scheme.primary : Colors.white24),
                              onPressed: _peopleCount > 1 ? () => setState(() => _peopleCount--) : null,
                            ),
                            SizedBox(
                              width: 30,
                              child: Text(
                                '$_peopleCount',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: scheme.primary),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline, color: scheme.primary),
                              onPressed: () => setState(() => _peopleCount++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Medical info
                _TechFormSection(
                  title: 'MEDICAL_RECORDS',
                  icon: Icons.medical_information_rounded,
                  child: TextField(
                    controller: _medicalController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                    decoration: _techInputDecoration(scheme, 'Allergies, conditions, meds...', Icons.health_and_safety_rounded),
                  ),
                ),

                const SizedBox(height: 16),

                // Emergency contact
                _TechFormSection(
                  title: 'EMERGENCY_UPLINK',
                  icon: Icons.contact_phone_rounded,
                  child: Column(
                    children: [
                      TextField(
                        controller: _contactNameController,
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                        decoration: _techInputDecoration(scheme, 'Contact Name (Optional)', Icons.person_outline_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _contactPhoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                        decoration: _techInputDecoration(scheme, 'Contact Phone (Optional)', Icons.phone_rounded),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.isEditing ? Icons.save : Icons.arrow_forward_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      widget.isEditing ? 'COMMIT CHANGES' : 'INITIALIZE PROTOCOL',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _techInputDecoration(ColorScheme scheme, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontFamily: 'monospace', fontSize: 12),
      prefixIcon: Icon(icon, color: scheme.primary.withValues(alpha: 0.5), size: 20),
      filled: true,
      fillColor: const Color(0xFF121212),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.2)),
      ),
    );
  }
}

class _TechFormSection extends StatelessWidget {
  const _TechFormSection({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: scheme.primary,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}