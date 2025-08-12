import 'package:coc/core/supabase_config.dart';
import 'package:coc/presentation/login_page.dart';
import 'package:coc/presentation/result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class NumberGamePage extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;

  const NumberGamePage({super.key, required this.userData});

  @override
  ConsumerState<NumberGamePage> createState() => _NumberGamePageState();
}

class _NumberGamePageState extends ConsumerState<NumberGamePage> {
  int? selectedNumber;
  bool _isSubmitting = false;
  bool _isLoading = true;
  String _question = 'Memuat pertanyaan...';
  int _correctAnswer = 0;
  int _questionId = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchQuestion();
  }

  Future<void> _fetchQuestion() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await SupabaseConfig.client
          .from('number_game_questions')
          .select()
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle();

      debugPrint('Response dari Supabase: $response');

      if (response == null || response.isEmpty) {
        throw Exception('Tidak ada pertanyaan tersedia');
      }

      setState(() {
        _question = response['question'] ?? 'Pertanyaan tidak tersedia';
        _correctAnswer = (response['correct_answer'] as num?)?.toInt() ?? 0;
        _questionId = (response['id'] as num?)?.toInt() ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error saat mengambil pertanyaan: $e');
      setState(() {
        _errorMessage = 'Gagal memuat pertanyaan. Silakan coba lagi.';
        _isLoading = false;
        _question = 'Tidak dapat memuat pertanyaan';
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _submitAnswer() async {
    if (selectedNumber == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final isCorrect = selectedNumber == _correctAnswer;

      final insertResponse =
          await SupabaseConfig.client.from('game_results').insert({
            'user_id': widget.userData['user_id'],
            'game_type': 'number_game',
            'number_question_id': _questionId,
            'user_answer': selectedNumber.toString(),
            'is_correct': isCorrect,
            'score': isCorrect ? 10 : 0,
          }).select();

      debugPrint('Insert response: $insertResponse');

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            isCorrect: isCorrect,
            userData: widget.userData,
            gameType: 'number_game',
            score: isCorrect ? 10.0 : 0.0,
            onContinue: () {
              Navigator.pop(context);
              _fetchQuestion();
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error menyimpan jawaban: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Game 1',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4FC3F7),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildGameContent(),
    );
  }

  Widget _buildGameContent() {
    return CustomPaint(
      painter: GridBackgroundPainter(),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage,
                    style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
                  ),
                ),

              // Pertanyaan dari database
              Text(
                _question,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Grid angka 1-10
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: 10,
                itemBuilder: (context, index) {
                  final number = index + 1;
                  return _buildNumberButton(number);
                },
              ),
              const SizedBox(height: 24),

              // Tombol submit - DIUBAH DISINI (tanpa loading indicator)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedNumber == null || _isSubmitting
                      ? null
                      : _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedNumber == null || _isSubmitting
                        ? Colors.grey[300]
                        : const Color(0xFF4FC3F7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Periksa Jawaban',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: selectedNumber == null || _isSubmitting
                          ? Colors.grey[600]
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    final isSelected = selectedNumber == number;

    return GestureDetector(
      onTap: () => setState(() => selectedNumber = number),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4FC3F7) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF4FC3F7), width: 2),
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
