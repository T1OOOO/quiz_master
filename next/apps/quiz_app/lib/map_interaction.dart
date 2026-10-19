import 'package:flutter/widgets.dart';

/// A page whose embedded maps own their pointer contacts until release/cancel.
class MapScrollView extends StatefulWidget {
  const MapScrollView({
    super.key,
    required this.child,
    this.padding,
    this.controller,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  @override
  State<MapScrollView> createState() => _MapScrollViewState();
}

class _MapScrollViewState extends State<MapScrollView> {
  final _pointers = <int>{};

  void _start(int pointer) {
    if (mounted && !_pointers.contains(pointer)) {
      setState(() => _pointers.add(pointer));
    }
  }

  void _end(int pointer) {
    if (mounted && _pointers.contains(pointer)) {
      setState(() => _pointers.remove(pointer));
    }
  }

  @override
  Widget build(BuildContext context) => _MapScrollScope(
    onStart: _start,
    // The page receives release/cancel even if the map disappears mid-contact.
    child: Listener(
      onPointerUp: (event) => _end(event.pointer),
      onPointerCancel: (event) => _end(event.pointer),
      child: SingleChildScrollView(
        controller: widget.controller,
        padding: widget.padding,
        physics: _pointers.isEmpty
            ? null
            : const NeverScrollableScrollPhysics(),
        child: widget.child,
      ),
    ),
  );
}

class _MapScrollScope extends InheritedWidget {
  const _MapScrollScope({required this.onStart, required super.child});
  final ValueChanged<int> onStart;

  @override
  bool updateShouldNotify(_MapScrollScope oldWidget) =>
      onStart != oldWidget.onStart;
}

class MapInteraction extends StatelessWidget {
  const MapInteraction({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_MapScrollScope>();
    return Listener(
      onPointerDown: (event) => scope?.onStart(event.pointer),
      child: child,
    );
  }
}
