import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;

  const QuizScreen({Key? key, required this.quizId}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _quizData;
  int _currentIdx = 0;
  bool _loading = true;
  bool _showingFeedback = false;
  bool _lastCorrect = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  void _loadQuiz() async {
    try {
      final data = await _api.getQuiz(widget.quizId);
      setState(() {
        _quizData = data;
        _loading = false;
      });
    } catch (e) {
      Navigator.pop(context);
    }
  }

  void _handleAnswer(int idx) async {
    if (_showingFeedback) return;

    final questions = _quizData!['questions'] as List;
    final qId = questions[_currentIdx]['id'];

    try {
      final result = await _api.checkAnswer(widget.quizId, qId, idx);
      
      setState(() {
        _showingFeedback = true;
        _lastCorrect = result['correct'];
        if (_lastCorrect) _score++;
      });

      // Auto advance
      Future.delayed(Duration(seconds: 1), () {
        if (!mounted) return;
        if (_currentIdx < questions.length - 1) {
          setState(() {
            _currentIdx++;
            _showingFeedback = false;
          });
        } else {
          _showResults();
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: Text("Quiz Finished", style: TextStyle(color: Colors.white)),
        content: Text("Score: $_score / ${(_quizData!['questions'] as List).length}", style: TextStyle(color: Colors.white, fontSize: 24)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to home
            },
            child: Text("Home"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(backgroundColor: Colors.grey[900], body: Center(child: CircularProgressIndicator()));

    final questions = _quizData!['questions'] as List;
    final question = questions[_currentIdx];

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("Question ${_currentIdx + 1}/${questions.length}"),
        backgroundColor: Colors.grey[850],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
                border: _showingFeedback 
                  ? Border.all(color: _lastCorrect ? Colors.green : Colors.red, width: 2)
                  : null,
              ),
              child: Text(
                question['text'],
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.normal),
                textAlign: TextAlign.center,
              ),
            ).animate(target: _showingFeedback ? 1 : 0).shake(curve: Curves.easeInOutCubic),
            
            SizedBox(height: 32),
            
            Expanded(
              child: ListView.separated(
                itemCount: (question['options'] as List).length,
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  return SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => _handleAnswer(idx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          question['options'][idx], 
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
