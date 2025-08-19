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
      final userAnswer = _selectedWords.join(' ').trim();
      final correctAnswer = _correctAnswer.join(' ').trim();

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
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Game 3',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 40 : 16,
                vertical: 16,
              ),
              child: Column(
                children: [
                  // Question Section
                  Text(
                    _question,
                    style: GoogleFonts.poppins(
                      fontSize: isWideScreen ? 18 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Answer Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Susun Jawaban:',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedWords.isEmpty
                              ? [
                                  Text(
                                    'Pilih kata-kata di bawah',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ]
                              : _selectedWords
                                    .map(
                                      (word) => Chip(
                                        label: Text(word),
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
                                      ),
                                    )
                                    .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Word Selection Grid
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWideScreen ? 3 : 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _words.length,
                      itemBuilder: (context, index) => InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _onWordSelected(_words[index]),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromRGBO(
                                  0,
                                  0,
                                  0,
                                  0.1,
                                ), // Fixed deprecated withOpacity
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _words[index],
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: isWideScreen ? 300 : double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedWords.isEmpty ? null : _submitAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Periksa Jawaban',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
