import 'dart:js_interop';

@JS('quizAtlasLandReady')
external JSFunction? get _quizAtlasLandReady;

void notifyAtlasLandReady() {
  _quizAtlasLandReady?.callAsFunction();
}
