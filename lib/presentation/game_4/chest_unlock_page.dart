import 'package:coc/core/supabase_config.dart';
import 'package:coc/presentation/result_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChestUnlockPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ChestUnlockPage({super.key, required this.userData});

  @override
  State<ChestUnlockPage> createState() => _ChestUnlockPageState();
}

class _ChestUnlockPageState extends State<ChestUnlockPage> {
  final List<TextEditingController> _codeControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  int? _currentQuestionId;
  String? _questionText;
  bool _isLoading = true;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
    _setupFocusNodes();
  }

  void _setupFocusNodes() {
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && i < _focusNodes.length - 1) {
          FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
        }
      });
    }
  }

  Future<void> _loadQuestion() async {
    try {
      final response = await SupabaseConfig.client
          .from('chest_unlock_questions')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _currentQuestionId = response['id'];
          _questionText = response['question_text'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat pertanyaan')),
        );
      }
    }
  }

  Future<void> _submitAnswer() async {
    if (_currentQuestionId == null) return;

    final enteredCode = _codeControllers.map((c) => c.text).join();
    if (enteredCode.length != 4) {
      setState(() => _showError = true);
      return;
    }

    try {
      // Get correct answer
      final response = await SupabaseConfig.client
          .from('chest_unlock_questions')
          .select('correct_code')
          .eq('id', _currentQuestionId!)
          .single();

      final isCorrect = enteredCode == response['correct_code'];
      final score = isCorrect ? 10 : 0;

      // Save result
      await SupabaseConfig.client.from('game_results').insert({
        'user_id': widget.userData['user_id'],
        'game_type': 'password_unlock',
        'user_answer': enteredCode,
        'is_correct': isCorrect,
        'score': score,
        'chest_question_id': _currentQuestionId,
      });

      // Navigate to result page
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultPage(
              isCorrect: isCorrect,
              userData: widget.userData,
              gameType: 'Password Unlock',
              score: score.toDouble(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Game 4',
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
        painter: _GridBackgroundPainter(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Icon(
                  Icons.lock_outlined,
                  size: 80,
                  color: const Color(0xFF4FC3F7),
                ),
                const SizedBox(height: 25),

                // Question Text from Database
                if (_questionText != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _questionText!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 40),

                // Password Input Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      return SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _codeControllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4FC3F7),
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _showError
                                    ? Colors.red
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFF4FC3F7),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => _showError = false);
                            if (value.length == 1 && index < 3) {
                              FocusScope.of(
                                context,
                              ).requestFocus(_focusNodes[index + 1]);
                            } else if (value.isEmpty && index > 0) {
                              FocusScope.of(
                                context,
                              ).requestFocus(_focusNodes[index - 1]);
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),

                if (_showError)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Harap isi semua digit',
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC3F7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'VERIFIKASI',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

class _GridBackgroundPainter extends CustomPainter {
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
