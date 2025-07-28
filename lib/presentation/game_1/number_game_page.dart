import 'package:coc/core/supabase_config.dart';
import 'package:coc/presentation/game_1/result_page.dart';
import 'package:coc/presentation/home_page.dart';
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
  String _question = '';
  int _correctAnswer = 0;
  int _questionId = 0;

  @override
  void initState() {
    super.initState();
    _fetchQuestion();
  }

  Future<void> _fetchQuestion() async {
    try {
      final response = await SupabaseConfig.client
          .from('number_game_questions')
          .select()
          .order('random()')
          .limit(1)
          .single();

      setState(() {
        _question = response['question'] ?? 'Pilih angka dari 1-10';
        _correctAnswer = response['correct_answer'] ?? 7;
        _questionId = response['id']; // Jangan beri nilai default 0
        _isLoading = false;
      });
    } catch (e) {
      // Fallback jika database error
      setState(() {
        _question = 'Pilih angka dari 1-10';
        _correctAnswer = 7;
        _questionId = -1; // Gunakan nilai khusus untuk menandai error
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (selectedNumber == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final isCorrect = selectedNumber == _correctAnswer;

      // Siapkan data untuk disimpan
      final data = {
        'user_id': widget.userData['user_id'],
        'game_type': 'number_game',
        'user_answer': selectedNumber,
        'is_correct': isCorrect,
      };

      // Hanya tambahkan question_id jika valid (bukan -1 dan tidak null)
      if (_questionId != -1) {
        data['question_id'] = _questionId;
      }

      await SupabaseConfig.client.from('game_results').insert(data);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            isCorrect: isCorrect,
            userData: widget.userData,
            gameType: 'number_game',
            score: isCorrect ? 1.0 : 0.0,
          ),
        ),
      );
    } catch (e) {
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Game Pilihan Angka',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4FC3F7),
        centerTitle: true,
      ),
      body: CustomPaint(
        painter: GridBackgroundPainter(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _question,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    final number = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => selectedNumber = number),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedNumber == number
                              ? const Color(0xFF4FC3F7)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF4FC3F7),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            number.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: selectedNumber == number
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedNumber == null || _isSubmitting
                        ? null
                        : _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC3F7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'OK',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
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
