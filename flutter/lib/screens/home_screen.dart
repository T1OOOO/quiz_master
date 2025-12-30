import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  List<dynamic> _quizzes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  void _loadQuizzes() async {
    try {
      final quizzes = await _api.getQuizzes();
      setState(() {
        _quizzes = quizzes;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Quiz Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => Navigator.pushNamed(context, '/multiplayer'),
          ),
        ],
        backgroundColor: Colors.grey[850],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _quizzes.length,
              itemBuilder: (context, index) {
                final quiz = _quizzes[index];
                return Card(
                  color: Colors.grey[800],
                  margin: EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    title: Text(quiz['title'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(quiz['description'] ?? '', style: TextStyle(color: Colors.grey[400])),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QuizScreen(quizId: quiz['id'])),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
