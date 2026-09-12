import 'dart:async';

import 'package:flutter/material.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

enum QuestionType { trueFalse, singleChoice, multipleChoice, fillInBlank }

class Quiz {
  final String id;
  final String title;
  final String? description;
  final int timeLimitMinutes;
  final double passingGrade;
  final int maxAttempts;
  final List<QuizQuestion> questions;

  const Quiz({
    required this.id,
    required this.title,
    this.description,
    this.timeLimitMinutes = 0,
    this.passingGrade = 70.0,
    this.maxAttempts = 1,
    this.questions = const [],
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      timeLimitMinutes: json['timeLimitMinutes'] as int? ?? 0,
      passingGrade: (json['passingGrade'] as num?)?.toDouble() ?? 70.0,
      maxAttempts: json['maxAttempts'] as int? ?? 1,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class QuizQuestion {
  final String id;
  final String text;
  final QuestionType type;
  final List<QuizOption> options;
  final String? correctAnswer;
  final List<String>? correctAnswers;
  final String? explanation;

  const QuizQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options = const [],
    this.correctAnswer,
    this.correctAnswers,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      text: json['text'] as String,
      type: QuestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QuestionType.singleChoice,
      ),
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => QuizOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      correctAnswer: json['correctAnswer'] as String?,
      correctAnswers: (json['correctAnswers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      explanation: json['explanation'] as String?,
    );
  }
}

class QuizOption {
  final String id;
  final String text;

  const QuizOption({required this.id, required this.text});

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'] as String,
      text: json['text'] as String,
    );
  }
}

class QuizResult {
  final int totalQuestions;
  final int correctAnswers;
  final double score;
  final bool passed;
  final List<QuestionResult> questionResults;

  const QuizResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.passed,
    required this.questionResults,
  });
}

class QuestionResult {
  final QuizQuestion question;
  final dynamic userAnswer;
  final bool isCorrect;

  const QuestionResult({
    required this.question,
    this.userAnswer,
    required this.isCorrect,
  });
}

// ─── Quiz Provider ───────────────────────────────────────────────────────────

class QuizProvider extends ChangeNotifier {
  Quiz? _quiz;
  int _currentQuestionIndex = 0;
  Map<int, dynamic> _answers = {};
  int _attemptsRemaining = 1;
  Timer? _timer;
  int _timeRemainingSeconds = 0;
  bool _isQuizStarted = false;
  bool _isQuizFinished = false;
  bool _isLoading = false;
  String? _error;

  Quiz? get quiz => _quiz;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, dynamic> get answers => _answers;
  bool get isQuizStarted => _isQuizStarted;
  bool get isQuizFinished => _isQuizFinished;
  bool get isLoading => _isLoading;
  String? get error => _error;

  QuizQuestion? get currentQuestion =>
      _quiz?.questions[_currentQuestionIndex];
  bool get hasPrevious => _currentQuestionIndex > 0;
  bool get hasNext =>
      _quiz != null && _currentQuestionIndex < _quiz!.questions.length - 1;
  bool get allAnswered =>
      _quiz != null && _answers.length == _quiz!.questions.length;

  int get timeRemainingSeconds => _timeRemainingSeconds;
  String get timeRemainingFormatted {
    final minutes = (_timeRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timeRemainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get isTimeUp => _timeRemainingSeconds <= 0 && _quiz!.timeLimitMinutes > 0;

  Future<void> loadQuiz(String quizId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      // final response = await http.get(Uri.parse('$apiBase/quizzes/$quizId'));
      // _quiz = Quiz.fromJson(jsonDecode(response.body));

      _quiz = _getDemoQuiz();
      _attemptsRemaining = _quiz!.maxAttempts;
    } catch (e) {
      _error = 'Failed to load quiz';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startQuiz() {
    _isQuizStarted = true;
    _currentQuestionIndex = 0;
    _answers.clear();

    if (_quiz!.timeLimitMinutes > 0) {
      _timeRemainingSeconds = _quiz!.timeLimitMinutes * 60;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _timeRemainingSeconds--;
        if (_timeRemainingSeconds <= 0) {
          _timer?.cancel();
          submitQuiz();
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void selectAnswer(int questionIndex, dynamic answer) {
    _answers[questionIndex] = answer;
    notifyListeners();
  }

  void nextQuestion() {
    if (hasNext) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (hasPrevious) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && _quiz != null && index < _quiz!.questions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  QuizResult submitQuiz() {
    _timer?.cancel();
    _isQuizFinished = true;
    _attemptsRemaining--;

    int correct = 0;
    final results = <QuestionResult>[];

    for (int i = 0; i < _quiz!.questions.length; i++) {
      final question = _quiz!.questions[i];
      final userAnswer = _answers[i];
      bool isCorrect = false;

      switch (question.type) {
        case QuestionType.trueFalse:
        case QuestionType.fillInBlank:
          isCorrect = userAnswer?.toString().toLowerCase().trim() ==
              question.correctAnswer?.toLowerCase().trim();
          break;
        case QuestionType.singleChoice:
          isCorrect = userAnswer == question.correctAnswer;
          break;
        case QuestionType.multipleChoice:
          if (userAnswer is List<String> && question.correctAnswers != null) {
            final sorted = List<String>.from(userAnswer)..sort();
            final correctSorted =
                List<String>.from(question.correctAnswers!)..sort();
            isCorrect = sorted.toString() == correctSorted.toString();
          }
          break;
      }

      if (isCorrect) correct++;
      results.add(QuestionResult(
        question: question,
        userAnswer: userAnswer,
        isCorrect: isCorrect,
      ));
    }

    final score =
        _quiz!.questions.isEmpty ? 0.0 : (correct / _quiz!.questions.length) * 100;

    notifyListeners();

    return QuizResult(
      totalQuestions: _quiz!.questions.length,
      correctAnswers: correct,
      score: score,
      passed: score >= _quiz!.passingGrade,
      questionResults: results,
    );
  }

  void retryQuiz() {
    if (_attemptsRemaining > 0) {
      _isQuizStarted = false;
      _isQuizFinished = false;
      _currentQuestionIndex = 0;
      _answers.clear();
      _timeRemainingSeconds = 0;
      _timer?.cancel();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static Quiz _getDemoQuiz() {
    return const Quiz(
      id: 'q1',
      title: 'Flutter Fundamentals Quiz',
      description: 'Test your knowledge of Flutter basics. You have 10 minutes to complete this quiz.',
      timeLimitMinutes: 10,
      passingGrade: 70.0,
      maxAttempts: 3,
      questions: [
        QuizQuestion(
          id: 'q1',
          text: 'Flutter is developed by Google.',
          type: QuestionType.trueFalse,
          correctAnswer: 'true',
          explanation: 'Flutter is an open-source UI toolkit developed by Google for building natively compiled applications for mobile, web, and desktop.',
        ),
        QuizQuestion(
          id: 'q2',
          text: 'Which widget is used to display content that can scroll?',
          type: QuestionType.singleChoice,
          options: [
            QuizOption(id: 'a', text: 'Container'),
            QuizOption(id: 'b', text: 'Column'),
            QuizOption(id: 'c', text: 'ListView'),
            QuizOption(id: 'd', text: 'Row'),
          ],
          correctAnswer: 'c',
          explanation: 'ListView is a scrollable list of widgets arranged linearly. For scrollable content, ListView and SingleChildScrollView are commonly used.',
        ),
        QuizQuestion(
          id: 'q3',
          text: 'Which of the following are Flutter layout widgets? (Select all that apply)',
          type: QuestionType.multipleChoice,
          options: [
            QuizOption(id: 'a', text: 'Row'),
            QuizOption(id: 'b', text: 'Text'),
            QuizOption(id: 'c', text: 'Column'),
            QuizOption(id: 'd', text: 'Stack'),
            QuizOption(id: 'e', text: 'Icon'),
          ],
          correctAnswers: ['a', 'c', 'd'],
          explanation: 'Row, Column, and Stack are layout widgets. Text and Icon are leaf widgets that display content.',
        ),
        QuizQuestion(
          id: 'q4',
          text: 'The function used to launch a new Flutter app is called ___.',
          type: QuestionType.fillInBlank,
          correctAnswer: 'runapp',
          explanation: 'The main() function calls runApp() which takes a Widget and makes it the root of the widget tree.',
        ),
        QuizQuestion(
          id: 'q5',
          text: 'What is the name of Flutter\'s programming language?',
          type: QuestionType.singleChoice,
          options: [
            QuizOption(id: 'a', text: 'Kotlin'),
            QuizOption(id: 'b', text: 'Dart'),
            QuizOption(id: 'c', text: 'Java'),
            QuizOption(id: 'd', text: 'Swift'),
          ],
          correctAnswer: 'b',
          explanation: 'Flutter uses Dart as its programming language. Dart is also developed by Google.',
        ),
      ],
    );
  }
}

// ─── Quiz Screen ─────────────────────────────────────────────────────────────

class QuizScreen extends StatefulWidget {
  static const route = '/quiz';
  final String quizId;
  final String courseTitle;

  const QuizScreen({
    super.key,
    required this.quizId,
    required this.courseTitle,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = QuizProvider();
    _provider.addListener(_onProviderUpdate);
    _provider.loadQuiz(widget.quizId);
  }

  void _onProviderUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_provider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.courseTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_provider.error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.courseTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_provider.error!),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _provider.loadQuiz(widget.quizId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_provider.isQuizFinished) {
      return _QuizResultScreen(provider: _provider, quizTitle: widget.courseTitle);
    }

    if (!_provider.isQuizStarted) {
      return _QuizStartScreen(provider: _provider, quizTitle: widget.courseTitle);
    }

    return _QuizPlayScreen(provider: _provider, quizTitle: widget.courseTitle);
  }
}

// ─── Quiz Start Screen ───────────────────────────────────────────────────────

class _QuizStartScreen extends StatelessWidget {
  final QuizProvider provider;
  final String quizTitle;

  const _QuizStartScreen({required this.provider, required this.quizTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiz = provider.quiz!;

    return Scaffold(
      appBar: AppBar(title: Text(quizTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.quiz,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                quiz.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (quiz.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  quiz.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              _InfoCard(
                icon: Icons.help_outline,
                label: 'Questions',
                value: '${quiz.questions.length}',
              ),
              const SizedBox(height: 12),
              if (quiz.timeLimitMinutes > 0)
                _InfoCard(
                  icon: Icons.timer_outlined,
                  label: 'Time Limit',
                  value: '${quiz.timeLimitMinutes} min',
                ),
              if (quiz.timeLimitMinutes > 0) const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.grade_outlined,
                label: 'Passing Grade',
                value: '${quiz.passingGrade.toInt()}%',
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.replay,
                label: 'Max Attempts',
                value: '${quiz.maxAttempts}',
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: provider.startQuiz,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Quiz'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyLarge),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quiz Play Screen ────────────────────────────────────────────────────────

class _QuizPlayScreen extends StatelessWidget {
  final QuizProvider provider;
  final String quizTitle;

  const _QuizPlayScreen({required this.provider, required this.quizTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiz = provider.quiz!;
    final question = provider.currentQuestion!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Quit Quiz?'),
            content: const Text(
              'Are you sure you want to quit? Your progress will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Quit'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(quizTitle),
          actions: [
            if (quiz.timeLimitMinutes > 0)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: provider.timeRemainingSeconds < 60
                          ? theme.colorScheme.error
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: provider.timeRemainingSeconds < 60
                              ? theme.colorScheme.onError
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          provider.timeRemainingFormatted,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: provider.timeRemainingSeconds < 60
                                ? theme.colorScheme.onError
                                : theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Question indicator dots
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: quiz.questions.length,
                itemBuilder: (context, index) {
                  final isAnswered = provider.answers.containsKey(index);
                  final isCurrent = index == provider.currentQuestionIndex;
                  return GestureDetector(
                    onTap: () => provider.goToQuestion(index),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : isAnswered
                                ? theme.colorScheme.primary.withOpacity(0.3)
                                : theme.colorScheme.surfaceContainerHighest,
                        border: isCurrent
                            ? Border.all(color: theme.colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isCurrent
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Question number and progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Question ${provider.currentQuestionIndex + 1} of ${quiz.questions.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  _QuestionTypeBadge(type: question.type),
                ],
              ),
            ),

            const Divider(),

            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.text,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AnswerWidget(
                      question: question,
                      questionIndex: provider.currentQuestionIndex,
                      selectedAnswer: provider.answers[provider.currentQuestionIndex],
                      onAnswer: (answer) =>
                          provider.selectAnswer(provider.currentQuestionIndex, answer),
                    ),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          provider.hasPrevious ? provider.previousQuestion : null,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (provider.hasNext)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: provider.nextQuestion,
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Next'),
                      ),
                    )
                  else
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: provider.allAnswered
                            ? () => _showSubmitDialog(context)
                            : null,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Submit'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitDialog(BuildContext context) {
    final unanswered =
        provider.quiz!.questions.length - provider.answers.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Quiz?'),
        content: Text(
          unanswered > 0
              ? 'You have $unanswered unanswered question(s). Are you sure you want to submit?'
              : 'Are you sure you want to submit your answers?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.submitQuiz();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

// ─── Answer Widget ───────────────────────────────────────────────────────────

class _AnswerWidget extends StatelessWidget {
  final QuizQuestion question;
  final int questionIndex;
  final dynamic selectedAnswer;
  final ValueChanged<dynamic> onAnswer;

  const _AnswerWidget({
    required this.question,
    required this.questionIndex,
    this.selectedAnswer,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuestionType.trueFalse:
        return _TrueFalseAnswer(
          selectedValue: selectedAnswer,
          onAnswer: onAnswer,
        );
      case QuestionType.singleChoice:
        return _SingleChoiceAnswer(
          options: question.options,
          selectedId: selectedAnswer,
          onAnswer: onAnswer,
        );
      case QuestionType.multipleChoice:
        return _MultipleChoiceAnswer(
          options: question.options,
          selectedIds: selectedAnswer is List<String> ? selectedAnswer : [],
          onAnswer: onAnswer,
        );
      case QuestionType.fillInBlank:
        return _FillInBlankAnswer(
          initialValue: selectedAnswer,
          onAnswer: onAnswer,
        );
    }
  }
}

class _TrueFalseAnswer extends StatelessWidget {
  final String? selectedValue;
  final ValueChanged<String> onAnswer;

  const _TrueFalseAnswer({this.selectedValue, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SelectionTile(
            label: 'True',
            isSelected: selectedValue == 'true',
            onTap: () => onAnswer('true'),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SelectionTile(
            label: 'False',
            isSelected: selectedValue == 'false',
            onTap: () => onAnswer('false'),
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}

class _SingleChoiceAnswer extends StatelessWidget {
  final List<QuizOption> options;
  final String? selectedId;
  final ValueChanged<String> onAnswer;

  const _SingleChoiceAnswer({
    required this.options,
    this.selectedId,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        final isSelected = option.id == selectedId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<String>(
            value: option.id,
            groupValue: selectedId,
            onChanged: (value) {
              if (value != null) onAnswer(value);
            },
            title: Text(option.text),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            tileColor: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _MultipleChoiceAnswer extends StatelessWidget {
  final List<QuizOption> options;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onAnswer;

  const _MultipleChoiceAnswer({
    required this.options,
    required this.selectedIds,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        final isSelected = selectedIds.contains(option.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              final updated = List<String>.from(selectedIds);
              if (value == true) {
                updated.add(option.id);
              } else {
                updated.remove(option.id);
              }
              onAnswer(updated);
            },
            title: Text(option.text),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            tileColor: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _FillInBlankAnswer extends StatelessWidget {
  final String? initialValue;
  final ValueChanged<String> onAnswer;

  const _FillInBlankAnswer({this.initialValue, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: initialValue ?? ''),
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      onChanged: onAnswer,
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _SelectionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionTypeBadge extends StatelessWidget {
  final QuestionType type;

  const _QuestionTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String label;
    switch (type) {
      case QuestionType.trueFalse:
        label = 'True / False';
        break;
      case QuestionType.singleChoice:
        label = 'Single Choice';
        break;
      case QuestionType.multipleChoice:
        label = 'Multiple Choice';
        break;
      case QuestionType.fillInBlank:
        label = 'Fill in Blank';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

// ─── Quiz Result Screen ──────────────────────────────────────────────────────

class _QuizResultScreen extends StatelessWidget {
  final QuizProvider provider;
  final String quizTitle;

  const _QuizResultScreen({required this.provider, required this.quizTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = provider.submitQuiz();

    return Scaffold(
      appBar: AppBar(
        title: Text(quizTitle),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Score circle
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: result.score / 100,
                      strokeWidth: 12,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: result.passed ? Colors.green : theme.colorScheme.error,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${result.score.toStringAsFixed(0)}%',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: result.passed ? Colors.green : theme.colorScheme.error,
                        ),
                      ),
                      Text(
                        result.passed ? 'PASSED' : 'FAILED',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: result.passed ? Colors.green : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${result.correctAnswers}/${result.totalQuestions} correct answers',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),

            // Question breakdown
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Answers',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...result.questionResults.asMap().entries.map((entry) {
              final idx = entry.key;
              final qr = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: Icon(
                    qr.isCorrect ? Icons.check_circle : Icons.cancel,
                    color: qr.isCorrect ? Colors.green : theme.colorScheme.error,
                  ),
                  title: Text(
                    'Question ${idx + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    qr.question.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question: ${qr.question.text}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your answer: ${_formatAnswer(qr.question.type, qr.userAnswer)}',
                            style: TextStyle(
                              color: qr.isCorrect ? Colors.green : theme.colorScheme.error,
                            ),
                          ),
                          if (qr.question.explanation != null) ...[
                            const Divider(height: 24),
                            Text(
                              'Explanation:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              qr.question.explanation!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Back to Course'),
                  ),
                ),
                const SizedBox(width: 12),
                if (provider._attemptsRemaining > 0 && !result.passed)
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        provider.retryQuiz();
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Retry (${provider._attemptsRemaining} left)'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatAnswer(QuestionType type, dynamic answer) {
    if (answer == null) return 'Not answered';
    if (answer is List) {
      return answer.join(', ');
    }
    return answer.toString();
  }
}
