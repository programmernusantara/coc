import 'package:coc/presentation/leaderboard_page.dart';
import 'package:coc/presentation/game_1/number_game_page.dart';
import 'package:coc/presentation/game_2/word_arrangement_page.dart';
import 'package:coc/presentation/game_3/translation_game_page.dart';
import 'package:coc/presentation/game_4/chest_unlock_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Class of Bakid',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4FC3F7),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LeaderboardPage(userData: widget.userData),
                ),
              );
            },
            tooltip: 'Lihat Leaderboard',
          ),
        ],
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
                          text: 'Kls ${widget.userData['kelas']}',
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          icon: Icons.home_work,
                          text: 'Asr ${widget.userData['asrama']}',
                        ),
                      ],
                    ),
                  ],
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
          title: 'Game 1',
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
          title: 'Game 2',
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
          title: 'Game 3',
          icon: Icons.translate,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TranslationPuzzlePage(userData: widget.userData),
              ),
            );
          },
        ),
        _buildGameCard(
          title: 'Game 4',
          icon: Icons.lock_open,
          color: Colors.amber,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChestUnlockPage(userData: widget.userData),
              ),
            );
          },
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
