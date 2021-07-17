import 'dart:async';
import 'package:drag_and_drop_lists/drag_and_drop_builder_parameters.dart';
import 'package:drag_and_drop_lists/drag_and_drop_item.dart';
import 'package:drag_and_drop_lists/drag_and_drop_item_target.dart';
import 'package:drag_and_drop_lists/drag_and_drop_item_wrapper.dart';
import 'package:drag_and_drop_lists/drag_and_drop_list_interface.dart';
import 'package:drag_and_drop_lists/programmatic_expansion_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class DragAndDropListCollapsable implements DragAndDropListExpansionInterface {
  final Widget? leading;

  /// The widget that is displayed at the top of the list.
  final List<Widget> header;
  final EdgeInsets? headerPadding;

  /// The widget that is displayed at the bottom of the list.
  final Widget? footer;

  /// The widget that is displayed at the bottom of the list when it is collapsed.
  final Widget? collapsedFooter;

  /// The widget that is displayed to the left of the list.
  final Widget? leftSide;

  /// The widget that is displayed to the right of the list.
  final Widget? rightSide;

  /// The widget to be displayed when a list is empty.
  /// If this is not null, it will override that set in [DragAndDropLists.contentsWhenEmpty].
  final Widget? contentsWhenEmpty;

  /// The widget to be displayed as the last element in the list that will accept
  /// a dragged item.
  final Widget? lastTarget;

  /// Set this to a unique key that will remain unchanged over the lifetime of the list.
  /// Used to maintain the expanded/collapsed states
  final Key listKey;

  /// The decoration displayed around a list.
  /// If this is not null, it will override that set in [DragAndDropLists.listDecoration].
  final Decoration? decoration;

  /// The vertical alignment of the contents in this list.
  /// If this is not null, it will override that set in [DragAndDropLists.verticalAlignment].
  final CrossAxisAlignment verticalAlignment;

  /// The horizontal alignment of the contents in this list.
  /// If this is not null, it will override that set in [DragAndDropLists.horizontalAlignment].
  final MainAxisAlignment horizontalAlignment;

  /// The child elements that will be contained in this list.
  /// It is possible to not provide any children when an empty list is desired.
  final List<DragAndDropItem> children = <DragAndDropItem>[];

  /// This function will be called when the expansion of a tile is changed.
  final OnExpansionChanged? onExpansionChanged;

  /// Disable to borders displayed at the top and bottom when expanded
  final bool disableTopAndBottomBorders;

  final bool initiallyExpanded;

  /// Whether or not this item can be dragged.
  /// Set to true if it can be reordered.
  /// Set to false if it must remain fixed.
  final bool canDrag;

  ValueNotifier<bool> _expanded = ValueNotifier<bool>(true);
  GlobalKey<ProgrammaticExpansionContainerState> _expansionKey =
  GlobalKey<ProgrammaticExpansionContainerState>();

  DragAndDropItemTarget? lastTargetItem;

  DragAndDropListCollapsable(
      {List<DragAndDropItem>? children,
      required this.listKey,
      this.leading,
      this.header=const <Widget>[],
      this.headerPadding,
      this.footer,
      this.collapsedFooter,
      this.leftSide,
      this.rightSide,
      this.contentsWhenEmpty,
      this.onExpansionChanged,
      this.initiallyExpanded = false,
      this.lastTarget,
      this.decoration,
      this.horizontalAlignment = MainAxisAlignment.start,
      this.verticalAlignment = CrossAxisAlignment.start,
      this.canDrag = true,
      this.disableTopAndBottomBorders = false,
  }) {
    if (children != null) {
      children.forEach((element) => this.children.add(element));
    }
  }

  @override
  Widget generateWidget(DragAndDropBuilderParameters? params) {
    lastTargetItem = DragAndDropItemTarget(
      parent: this,
      parameters: params!,
      onReorderOrAdd: params.onItemDropOnLastTarget,
      child: lastTarget ??
          Container(
            height: params.lastItemTargetHeight,
          ),
    );
    var contents = <Widget>[];
    Widget intrinsicHeight = IntrinsicHeight(
      child: Row(
        mainAxisAlignment: horizontalAlignment,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _generateDragAndDropListInnerContents(params) as List<Widget>,
      ),
    );
    if (params.listInnerDecoration != null) {
      intrinsicHeight = Container(
        decoration: params.listInnerDecoration,
        child: intrinsicHeight,
      );
    }
    if (params.listInnerDecoration != null) {
      intrinsicHeight = Container(
        decoration: params.listInnerDecoration,
        child: intrinsicHeight,
      );
    }
    contents.add(intrinsicHeight);

    Widget expandable = ProgrammaticExpansionContainer(
      header: header,
      headerPadding: headerPadding,
      listKey: listKey,
      footer: footer,
      collapsedFooter: collapsedFooter ?? footer,
      leading: leading,
      disableTopAndBottomBorders: disableTopAndBottomBorders,
      decoration: decoration ?? params.listDecoration,
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: _onSetExpansion,
      key: _expansionKey,
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: verticalAlignment,
          children: contents,
        ),
      ),
    );

    Widget toReturn = ValueListenableBuilder(
      valueListenable: _expanded,
      child: expandable,
      builder: (context, dynamic error, child) {
        if (!_expanded.value) {
          return Stack(
              children: <Widget>[
                child!,
                Positioned.fill(
                  child: DragTarget<DragAndDropItem>(
                    builder: (context, candidateData, rejectedData) {
                      if (candidateData != null && candidateData.isNotEmpty) {}
                      return Container();
                    },
                    onWillAccept: (incoming) {
                      _startExpansionTimer();
                      return true;
                    },
                    onLeave: (incoming) {
                      _stopExpansionTimer();
                    },
                    onAccept: (incoming) {
                      _stopExpansionTimer();
                      params.onItemDropOnLastTarget!(incoming, this, lastTargetItem!);
                    },
                  ),
                )
              ]
          );
        } else {
          return child!;
        }
      },
    );

    return toReturn;
  }

  List<Widget> _generateDragAndDropListInnerContents(
      DragAndDropBuilderParameters? params) {
    List<Widget> contents = <Widget>[];
    if (leftSide != null) {
      contents.add(leftSide!);
    }
    if (children != null && children.isNotEmpty) {
      List<Widget?> allChildren = <Widget?>[];
      if (params!.addLastItemTargetHeightToTop) {
        allChildren.add(Padding(
          padding: EdgeInsets.only(top: params.lastItemTargetHeight),
        ));
      }
      for (int i = 0; i < children.length; i++) {
        allChildren.add(DragAndDropItemWrapper(
          child: children[i],
          parameters: params,
        ));
        if (params.itemDivider != null && i < children.length - 1) {
          allChildren.add(params.itemDivider);
        }
      }
      allChildren.add(lastTargetItem);
      contents.add(
        Expanded(
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: verticalAlignment,
              mainAxisSize: MainAxisSize.max,
              children: allChildren as List<Widget>,
            ),
          ),
        ),
      );
    } else {
      contents.add(
        Expanded(
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                contentsWhenEmpty ??
                  Text(
                    'Empty list',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                lastTargetItem!
              ],
            ),
          ),
        ),
      );
    }
    if (rightSide != null) {
      contents.add(rightSide!);
    }
    return contents;
  }

  @override
  toggleExpanded() {
    if (isExpanded)
      collapse();
    else
      expand();
  }

  @override
  collapse() {
    if (!isExpanded) {
      _expanded.value = false;
      _expansionKey.currentState!.collapse();
    }
  }

  @override
  expand() {
    if (!isExpanded) {
      _expanded.value = true;
      _expansionKey.currentState!.expand();
    }
  }

  _onSetExpansion(bool expanded) {
    _expanded.value = expanded;

    if (onExpansionChanged != null) onExpansionChanged!(expanded);
  }

  @override
  get isExpanded => _expanded.value;

  late Timer _expansionTimer;

  _startExpansionTimer() async {
    _expansionTimer = Timer(Duration(milliseconds: 400), _expansionCallback);
  }

  _stopExpansionTimer() async {
    if (_expansionTimer.isActive) {
      _expansionTimer.cancel();
    }
  }

  _expansionCallback() {
    expand();
  }
}
