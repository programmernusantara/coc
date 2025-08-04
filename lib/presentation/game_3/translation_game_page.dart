import 'package:coc/core/supabase_config.dart';
import 'package:coc/presentation/game_2/word_arrangement_page.dart';
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
        'question_id': _questionId,
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
            gameType: 'translation_puzzle',
            score: isCorrect ? 15.0 : 0.0,
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
    return Scaffold(
      appBar: AppBar(
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              _question,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Area Jawaban (RTL)
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Container(
                          height: 80,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4FC3F7),
                              width: 2,
                            ),
                          ),
                          child: _selectedWords.isEmpty
                              ? Center(
                                  child: Text(
                                    'Susun jawaban di sini',
                                    style: GoogleFonts.poppins(
                                      color: Color.fromRGBO(
                                        158,
                                        158,
                                        158,
                                        1,
                                      ), // Grey 500
                                    ),
                                  ),
                                )
                              : Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _selectedWords
                                      .map(
                                        (word) => Chip(
                                          label: Text(
                                            word,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFF4FC3F7,
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
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Kata-kata Pilihan (RTL)
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 1.5,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: _words.length,
                            itemBuilder: (context, index) => Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _onWordSelected(_words[index]),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color.fromRGBO(
                                          128,
                                          128,
                                          128,
                                          0.1,
                                        ),
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
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Submit
                      SizedBox(
                        width: double.infinity,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
