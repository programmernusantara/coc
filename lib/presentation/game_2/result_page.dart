import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:coc/presentation/login_page.dart';

class CardSortingResultPage extends StatelessWidget {
  final bool isCorrect;
  final Map<String, dynamic> userData;
  final String question;
  final List<int> userOrder;
  final List<int> correctOrder;
  final List<String> cards;

  const CardSortingResultPage({
    super.key,
    required this.isCorrect,
    required this.userData,
    required this.question,
    required this.userOrder,
    required this.correctOrder,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hasil', style: GoogleFonts.poppins())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    size: 80,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCorrect ? 'BENAR!' : 'SALAH',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pertanyaan:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(question, style: GoogleFonts.poppins(fontSize: 16)),
            const SizedBox(height: 16),
            _buildComparisonSection(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'KEMBALI KE LOGIN',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perbandingan Jawaban:',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        ...List.generate(cards.length, (index) {
          final userCardIndex = userOrder[index];
          final correctCardIndex = correctOrder[index];
          final isItemCorrect = userCardIndex == correctCardIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isItemCorrect ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cards[userCardIndex],
                    style: GoogleFonts.poppins(
                      color: isItemCorrect ? Colors.green : Colors.red,
                      decoration: isItemCorrect
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                ),
                if (!isItemCorrect) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cards[correctCardIndex],
                      style: GoogleFonts.poppins(color: Colors.green),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
