import 'package:coc/core/supabase_config.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const LeaderboardPage({super.key, required this.userData});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
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
          .limit(10); // Tampilkan 10 pemain teratas

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
          'TOP PEMAIN',
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Informasi User Saat Ini
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userData['nama'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Kelas ${widget.userData['kelas']} - ${widget.userData['asrama']}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Leaderboard Content
              Expanded(child: _buildLeaderboardContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    if (_isLoadingLeaderboard) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_leaderboardData.isEmpty) {
      return Center(
        child: Text(
          'Belum ada data leaderboard',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Table
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    'RANK',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'NAMA PEMAIN',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'POIN',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
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
            final isCurrentUser =
                player['user_id'] == widget.userData['user_id'];

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              color: isCurrentUser ? Colors.blue[50] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    // Rank with medal icon for top 3
                    SizedBox(
                      width: 40,
                      child: Row(
                        children: [
                          if (index < 3)
                            Icon(
                              index == 0
                                  ? Icons.emoji_events
                                  : index == 1
                                  ? Icons.workspace_premium
                                  : Icons.military_tech,
                              color: _getRankColor(index + 1),
                              size: 20,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            '${index + 1}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: _getRankColor(index + 1),
                            ),
                          ),
                        ],
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
                      width: 60,
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
      ),
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
