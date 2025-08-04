import 'package:coc/core/supabase_config.dart';
import 'package:coc/presentation/result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class WordArrangementPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;

  const WordArrangementPage({super.key, required this.userData});

  @override
  ConsumerState<WordArrangementPage> createState() =>
      _WordArrangementPageState();
}

class _WordArrangementPageState extends ConsumerState<WordArrangementPage> {
  List<String> _words = [];
  bool _isLoading = true;
  String _question = '';
  List<String> _correctOrder = [];
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
      });

      final response = await SupabaseConfig.client
          .from('word_arrangement_questions')
          .select()
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null || response.isEmpty) {
        throw Exception('Tidak ada pertanyaan tersedia');
      }

      final correctOrder = List<String>.from(response['correct_order'] ?? []);
      final shuffledWords = List<String>.from(correctOrder)..shuffle();

      setState(() {
        _question = response['question'] ?? 'Susun kata berikut:';
        _correctOrder = correctOrder;
        _words = shuffledWords;
        _questionId = response['id'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
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
    try {
      final isCorrect = _listEquals(_words, _correctOrder);

      await SupabaseConfig.client.from('game_results').insert({
        'user_id': widget.userData['user_id'],
        'game_type': 'word_arrangement',
        'question_id': _questionId,
        'user_answer': _words.join(','),
        'is_correct': isCorrect,
        'score': isCorrect ? 20 : 0,
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            isCorrect: isCorrect,
            userData: widget.userData,
            gameType: 'word_arrangement',
            score: isCorrect ? 20.0 : 0.0,
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

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Game 2',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4FC3F7),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchQuestion,
            tooltip: 'Muat ulang pertanyaan',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Grid Background
                CustomPaint(
                  painter: GridBackgroundPainter(),
                  size: Size.infinite,
                ),

                // Konten Game
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Pertanyaan
                      Text(
                        _question,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ReorderableListView(
                              padding: const EdgeInsets.only(
                                bottom: 16,
                                top: 8,
                              ),
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) newIndex--;
                                  final String item = _words.removeAt(oldIndex);
                                  _words.insert(newIndex, item);
                                });
                              },
                              children: _words
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Container(
                                      key: ValueKey(entry.value),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withAlpha(10),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                        title: Text(
                                          entry.value,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        trailing: const Icon(
                                          Icons.drag_handle,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),

                      // Tombol Jawab
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4FC3F7),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Ok',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
