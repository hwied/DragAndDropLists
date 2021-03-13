// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

const Duration _kExpand = Duration(milliseconds: 200);

/// A single-line [ListTile] with a trailing button that expands or collapses
/// the tile to reveal or hide the [child].
///
/// This widget is typically used with [ListView] to create an
/// "expand / collapse" list entry. When used with scrolling widgets like
/// [ListView], a unique [PageStorageKey] must be specified to enable the
/// [ProgrammaticExpansionContainer] to save and restore its expanded state when it is scrolled
/// in and out of view.
///
/// See also:
///
///  * [ListTile], useful for creating expansion tile [child] when the
///    expansion tile represents a sublist.
///  * The "Expand/collapse" section of
///    <https://material.io/guidelines/components/lists-controls.html>.
class ProgrammaticExpansionContainer extends StatefulWidget {
  /// Creates a single-line [Row] with a leading button that expands or collapses
  /// the tile to reveal or hide the [child]. The [initiallyExpanded] property must
  /// be non-null.
  const ProgrammaticExpansionContainer({
    required Key key,
    required this.listKey,
    this.leading,
    required this.header,
    this.headerPadding,
    this.footer,
    this.collapsedFooter,
    this.decoration,
    this.onExpansionChanged,
    this.child,
    this.trailing,
    this.initiallyExpanded = false,
    this.disableTopAndBottomBorders = false,
  })  : assert(initiallyExpanded != null),
        assert(listKey != null),
        assert(key != null),
        super(key: key);

  final Key listKey;

  /// A widget to display instead of a rotating arrow icon.
  final Widget? leading;

  /// The primary content of the list item.
  ///
  /// Typically a [Text] widget.
  final List<Widget> header;
  final EdgeInsets? headerPadding;

  /// Additional widget displayed below the List
  final Widget? footer;

  /// Additional content displayed below the title.
  ///
  /// Typically a [Text] widget.
  final Widget? collapsedFooter;

  /// Called when the tile expands or collapses.
  ///
  /// When the tile starts expanding, this function is called with the value
  /// true. When the tile starts collapsing, this function is called with
  /// the value false.
  final ValueChanged<bool>? onExpansionChanged;

  /// The widgets that are displayed when the tile expands.
  ///
  /// Typically [ListTile] widgets.
  final Widget? child;

  /// The decoration to display behind the sublist.
  final Decoration? decoration;

  /// A widget to display after the title
  final Widget? trailing;

  /// Specifies if the list tile is initially expanded (true) or collapsed (false, the default).
  final bool initiallyExpanded;

  /// Disable to borders displayed at the top and bottom when expanded
  final bool disableTopAndBottomBorders;

  @override
  ProgrammaticExpansionContainerState createState() =>
      ProgrammaticExpansionContainerState();
}

class ProgrammaticExpansionContainerState extends State<ProgrammaticExpansionContainer>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _easeOutTween =
      CurveTween(curve: Curves.easeOut);
  static final Animatable<double> _easeInTween =
      CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _halfTween =
      Tween<double>(begin: 0.0, end: 0.5);

  // final ColorTween _borderColorTween = ColorTween();
  // final ColorTween _headerColorTween = ColorTween();
  final ColorTween _iconColorTween = ColorTween();
  // final ColorTween _backgroundColorTween = ColorTween();

  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;
  // late Animation<Color?> _borderColor;
  // late Animation<Color?> _headerColor;
  late Animation<Color?> _iconColor;
  // late Animation<Color?> _backgroundColor;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _kExpand, vsync: this);
    _heightFactor = _controller.drive(_easeInTween);
    _iconTurns = _controller.drive(_halfTween.chain(_easeInTween));
    // _borderColor = _controller.drive(_borderColorTween.chain(_easeOutTween));
    // _headerColor = _controller.drive(_headerColorTween.chain(_easeInTween));
    _iconColor = _controller.drive(_iconColorTween.chain(_easeInTween));
    // _backgroundColor =
    //     _controller.drive(_backgroundColorTween.chain(_easeOutTween));

    _isExpanded = PageStorage.of(context)
            ?.readState(context, identifier: widget.listKey) as bool? ??
        widget.initiallyExpanded;
    if (_isExpanded) _controller.value = 1.0;

    // Schedule the notification that widget has changed for after init
    // to ensure that the parent widget maintains the correct state
    SchedulerBinding.instance!.addPostFrameCallback((Duration duration) {
      if (widget.onExpansionChanged != null &&
          _isExpanded != widget.initiallyExpanded) {
        widget.onExpansionChanged!(_isExpanded);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void expand() {
    _setExpanded(true);
  }

  void collapse() {
    _setExpanded(false);
  }

  void toggle() {
    _setExpanded(!_isExpanded);
  }

  void _setExpanded(bool expanded) {
    if (_isExpanded != expanded) {
      setState(() {
        _isExpanded = expanded;
        if (_isExpanded) {
          _controller.forward();
        } else {
          _controller.reverse().then<void>((void value) {
            if (!mounted) return;
            setState(() {
              // Rebuild without widget.children.
            });
          });
        }
        PageStorage.of(context)
            ?.writeState(context, _isExpanded, identifier: widget.listKey);
      });
      if (widget.onExpansionChanged != null) {
        widget.onExpansionChanged!(_isExpanded);
      }
    }
  }

  Widget _buildChildren(BuildContext context, Widget? child) {
    // final Color borderSideColor = _borderColor.value ?? Colors.transparent;
    // bool setBorder = !widget.disableTopAndBottomBorders;

    return Container(
      decoration: widget.decoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: widget.headerPadding,
            child: Row(
            children:[
              widget.leading ?? IconButton(
                icon: RotationTransition(
                  turns: _iconTurns,
                  child: const Icon(Icons.expand_more),
                ),
                onPressed: toggle,
              )]+
              widget.header
            )
          ),
          ClipRect(
            child: Align(
              heightFactor: _heightFactor.value,
              child: child,
            ),
          ),
          if (!_isExpanded && widget.collapsedFooter!=null)
            Flexible(child: widget.collapsedFooter!),
          if (_isExpanded && widget.footer!=null)
            Flexible(child: widget.footer!)
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    // _borderColorTween.end = theme.dividerColor;
    // _headerColorTween
    //   ..begin = theme.textTheme.subtitle1!.color
    //   ..end = theme.accentColor;
    // _iconColorTween
    //   ..begin = theme.unselectedWidgetColor
    //   ..end = theme.accentColor;
    // _backgroundColorTween.end = widget.backgroundColor;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !_isExpanded && _controller.isDismissed;
    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildChildren,
      child: closed ? null : widget.child,
    );
  }
}
