import 'package:coc/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultPage extends StatelessWidget {
  final bool isCorrect;
  final Map<String, dynamic> userData;
  final String gameType;
  final double score;
  final VoidCallback? onContinue;

  const ResultPage({
    super.key,
    required this.isCorrect,
    required this.userData,
    required this.gameType,
    required this.score,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: GridBackgroundPainter(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  size: 100,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  isCorrect ? 'Jawaban Benar!' : 'Jawaban Salah',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Skor: $score',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),

                // Tombol Kembali ke Beranda
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFF4FC3F7)),
                    ),
                    child: Text(
                      'Kembali ke Login',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4FC3F7),
                      ),
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
