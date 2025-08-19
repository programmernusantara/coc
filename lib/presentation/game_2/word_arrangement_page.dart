import 'package:coc/core/supabase_config.dart';
import 'package:coc/presentation/home_page.dart';
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
  bool _isSubmitting = false;
  String _question = '';
  List<String> _correctOrder = [];
  int _questionId = 0;
  List<int> _selectedIndices = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestion();
  }

  Future<void> _fetchQuestion() async {
    try {
      setState(() {
        _isLoading = true;
        _selectedIndices = [];
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
    if (_isSubmitting || _selectedIndices.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final userOrder = _selectedIndices.map((index) => _words[index]).toList();
      final isCorrect = _listEquals(userOrder, _correctOrder);

      await SupabaseConfig.client.from('game_results').insert({
        'user_id': widget.userData['user_id'],
        'game_type': 'word_arrangement',
        'word_question_id': _questionId,
        'user_answer': userOrder.join(','),
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
            gameType: 'word_arrangement',
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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

  void _selectWord(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Widget _buildDominoCard(String word, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectWord(index),
      child: Container(
        width: 80,
        height: 120,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4FC3F7) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF4FC3F7) : Colors.grey[400]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Text(
                  '${_selectedIndices.indexOf(index) + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  word,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomPaint(
                  painter: GridBackgroundPainter(),
                  size: Size.infinite,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Pertanyaan
                      Container(
                        padding: const EdgeInsets.all(12),

                        child: Text(
                          _question,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Kartu Domino
                      Expanded(
                        child: Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            runSpacing: 4,
                            children: List.generate(_words.length, (index) {
                              return _buildDominoCard(
                                _words[index],
                                index,
                                _selectedIndices.contains(index),
                              );
                            }),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tombol Submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedIndices.isEmpty || _isSubmitting
                              ? null
                              : _submitAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _selectedIndices.isEmpty || _isSubmitting
                                ? Colors.grey[300]
                                : const Color(0xFF4FC3F7),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'PERIKSA JAWABAN',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _selectedIndices.isEmpty || _isSubmitting
                                  ? Colors.grey[600]
                                  : Colors.white,
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
