import 'package:coc/core/supabase_config.dart';
import 'package:coc/presentation/game_1/number_game_page.dart';
import 'package:coc/presentation/game_2/word_arrangement_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoadingLeaderboard = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final response = await SupabaseConfig.client
          .rpc('get_leaderboard')
          .select()
          .order('total_score', ascending: false)
          .limit(5);

      setState(() {
        _leaderboardData = List<Map<String, dynamic>>.from(response);
        _isLoadingLeaderboard = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLeaderboard = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat leaderboard')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Class of Champions',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4FC3F7),
        centerTitle: true,
        elevation: 0,
      ),
      body: CustomPaint(
        painter: GridBackgroundPainter(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      widget.userData['nama'],
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.school,
                          text: 'Kelas ${widget.userData['kelas']}',
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          icon: Icons.home_work,
                          text: 'Asrama ${widget.userData['asrama']}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Leaderboard Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOP PEMAIN',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              iconSize: 20,
                              onPressed: _fetchLeaderboard,
                              tooltip: 'Refresh',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildLeaderboardContent(),
                      ],
                    ),
                  ),
                ),
              ),

              // Games Section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  'PILIHAN GAME',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              _buildGameGrid(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.blue),
      label: Text(text, style: GoogleFonts.poppins(fontSize: 12)),
      backgroundColor: Colors.blue.withAlpha(30),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildLeaderboardContent() {
    if (_isLoadingLeaderboard) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_leaderboardData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Belum ada data leaderboard',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header Table
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: const Row(
            children: [
              SizedBox(
                width: 32,
                child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Text(
                  'Nama',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'Poin',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Leaderboard Items
        ..._leaderboardData.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;
          final isCurrentUser = player['user_id'] == widget.userData['user_id'];

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue[50] : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: _getRankColor(index + 1),
                      ),
                    ),
                  ),
                  // Name and Asrama
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player['nama'],
                          style: GoogleFonts.poppins(
                            fontWeight: isCurrentUser
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          player['asrama'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Score
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${player['total_score']}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[800]!;
      case 2:
        return Colors.grey[600]!;
      case 3:
        return Colors.brown[600]!;
      default:
        return Colors.grey;
    }
  }

  Widget _buildGameGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildGameCard(
          title: 'Game Angka',
          icon: Icons.numbers,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NumberGamePage(userData: widget.userData),
              ),
            );
          },
        ),
        _buildGameCard(
          title: 'Susun Kata',
          icon: Icons.text_fields,
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    WordArrangementPage(userData: widget.userData),
              ),
            );
          },
        ),
        _buildGameCard(
          title: 'Game Logika',
          icon: Icons.psychology,
          color: Colors.orange,
          onTap: () {},
        ),
        _buildGameCard(
          title: 'Game Kata',
          icon: Icons.text_fields,
          color: Colors.purple,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha(50)
      ..strokeWidth = 1;

    const gridSize = 40.0;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
