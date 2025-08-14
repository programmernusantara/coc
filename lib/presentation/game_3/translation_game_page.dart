import 'package:coc/core/supabase_config.dart';
import 'package:coc/presentation/result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class TranslationPuzzlePage extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;

  const TranslationPuzzlePage({super.key, required this.userData});

  @override
  ConsumerState<TranslationPuzzlePage> createState() =>
      _TranslationPuzzlePageState();
}

class _TranslationPuzzlePageState extends ConsumerState<TranslationPuzzlePage> {
  List<String> _words = [];
  List<String> _selectedWords = [];
  bool _isLoading = true;
  String _question = '';
  List<String> _correctAnswer = [];
  int _questionId = 0;

  @override
  void initState() {
    super.initState();
    _fetchQuestion();
  }

  Future<void> _fetchQuestion() async {
    try {
      setState(() {
        _isLoading = true;
        _selectedWords = [];
      });

      final response = await SupabaseConfig.client
          .from('translation_questions')
          .select()
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null || response.isEmpty) {
        throw Exception('Tidak ada pertanyaan tersedia');
      }

      final correctAnswer = (response['arabic_text'] as String)
          .split(' ')
          .where((word) => word.isNotEmpty)
          .toList();

      final hintWords = List<String>.from(response['hint_words'] ?? []);

      setState(() {
        _question = response['indonesia_text'] ?? 'Pertanyaan tidak tersedia';
        _correctAnswer = correctAnswer;
        _words = List.from(hintWords)..shuffle();
        _questionId = response['id'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _question = 'Tidak dapat memuat pertanyaan';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pertanyaan: ${e.toString()}')),
        );
      }
    }
  }

  void _onWordSelected(String word) {
    setState(() {
      _selectedWords.add(word);
      _words.remove(word);
    });
  }

  void _onWordDeselected(String word) {
    setState(() {
      _words.add(word);
      _selectedWords.remove(word);
      _words.shuffle();
    });
  }

  Future<void> _submitAnswer() async {
    try {
      final userAnswer = _selectedWords
          .join(' ')
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ');
      final correctAnswer = _correctAnswer
          .join(' ')
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ');

      final isCorrect = userAnswer == correctAnswer;

      await SupabaseConfig.client.from('game_results').insert({
        'user_id': widget.userData['user_id'],
        'game_type': 'translation_puzzle',
        'translation_question_id': _questionId,
        'user_answer': userAnswer,
        'is_correct': isCorrect,
        'score': isCorrect ? 10 : 0,
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            isCorrect: isCorrect,
            userData: widget.userData,
            gameType: 'Terjemahan Arab',
            score: isCorrect ? 10.0 : 0.0,
            onContinue: () {
              Navigator.pop(context);
              _fetchQuestion();
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Game 3',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4FC3F7),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : CustomPaint(
              painter: _GridBackgroundPainter(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop
                      ? 60
                      : isTablet
                      ? 40
                      : 16,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    // Question Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            _question,
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 22 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Answer Area - Minimalist Version without Box
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Jawaban Anda:',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 16 : 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: _selectedWords.isEmpty
                              ? Text(
                                  'Pilih kata-kata di bawah untuk menyusun jawaban',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[500],
                                    fontSize: isTablet ? 16 : 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.start,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: _selectedWords
                                      .map(
                                        (word) => InputChip(
                                          label: Text(
                                            word,
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 16 : 14,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFF4FC3F7,
                                          ),
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          deleteIcon: const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          onDeleted: () =>
                                              _onWordDeselected(word),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Word Selection Grid
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isDesktop
                                    ? 4
                                    : isTablet
                                    ? 3
                                    : 2,
                                childAspectRatio: isDesktop
                                    ? 2.5
                                    : isTablet
                                    ? 2
                                    : 1.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: _words.length,
                          itemBuilder: (context, index) => Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _onWordSelected(_words[index]),
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                                  child: Text(
                                    _words[index],
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 18 : 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: isDesktop
                          ? 400
                          : isTablet
                          ? 300
                          : double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedWords.isEmpty
                            ? null
                            : _submitAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FC3F7),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'PERIKSA JAWABAN',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
