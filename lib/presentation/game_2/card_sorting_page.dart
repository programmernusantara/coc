import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:coc/core/supabase_config.dart';
import 'package:coc/presentation/game_2/result_page.dart';

class CardSortingGamePage extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;

  const CardSortingGamePage({super.key, required this.userData});

  @override
  ConsumerState<CardSortingGamePage> createState() =>
      _CardSortingGamePageState();
}

class _CardSortingGamePageState extends ConsumerState<CardSortingGamePage> {
  List<String> _cards = [];
  List<int> _currentOrder = [];
  List<int> _correctOrder = [];
  String _question = '';
  String _category = '';
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _timeLeft = 60;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _fetchQuestion();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _submitAnswer();
        timer.cancel();
      }
    });
  }

  Future<void> _fetchQuestion() async {
    try {
      final response = await SupabaseConfig.client
          .from('card_sorting_questions')
          .select()
          .order('random()')
          .limit(1)
          .single();

      setState(() {
        _question = response['question'] ?? 'Urutkan kartu berikut';
        _cards = List<String>.from(response['cards'] ?? []);
        _correctOrder = List<int>.from(response['correct_order'] ?? []);
        _category = response['category'] ?? 'Umum';
        _currentOrder = List.generate(_cards.length, (index) => index)
          ..shuffle();
        _isLoading = false;
        _timeLeft = 60;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat soal: ${e.toString()}')),
        );
      });
    }
  }

  void _reorderCards(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _currentOrder.removeAt(oldIndex);
      _currentOrder.insert(newIndex, item);
    });
  }

  Future<void> _submitAnswer() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      bool isCorrect = true;
      for (int i = 0; i < _currentOrder.length; i++) {
        if (_currentOrder[i] != _correctOrder[i]) {
          isCorrect = false;
          break;
        }
      }

      await SupabaseConfig.client.from('game_results').insert({
        'user_id': widget.userData['user_id'],
        'game_type': 'card_sorting',
        'question': _question,
        'user_answer': _currentOrder.toString(),
        'correct_answer': _correctOrder.toString(),
        'is_correct': isCorrect,
        'time_spent': 60 - _timeLeft,
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardSortingResultPage(
            isCorrect: isCorrect,
            userData: widget.userData,
            question: _question,
            userOrder: _currentOrder,
            correctOrder: _correctOrder,
            cards: _cards,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text('Memuat soal...', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Urutkan Kartu', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchQuestion,
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _timeLeft / 60,
            backgroundColor: Colors.grey[200],
            color: Colors.blue,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(_category, style: GoogleFonts.poppins()),
                  backgroundColor: Colors.blue[100],
                ),
                Text(
                  'Waktu: $_timeLeft detik',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: _timeLeft < 10 ? Colors.red : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _question,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cards.length,
                    itemBuilder: (context, index) {
                      final cardIndex = _currentOrder[index];
                      return _buildSortableCard(
                        key: Key('$index'),
                        index: index,
                        content: _cards[cardIndex],
                      );
                    },
                    onReorder: _reorderCards,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'SIMPAN JAWABAN',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortableCard({
    required Key key,
    required int index,
    required String content,
  }) {
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue,
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
            const SizedBox(width: 16),
            Expanded(
              child: Text(content, style: GoogleFonts.poppins(fontSize: 16)),
            ),
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
