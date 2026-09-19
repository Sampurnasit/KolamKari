import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/seed/quiz_seed_data.dart';
import '../../providers/app_providers.dart';

class HeritageQuizScreen extends ConsumerStatefulWidget {
  final bool isDailyChallenge;
  final VoidCallback? onChallengeCompleted;

  const HeritageQuizScreen({
    super.key,
    this.isDailyChallenge = false,
    this.onChallengeCompleted,
  });

  @override
  ConsumerState<HeritageQuizScreen> createState() => _HeritageQuizScreenState();
}

class _HeritageQuizScreenState extends ConsumerState<HeritageQuizScreen> {
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _score = 0;
  bool _quizFinished = false;

  final List<QuizQuestion> _questions = QuizSeedData.questions;

  void _submitAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == _questions[_currentIndex].correctIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    setState(() {
      _quizFinished = true;
    });

    // Award +30 XP for quiz
    await ref.read(userProfileProvider.notifier).onQuizCompleted(_score, _questions.length);

    if (widget.isDailyChallenge) {
      await ref.read(userProfileProvider.notifier).onDailyChallengeCompleted();
      widget.onChallengeCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDailyChallenge ? 'Sunday Challenge: Heritage Quiz' : 'Heritage & Ethnomathematics Quiz'),
      ),
      body: _quizFinished
          ? _buildResultsView(isDark)
          : _buildQuestionView(isDark),
    );
  }

  Widget _buildQuestionView(bool isDark) {
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linear progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? AppColors.slateCard : AppColors.borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.turmericGold),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 16),

          // Header row with category badge and question counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.terracottaRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  q.culturalTag,
                  style: AppTypography.tagText.copyWith(color: AppColors.terracottaRed),
                ),
              ),
              Text(
                'Question ${_currentIndex + 1} of ${_questions.length}',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Question Prompt
          Text(
            q.question,
            style: AppTypography.cardTitle.copyWith(
              fontSize: 18,
              height: 1.4,
              color: isDark ? AppColors.textLight : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),

          // Option Cards
          ...List.generate(q.options.length, (index) {
            final optionText = q.options[index];
            Color? cardBg;
            BorderSide border = BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            );

            if (_answered) {
              if (index == q.correctIndex) {
                cardBg = AppColors.tulsiGreen.withValues(alpha: 0.15);
                border = const BorderSide(color: AppColors.tulsiGreen, width: 2);
              } else if (index == _selectedOption) {
                cardBg = AppColors.crimsonRed.withValues(alpha: 0.15);
                border = const BorderSide(color: AppColors.crimsonRed, width: 2);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _submitAnswer(index),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardBg ?? (isDark ? AppColors.slateCard : AppColors.riceFlourCard),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.fromBorderSide(border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isDark ? AppColors.slateLight : const Color(0xFFF0EAE1),
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textLight : AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          optionText,
                          style: AppTypography.bodyText.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_answered && index == q.correctIndex)
                        const Icon(Icons.check_circle_rounded, color: AppColors.tulsiGreen, size: 22)
                      else if (_answered && index == _selectedOption)
                        const Icon(Icons.cancel_rounded, color: AppColors.crimsonRed, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Explanation Card (appears after answering)
          if (_answered) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slateCard : const Color(0xFFF9F3EA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.turmericGold.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedOption == q.correctIndex
                            ? Icons.lightbulb_rounded
                            : Icons.info_outline_rounded,
                        color: AppColors.turmericAmber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cultural Insight',
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 14,
                          color: AppColors.turmericAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.explanation,
                    style: AppTypography.bodyText.copyWith(fontSize: 13.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Next Question / Finish Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _nextQuestion,
                icon: Icon(
                  _currentIndex < _questions.length - 1
                      ? Icons.arrow_forward_rounded
                      : Icons.emoji_events_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  _currentIndex < _questions.length - 1
                      ? 'Next Question'
                      : 'View Results',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsView(bool isDark) {
    final percentage = (_score / _questions.length) * 100;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.turmericGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 72,
                color: AppColors.turmericGold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              percentage >= 70 ? 'Sacred Wisdom Attained!' : 'Good Effort, Seeker!',
              style: AppTypography.displayTitle.copyWith(
                color: isDark ? AppColors.textLight : AppColors.textDark,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'You answered $_score of ${_questions.length} questions correctly.',
              style: AppTypography.bodyText.copyWith(
                fontSize: 15,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),

            // XP Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.tulsiGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.tulsiGreen),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.tulsiGreen, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    widget.isDailyChallenge ? '+130 XP Earned!' : '+30 XP Earned!',
                    style: AppTypography.cardTitle.copyWith(
                      color: AppColors.tulsiGreen,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              label: const Text('Return to Learn Hub'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
