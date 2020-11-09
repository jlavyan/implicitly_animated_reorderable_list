import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src.dart';

/// A `Widget` that is used to initiate a drag/reorder of a [Reorderable] inside an
/// [ImplicitlyAnimatedReorderableList].
///
/// A `Handle` must have a [Reorderable] and an [ImplicitlyAnimatedReorderableList]
/// as its ancestor.
class Handle extends StatefulWidget {
  /// The child of this Handle that can initiate a reorder.
  ///
  /// This might for instance be an [Icon] or a [ListTile].
  final Widget child;

  /// The delay between when a pointer touched the [child] and
  /// when the drag is initiated.
  ///
  /// If the Handle wraps the whole item, the delay should be greater
  /// than the default `Duration.zero` as otherwise the list might become unscrollable.
  ///
  /// When the [ImplicitlyAnimatedReorderableList] was scrolled in the mean time,
  /// the reorder will be canceled.
  /// If the [ImplicitlyAnimatedReorderableList] uses a `NeverScrollableScrollPhysics`
  /// the Handle will instead use a parent `Scrollable` if there is one.
  final Duration delay;

  /// Whether to vibrate when a drag has been initiated.
  final bool vibrate;

  /// Whether the handle should capture the pointer event of the drag.
  ///
  /// When this is set to `true`, the `Hanlde` is not allowed to change
  /// the parent between normal and dragged state.
  final bool capturePointer;

  /// Creates a widget that can initiate a drag/reorder of an item inside an
  /// [ImplicitlyAnimatedReorderableList].
  ///
  /// A Handle must have a [Reorderable] and an [ImplicitlyAnimatedReorderableList]
  /// as its ancestor.
  const Handle({
    Key key,
    @required this.child,
    this.delay = Duration.zero,
    this.capturePointer = true,
    this.vibrate = true,
  })  : assert(delay != null),
        assert(child != null),
        assert(vibrate != null),
        super(key: key);

  @override
  _HandleState createState() => _HandleState();
}

class _HandleState extends State<Handle> {
  ScrollableState _scrollable;
  // A custom handler used to cancel the pending onDragStart callbacks.
  Handler _handler;
  // The parent Reorderable item.
  ReorderableState _reorderable;
  // The parent list.
  ImplicitlyAnimatedReorderableListState _list;
  // Whether the ImplicitlyAnimatedReorderableList has a
  // scrollDirection of Axis.vertical.
  bool get _isVertical => _list?.isVertical ?? true;

  Offset _pointer;
  double _initialOffset;
  double _currentOffset;
  double get _delta => (_currentOffset ?? 0) - (_initialOffset ?? 0);

  // Use flags from the list as this State object is being
  // recreated between dragged and normal state.
  bool get _inDrag => _list.inDrag ?? false;
  bool get _inReorder => _list.inReorder ?? false;

  void _onDragStarted() {
    _removeScrollListener();

    // If the list is already in drag we dont want to
    // initiate a new reorder.
    if (_inReorder) return;

    _initialOffset = _isVertical ? _pointer.dy : _pointer.dx;

    _list?.onDragStarted(_reorderable?.key);
    _reorderable.rebuild();

    _vibrate();
  }

  void _onDragUpdated(Offset pointer) {
    _currentOffset = _isVertical ? pointer.dy : pointer.dx;
    _list?.onDragUpdated(_delta);
  }

  void _onDragEnded() {
    _handler?.cancel();
    _list?.onDragEnded();
  }

  void _vibrate() {
    if (widget.vibrate) HapticFeedback.mediumImpact();
  }

  // A Handle should only initiate a reorder when the list didn't change it scroll
  // position in the meantime.

  bool get _useParentScrollable {
    final hasParent = _scrollable != null;
    final physics = _list?.widget?.physics;

    return hasParent && physics != null && physics is NeverScrollableScrollPhysics;
  }

  void _addScrollListener() {
    if (widget.delay > Duration.zero) {
      if (_useParentScrollable) {
        _scrollable.position.addListener(_onUp);
      } else {
        _list?.scrollController?.addListener(_onUp);
      }
    }
  }

  void _removeScrollListener() {
    if (widget.delay > Duration.zero) {
      if (_useParentScrollable) {
        _scrollable.position.removeListener(_onUp);
      } else {
        _list?.scrollController?.removeListener(_onUp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _list ??= ImplicitlyAnimatedReorderableList.of(context);
    assert(_list != null,
        'No ancestor ImplicitlyAnimatedReorderableList was found in the hierarchy!');
    _reorderable ??= Reorderable.of(context);
    assert(_reorderable != null, 'No ancestor Reorderable was found in the hierarchy!');
    _scrollable = Scrollable.of(_list.context);

    if (widget.capturePointer) {
      // Sometimes the cancel callbacks of the GestureDetector
      // are erroneously invoked. Use a plain Listener instead
      // for now.
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerMove: (event) => _onUpdate(event.localPosition),
        onPointerUp: (_) => _onUp(),
        onPointerCancel: (_) => _onUp(),
        child: _isVertical
            ? GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragDown: (event) => _onDown(event.localPosition),
                // Only capture the following events.
                onVerticalDragUpdate: (event) {},
                onVerticalDragEnd: (_) {},
                onVerticalDragCancel: () {},
                child: widget.child,
              )
            : GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragDown: (event) => _onDown(event.localPosition),
                // Only capture the following events.
                onHorizontalDragUpdate: (event) {},
                onHorizontalDragEnd: (_) {},
                onHorizontalDragCancel: () {},
                child: widget.child,
              ),
      );
    } else {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) => _onDown(event.localPosition),
        onPointerMove: (event) => _onUpdate(event.localPosition),
        onPointerUp: (_) => _onUp(),
        onPointerCancel: (_) => _onUp(),
        child: widget.child,
      );
    }
  }

  void _onDown(Offset pointer) {
    _pointer = pointer;

    // Ensure the list is not already in a reordering
    // state when initiating a new reorder operation.
    if (!_inDrag) {
      _onUp();

      _addScrollListener();
      _handler = postDuration(
        widget.delay,
        _onDragStarted,
      );
    }
  }

  void _onUpdate(Offset pointer) {
    _pointer = pointer;

    if (_inDrag && _inReorder) {
      _onDragUpdated(pointer);
    }
  }

  void _onUp() {
    _handler?.cancel();
    _removeScrollListener();

    if (_inDrag) _onDragEnded();
  }
}
