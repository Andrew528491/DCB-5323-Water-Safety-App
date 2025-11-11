import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class QuizScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;

  const QuizScreen({super.key, required this.lesson});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _hasAnswered = false;
  
  Map<String, dynamic>? _quizResult;
  
  late AnimationController _buttonAnimController;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _fetchQuizQuestions();
    
    _buttonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _buttonAnimation = CurvedAnimation(
      parent: _buttonAnimController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _buttonAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchQuizQuestions() async {
    try {
      final String? lessonId = widget.lesson['id'] as String?;
      if (lessonId == null) {
        throw Exception("Lesson ID is missing.");
      }

      final snapshot = await _db
          .collection('lessons')
          .doc(lessonId)
          .collection('quiz')
          .get();

      final allQuestions = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'question': data['question'] as String,
          'options': List<String>.from(data['options']),
          'correctIndex': data['correctIndex'] as int,
        };
      }).toList();

      allQuestions.shuffle(math.Random());
      final selectedQuestions = allQuestions.take(5).toList();

      setState(() {
        _questions = selectedQuestions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching quiz: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load quiz questions.')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _answerQuestion(int selectedIndex) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswer = selectedIndex;
      _hasAnswered = true;
      
      if (selectedIndex == _questions[_currentQuestionIndex]['correctIndex']) {
        _score++;
      }
    });
    
    _buttonAnimController.forward();
  }

  void _nextQuestion() {
    _buttonAnimController.reset();
    
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
      });
    } else {
      final int total = _questions.length;
      final double requiredPassPercentage = 0.70;
      final bool passed = total > 0 && (_score / total) >= requiredPassPercentage;

      setState(() {
        _quizResult = {
          'score': _score,
          'total': total,
          'passed': passed,
        };
      });
    }
  }

  void _handleBackButton() {
    Navigator.of(context).pop();
  }

  Color _getOptionColor(int optionIndex) {
    if (!_hasAnswered) {
      return Colors.white;
    }

    final correctIndex = _questions[_currentQuestionIndex]['correctIndex'];
    
    if (optionIndex == correctIndex) {
      return Colors.green.shade50;
    }
    
    if (optionIndex == _selectedAnswer && optionIndex != correctIndex) {
      return Colors.red.shade50;
    }
    
    return Colors.white;
  }

  Color _getOptionBorderColor(int optionIndex) {
    if (!_hasAnswered) {
      return _selectedAnswer == optionIndex 
          ? Theme.of(context).colorScheme.primary
          : Colors.grey.shade300;
    }

    final correctIndex = _questions[_currentQuestionIndex]['correctIndex'];
    
    if (optionIndex == correctIndex) {
      return Colors.green.shade600;
    }
    
    if (optionIndex == _selectedAnswer && optionIndex != correctIndex) {
      return Colors.red.shade600;
    }
    
    return Colors.grey.shade300;
  }

  Widget? _getOptionIcon(int optionIndex) {
    if (!_hasAnswered) return null;

    final correctIndex = _questions[_currentQuestionIndex]['correctIndex'];
    
    if (optionIndex == correctIndex) {
      return Icon(Icons.check_circle, color: Colors.green.shade600, size: 28);
    }
    
    if (optionIndex == _selectedAnswer && optionIndex != correctIndex) {
      return Icon(Icons.cancel, color: Colors.red.shade600, size: 28);
    }
    
    return null;
  }

  Widget _buildQuestionScreen() {
    final question = _questions[_currentQuestionIndex];
    const Color shallowWater = Color(0xFF81D4FA);
    const Color deepWater = Color(0xFF0D47A1);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shallowWater, deepWater],
          stops: [0.0, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header with back button and progress
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    onPressed: _handleBackButton,
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    tooltip: 'Back to Lessons',
                  ),
                  const SizedBox(width: 8),
                  // Question progress
                  Text(
                    '${_currentQuestionIndex + 1}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Text(
                    ' / ${_questions.length}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  // Score badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade300, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '$_score',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  children: [
                    // Question card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        question['question'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                          color: Color(0xFF1A1A1A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Options
                    ...List.generate(question['options'].length, (optIndex) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _getOptionColor(optIndex),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getOptionBorderColor(optIndex),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _hasAnswered ? null : () => _answerQuestion(optIndex),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _selectedAnswer == optIndex
                                          ? _getOptionBorderColor(optIndex)
                                          : Colors.grey.shade200,
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + optIndex),
                                        style: TextStyle(
                                          color: _selectedAnswer == optIndex
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      question['options'][optIndex],
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  if (_getOptionIcon(optIndex) != null) ...[
                                    const SizedBox(width: 12),
                                    _getOptionIcon(optIndex)!,
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Next button with smooth animation
                    if (_hasAnswered)
                      ScaleTransition(
                        scale: _buttonAnimation,
                        child: Container(
                          margin: const EdgeInsets.only(top: 24),
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _nextQuestion,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentQuestionIndex < _questions.length - 1
                                      ? 'Next Question'
                                      : 'See Results',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentQuestionIndex < _questions.length - 1
                                      ? Icons.arrow_forward
                                      : Icons.emoji_events,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen(Map<String, dynamic> result) {
    final theme = Theme.of(context);
    final int score = result['score'];
    final int total = result['total'];
    final bool passed = result['passed'];
    final int percentage = (total > 0 ? (score / total) * 100 : 0).round();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: passed 
              ? [const Color(0xFF81D4FA), const Color(0xFF4CAF50)]
              : [const Color(0xFF81D4FA), const Color(0xFFE57373)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Trophy or retry icon
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Icon(
                    passed ? Icons.emoji_events : Icons.refresh,
                    size: 120,
                    color: passed ? Colors.amber.shade600 : theme.colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Result card
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        passed ? 'Amazing!' : 'Keep Going!',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: passed ? Colors.green.shade700 : theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        passed 
                            ? 'You passed the quiz!' 
                            : 'You need 70% to pass',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Score display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$percentage',
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: passed ? Colors.green.shade600 : Colors.red.shade600,
                              height: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '%',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: passed ? Colors.green.shade600 : Colors.red.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        '$score out of $total correct',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Return button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(result);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Back to Lessons',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF81D4FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz, size: 80, color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(height: 20),
                      Text(
                        'No quiz questions available',
                        style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                )
              : _quizResult != null
                  ? _buildResultsScreen(_quizResult!)
                  : _buildQuestionScreen(),
    );
  }
}