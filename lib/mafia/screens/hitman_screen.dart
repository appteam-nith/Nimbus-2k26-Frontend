import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../models/player_model.dart';
import '../services/game_api.dart';

class HitmanScreen extends StatefulWidget {
  const HitmanScreen({super.key});

  @override
  State<HitmanScreen> createState() => _HitmanScreenState();
}

class _HitmanScreenState extends State<HitmanScreen> {
  PlayerModel? _selectedPlayer;
  String? _selectedRole;
  bool _isSubmitting = false;

  final Color _bgDark = const Color(0xFF0F0F0F);
  final Color _bgCard = const Color(0xFF1A1C1E);
  final Color _accentOrange = const Color(0xFFFF8566);
  final Color _textMuted = const Color(0xFF888888);

  final List<Map<String, dynamic>> _allRoles = [
    {'name': 'MAFIA', 'icon': Icons.dangerous},
    {'name': 'COP', 'icon': Icons.local_police},
    {'name': 'VIGILANTE', 'icon': Icons.remove_red_eye},
    {'name': 'AGENT', 'icon': Icons.real_estate_agent},
    {'name': 'DOCTOR', 'icon': Icons.medical_services},
    {'name': 'CITIZEN', 'icon': Icons.person},
    {'name': 'SOLDIER', 'icon': Icons.security},
    {'name': 'POLITICIAN', 'icon': Icons.account_balance},
    {'name': 'PSYCHIC', 'icon': Icons.psychology},
    {'name': 'LOVER', 'icon': Icons.favorite},
    {'name': 'REPORTER', 'icon': Icons.feed},
    {'name': 'GANGSTER', 'icon': Icons.groups},
    {'name': 'DETECTIVE', 'icon': Icons.troubleshoot},
    {'name': 'GHOUL', 'icon': Icons.filter_vintage},
    {'name': 'MARTYR', 'icon': Icons.ac_unit},
    {'name': 'PRIEST', 'icon': Icons.church},
    {'name': 'PROPHET', 'icon': Icons.auto_awesome},
    {'name': 'JUDGE', 'icon': Icons.gavel},
    {'name': 'HACKER', 'icon': Icons.terminal},
    {'name': 'MAGICIAN', 'icon': Icons.star_border},
  ];

  Future<void> _executePrediction(GameController controller) async {
    if (_selectedPlayer == null || _selectedRole == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final res = await GameApi.instance.submitVote(
        controller.roomCode!,
        'HITMAN_STRIKE',
        targets: [_selectedPlayer!.userId],
        roles: [_selectedRole!],
      );

      if (!mounted) return;
      if (res != null) {
        // success message from backend
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res, style: const TextStyle(color: Colors.white, fontFamily: 'Inter')),
          backgroundColor: _accentOrange,
        ));
      }
      // Return back after striking
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: const TextStyle(color: Colors.white, fontFamily: 'Inter')),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();

    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield, color: _accentOrange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'NIMBUS MAFIA: ROLE\nANALYSIS',
                        style: TextStyle(
                          color: _accentOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'NIMBUS\nMAFIA',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF222222), thickness: 1, height: 1),

            Expanded(
              child: _selectedPlayer == null
                  ? _buildDiscussionTerminal(controller)
                  : _buildRolePredictionTerminal(controller),
            ),

            // Mock Bottom Nav Bar (Matches App Aesthetic)
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussionTerminal(GameController controller) {
    final validPlayers = controller.players.where((p) => p.isAlive && p.userId != controller.myUserId).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Vertical Orange Line
        Container(
          width: 3,
          margin: const EdgeInsets.only(left: 20, top: 20, bottom: 40),
          decoration: BoxDecoration(
            color: _accentOrange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PLAYERS IN ROOM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'STATUS: ACTIVE DISCUSSION',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _textMuted, width: 1),
                          ),
                          child: Icon(Icons.add, color: _textMuted, size: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${validPlayers.length}/${controller.players.length}',
                          style: TextStyle(
                            color: _accentOrange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Player List
                Expanded(
                  child: ListView.separated(
                    itemCount: validPlayers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = validPlayers[index];
                      // Assign mock statuses to make UI feel dynamic
                      final statusMock = ['CURRENT FOCUS', 'SUSPECT', 'ANALYZING PATTERN...'][index % 3];
                      final iconMock = [Icons.my_location, Icons.radio_button_unchecked, Icons.sync][index % 3];
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPlayer = p;
                            _selectedRole = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _bgCard,
                            border: Border.all(
                              color: const Color(0xFF2C2C2C),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFF3B5BDB),
                                child: Text(
                                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      statusMock,
                                      style: TextStyle(
                                        color: index == 0 ? _accentOrange : _textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                iconMock,
                                color: index == 0 ? _accentOrange : _textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Footer lines
                const Divider(color: Color(0xFF2C2C2C), thickness: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 3, height: 12, color: _accentOrange),
                        const SizedBox(width: 4),
                        Container(width: 2, height: 12, color: _accentOrange.withAlpha(150)),
                        const SizedBox(width: 4),
                        Container(width: 2, height: 12, color: _accentOrange.withAlpha(50)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'GAME ID: ${controller.roomCode ?? 'THETA-9'}',
                          style: TextStyle(color: _textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'ROUND: ${controller.round}',
                          style: TextStyle(color: _textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRolePredictionTerminal(GameController controller) {
    return Column(
      children: [
        // Left Vertical blue-ish line container
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 2,
                margin: const EdgeInsets.only(left: 10, top: 20, bottom: 20),
                color: const Color(0xFF4C4CFF),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _selectedPlayer = null;
                                _selectedRole = null;
                              });
                            },
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'ROLE PREDICTION TERMINAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                            children: [
                              const TextSpan(text: 'ASSIGN IDENTITY TO '),
                              TextSpan(
                                text: _selectedPlayer?.name ?? '',
                                style: TextStyle(color: _accentOrange),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Search bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF141414),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: _accentOrange, size: 16),
                            const SizedBox(width: 12),
                            Text(
                              'FILTER ROLES...',
                              style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Roles Grid
                      Expanded(
                        child: GridView.builder(
                          itemCount: _allRoles.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.1,
                          ),
                          itemBuilder: (context, index) {
                            final role = _allRoles[index];
                            final isSelected = _selectedRole == role['name'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRole = role['name'];
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _bgCard,
                                  border: Border.all(
                                    color: isSelected ? _accentOrange : const Color(0xFF2C2C2C),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    if (isSelected)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          color: _accentOrange,
                                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(role['icon'], color: _accentOrange, size: 28),
                                          const SizedBox(height: 12),
                                          Text(
                                            role['name'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom Footer (Exec)
        if (_selectedRole != null)
          Container(
            padding: const EdgeInsets.all(20),
            color: _bgDark,
            child: Row(
               crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Container(
                  width: 3,
                  height: 100, // Approximate height to match image
                  color: const Color(0xFFF7DE88),
                  margin: const EdgeInsets.only(right: 16),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF222222),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              color: Colors.black,
                              child: Icon(
                                _allRoles.firstWhere((r) => r['name'] == _selectedRole)['icon'],
                                color: _accentOrange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ROLE PREDICTED',
                                  style: TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                    children: [
                                      TextSpan(text: '${_selectedPlayer?.name} IS '),
                                      TextSpan(text: _selectedRole, style: TextStyle(color: _accentOrange)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentOrange,
                              foregroundColor: Colors.black,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _isSubmitting ? null : () => _executePrediction(controller),
                            child: _isSubmitting 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('EXECUTE PREDICTION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                                    SizedBox(width: 12),
                                    Icon(Icons.send, size: 16),
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _bgDark,
        border: const Border(top: BorderSide(color: Color(0xFF2C2C2C))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.assignment, 'GAMES', false),
          _navItem(Icons.remove_red_eye, 'ROLES', false),
          _navItem(Icons.people, 'ROOMS', false),
          _navItem(Icons.monetization_on, 'RANK', false),
          _navItem(Icons.account_circle, 'PROFILE', true),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isSelected) {
    return Container(
      decoration: isSelected
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFFF8566), width: 2)),
              color: Color(0xFF1E130E),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? _accentOrange : _textMuted, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? _accentOrange : _textMuted,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
