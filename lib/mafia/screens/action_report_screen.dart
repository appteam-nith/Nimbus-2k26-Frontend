import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../models/action_report_model.dart';

/// Listens to [GameController.pendingActionReport] and shows a full-screen
/// Cyberpunk/Terminal overlay whenever an action report arrives.
class ActionReportListener extends StatefulWidget {
  final Widget child;
  const ActionReportListener({super.key, required this.child});

  @override
  State<ActionReportListener> createState() => _ActionReportListenerState();
}

class _ActionReportListenerState extends State<ActionReportListener> {
  OverlayEntry? _overlayEntry;
  ActionReport? _lastReport;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gc = context.watch<GameController>();
    final pending = gc.pendingActionReport;

    if (pending != null && pending != _lastReport) {
      _lastReport = pending;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOverlay(pending);
      });
    }
  }

  void _showOverlay(ActionReport report) {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (_) => _ActionReportOverlay(
        report: report,
        onDismiss: _dismiss,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _dismiss() {
    _removeOverlay();
    if (mounted) {
      context.read<GameController>().dismissActionReport();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// ─── OVERLAY WIDGET ───────────────────────────────────────────────────────────

class _ActionReportOverlay extends StatefulWidget {
  final ActionReport report;
  final VoidCallback onDismiss;

  const _ActionReportOverlay({
    required this.report,
    required this.onDismiss,
  });

  @override
  State<_ActionReportOverlay> createState() => _ActionReportOverlayState();
}

class _ActionReportOverlayState extends State<_ActionReportOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<double>(begin: 0.1, end: 0.0).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
    );

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _enterController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _enterController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnim.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnim.value * MediaQuery.of(context).size.height),
              child: GestureDetector(
                onTap: _handleDismiss,
                child: Container(
                  color: const Color(0xFF0A0E17), // Deep space background
                  child: SafeArea(
                    child: _buildReportContent(context),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportContent(BuildContext context) {
    switch (widget.report.type) {
      case ActionReportType.mafiaKill:
        return _buildMafiaKillUI();
      case ActionReportType.bountyKill:
        return _buildBountyKillUI();
      case ActionReportType.doctorSave:
        return _buildDoctorSaveUI();
      case ActionReportType.copInvestigate:
        return _buildCopInvestigationUI();
      case ActionReportType.nurseFindsDoctor:
        return _buildNurseFindUI();
    }
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader({required Color accentColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.grid_view_rounded, color: accentColor, size: 20),
            const SizedBox(width: 12),
            const Text(
              'NIMBUS OPERATIVE',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF97316),
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Icon(Icons.wifi_tethering, color: accentColor, size: 20),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accentColor, width: 4)),
          ),
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SEQUENCE_RESULT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  letterSpacing: 2,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'NIGHT ACTION REPORT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── MAFIA / HITMAN KILL UI ────────────────────────────────────────────────
  Widget _buildMafiaKillUI() {
    const accentColor = Color(0xFFEF4444); // Red
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(accentColor: accentColor),
          _buildLocationBlock(accentColor: accentColor, location: 'DARK ALLEY', status: 'CASE CLOSED'),
          const SizedBox(height: 20),
          _buildImagePlaceholder(
            accentColor: accentColor,
            imagePath: 'assets/images/mafia/kill_success.png',
            icon: Icons.person_off_rounded,
            title: widget.report.title.isNotEmpty ? widget.report.title : 'TERMINATED',
            subtitle: widget.report.targetName ?? 'UNKNOWN ASSET',
          ),
          const SizedBox(height: 20),
          _buildPrimaryAlertBlock(
            accentColor: accentColor,
            icon: Icons.my_location,
            title: 'TARGET NEUTRALIZED',
            subtitle: widget.report.description,
          ),
          const SizedBox(height: 20),
          _buildMetricsGrid(accentColor: accentColor, precision: widget.report.precision ?? 98.2),
          const Spacer(),
          _buildTapToDismiss(),
        ],
      ),
    );
  }

  // ─── BOUNTY KILL UI ────────────────────────────────────────────────────────
  Widget _buildBountyKillUI() {
    const accentColor = Color(0xFFF59E0B); // Amber
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(accentColor: accentColor),
          _buildImagePlaceholder(
            accentColor: accentColor,
            imagePath: 'assets/images/mafia/bounty_claimed.png',
            icon: Icons.monetization_on_rounded,
            title: widget.report.title.isNotEmpty ? widget.report.title : 'BOUNTY CLAIMED',
            subtitle: widget.report.description,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  accentColor: accentColor,
                  label: 'PRECISION',
                  value: '${(widget.report.precision ?? 94.0).toInt()}%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  accentColor: accentColor,
                  label: 'XP GAINED',
                  value: '+${widget.report.xpGained ?? 1200}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMissionIntelBlock(accentColor: accentColor),
          const Spacer(),
          _buildTapToDismiss(),
        ],
      ),
    );
  }

  // ─── DOCTOR SAVE UI ────────────────────────────────────────────────────────
  Widget _buildDoctorSaveUI() {
    const accentColor = Color(0xFF22C55E); // Green
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(accentColor: accentColor),
          _buildImagePlaceholder(
            accentColor: accentColor,
            imagePath: 'assets/images/mafia/doctor_cure.png',
            icon: Icons.medical_services_rounded,
            title: widget.report.title.isNotEmpty ? widget.report.title : 'TARGET SAVED',
            subtitle: widget.report.description,
          ),
          const SizedBox(height: 20),
          _buildActionLogBlock(
            accentColor: accentColor,
            title: 'ACTION LOG EXCERPT',
            logEntries: [
              '[03:45] Intercepted hostile signature moving toward target.',
              '[03:58] Critical intervention applied. Hostile force retreated.',
              '[04:10] Target stabilized. Patient extracted to safe zone. STATUS: STABLE.',
            ],
          ),
          const Spacer(),
          _buildTapToDismiss(),
        ],
      ),
    );
  }

  // ─── COP INVESTIGATION UI ──────────────────────────────────────────────────
  Widget _buildCopInvestigationUI() {
    const accentColor = Color(0xFF3B82F6); // Blue
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(accentColor: accentColor),
          _buildImagePlaceholder(
            accentColor: accentColor,
            imagePath: 'assets/images/mafia/investigate_success.png',
            icon: Icons.fingerprint_rounded,
            title: widget.report.title.isNotEmpty ? widget.report.title : 'INVESTIGATION: SUCCESS',
            subtitle: widget.report.description,
          ),
          const SizedBox(height: 20),
          _buildActionLogBlock(
            accentColor: accentColor,
            title: 'OPERATIONAL BRIEF',
            logEntries: [
              'Subject intercepted at sector checkpoints.',
              'High frequency surveillance confirmed unauthorized data transfer.',
              'Result matched against central database: Role is ${widget.report.roleName ?? 'CONFIRMED'}.',
            ],
          ),
          const Spacer(),
          _buildTapToDismiss(),
        ],
      ),
    );
  }

  // ─── NURSE FINDS DOCTOR UI ─────────────────────────────────────────────────
  Widget _buildNurseFindUI() {
    const accentColor = Color(0xFF34D399); // Teal
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(accentColor: accentColor),
          _buildImagePlaceholder(
            accentColor: accentColor,
            imagePath: 'assets/images/mafia/doctor_meet.png',
            icon: Icons.group_add_rounded,
            title: widget.report.title.isNotEmpty ? widget.report.title : 'CONTACT ESTABLISHED',
            subtitle: widget.report.description,
          ),
          const SizedBox(height: 20),
          _buildPrimaryAlertBlock(
            accentColor: accentColor,
            icon: Icons.connect_without_contact,
            title: 'MEDICAL LINK ACTIVE',
            subtitle: 'Secure medical comms channel has been opened.',
          ),
          const Spacer(),
          _buildTapToDismiss(),
        ],
      ),
    );
  }

  // ─── REUSABLE UI WIDGETS ────────────────────────────────────────────────────

  Widget _buildLocationBlock({required Color accentColor, required String location, required String status}) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF161B26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LOCATION', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(location, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('STATUS', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(status, style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder({
    required Color accentColor,
    required IconData icon,
    required String title,
    required String subtitle,
    String? imagePath,
  }) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 20)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(icon, size: 80, color: accentColor.withOpacity(0.2)),
                ),
              )
            else
              Center(child: Icon(icon, size: 80, color: accentColor.withOpacity(0.2))),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryAlertBlock({
    required Color accentColor,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF161B26),
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid({required Color accentColor, required double precision}) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF161B26),
      child: Column(
        children: [
          _buildMetricRow('PRECISION', '${precision}%', accentColor),
          const SizedBox(height: 12),
          _buildMetricRow('LEGAL RISK', 'LOW', accentColor),
          const SizedBox(height: 12),
          _buildMetricRow('FACTION XP', '+450', Colors.white),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, letterSpacing: 1)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildMetricCard({required Color accentColor, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF161B26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(height: 2, color: accentColor, width: double.infinity),
        ],
      ),
    );
  }

  Widget _buildActionLogBlock({required Color accentColor, required String title, required List<String> logEntries}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              Icon(Icons.monitor_heart, color: accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          for (final log in logEntries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                log,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMissionIntelBlock({required Color accentColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF161B26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: accentColor, size: 20),
              const SizedBox(width: 8),
              const Text('MISSION INTEL', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricRow('PRIMARY OBJECTIVE', 'COMPLETED', accentColor),
          const SizedBox(height: 12),
          _buildMetricRow('AUTO-TRANSACTION', 'VERIFIED', Colors.white),
        ],
      ),
    );
  }

  Widget _buildTapToDismiss() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Text(
          'TAP ANYWHERE TO DISMISS LOG',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            letterSpacing: 3,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}
