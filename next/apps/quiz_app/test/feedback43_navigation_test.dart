import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

void main() {
  test(
    'question progress follows receipts and saved answers by question index',
    () {
      final revision = Revision(1, 'a' * 64);
      final snapshots = [
        AttemptSnapshot(
          questionId: 'q-one',
          revision: revision,
          optionOrder: const ['a', 'b', 'c', 'd'],
        ),
        AttemptSnapshot(
          questionId: 'q-two',
          revision: revision,
          optionOrder: const ['a', 'b', 'c', 'd'],
        ),
        AttemptSnapshot(
          questionId: 'q-three',
          revision: revision,
          optionOrder: const ['a', 'b', 'c', 'd'],
        ),
      ];
      final attempt = Attempt(
        id: 'attempt-one',
        participantId: 'p-0123456789abcdef0123456789abcdef',
        bundleVersion: 'v1',
        bundleSha256: 'b' * 64,
        snapshots: snapshots,
      );
      final answered = Receipt(
        id: 'receipt-one',
        attemptId: 'attempt-one',
        participantId: 'p-0123456789abcdef0123456789abcdef',
        questionId: 'q-one',
        revision: revision,
      );
      const feedback = PracticeFeedback(
        true,
        Reveal(answer: 'Answer', explanation: 'Explanation'),
      );

      final state = JourneyState(
        attempt: attempt,
        receipts: [answered],
        stagedByIndex: const {1: SingleChoiceAnswer('a')},
        sentByIndex: const {2: SingleChoiceAnswer('b')},
        feedbackByIndex: const {0: feedback},
      );

      expect(state.progressAt(0), QuestionProgress.answered);
      expect(state.progressAt(1), QuestionProgress.uncertain);
      expect(state.progressAt(2), QuestionProgress.unanswered);
      expect(state.firstUnansweredIndex, 2);
      expect(state.canComplete, isFalse);
      expect(state.answerForSubmissionAt(2), const SingleChoiceAnswer('b'));
      expect(state.reviewRevealAt(0), same(feedback.reveal));
    },
  );
}
