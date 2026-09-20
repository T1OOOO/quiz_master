// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'answer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AnswerState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnswerState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AnswerState()';
}


}

/// @nodoc
class $AnswerStateCopyWith<$Res>  {
$AnswerStateCopyWith(AnswerState _, $Res Function(AnswerState) __);
}


/// Adds pattern-matching-related methods to [AnswerState].
extension AnswerStatePatterns on AnswerState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Idle value)?  idle,TResult Function( _Submitting value)?  submitting,TResult Function( _Revealed value)?  revealed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Submitting() when submitting != null:
return submitting(_that);case _Revealed() when revealed != null:
return revealed(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Idle value)  idle,required TResult Function( _Submitting value)  submitting,required TResult Function( _Revealed value)  revealed,}){
final _that = this;
switch (_that) {
case _Idle():
return idle(_that);case _Submitting():
return submitting(_that);case _Revealed():
return revealed(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Idle value)?  idle,TResult? Function( _Submitting value)?  submitting,TResult? Function( _Revealed value)?  revealed,}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Submitting() when submitting != null:
return submitting(_that);case _Revealed() when revealed != null:
return revealed(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  submitting,TResult Function()?  revealed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Submitting() when submitting != null:
return submitting();case _Revealed() when revealed != null:
return revealed();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  submitting,required TResult Function()  revealed,}) {final _that = this;
switch (_that) {
case _Idle():
return idle();case _Submitting():
return submitting();case _Revealed():
return revealed();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  submitting,TResult? Function()?  revealed,}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Submitting() when submitting != null:
return submitting();case _Revealed() when revealed != null:
return revealed();case _:
  return null;

}
}

}

/// @nodoc


class _Idle implements AnswerState {
  const _Idle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Idle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AnswerState.idle()';
}


}




/// @nodoc


class _Submitting implements AnswerState {
  const _Submitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Submitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AnswerState.submitting()';
}


}




/// @nodoc


class _Revealed implements AnswerState {
  const _Revealed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Revealed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AnswerState.revealed()';
}


}




// dart format on
