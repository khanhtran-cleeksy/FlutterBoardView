import 'package:drag_and_drop_lists/drag_and_drop_item.dart';
import 'package:flutter/material.dart';

class CustomDragDropItemWidget implements DragAndDropItem {
  /// The child widget of this item.
  final Widget child;

  /// Widget when draggble
  final Widget? feedbackWidget;

  /// Whether or not this item can be dragged.
  /// Set to true if it can be reordered.
  /// Set to false if it must remain fixed.
  final bool canDrag;
  final dynamic data;

  CustomDragDropItemWidget({
    required this.child,
    this.feedbackWidget,
    this.data,
    this.canDrag = true,
  });
}