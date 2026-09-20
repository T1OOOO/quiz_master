import 'package:freezed_annotation/freezed_annotation.dart';

part 'answer_state.freezed.dart';

@freezed
sealed class AnswerState with _$AnswerState {
  const factory AnswerState.idle() = _Idle;
  const factory AnswerState.submitting() = _Submitting;
  const factory AnswerState.revealed() = _Revealed;
}
