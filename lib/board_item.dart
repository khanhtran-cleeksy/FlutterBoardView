import 'dart:math';

import 'package:boardview/board_list.dart';
import 'package:boardview/custom_drag_drop_item.widget.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef void OnDropItem(int? listIndex, int? itemIndex, int? oldListIndex,
    int? oldItemIndex, BoardItemState state);
typedef void OnTapItem(int? listIndex, int? itemIndex, BoardItemState state);
typedef void OnStartDragItem(
    int? listIndex, int? itemIndex, BoardItemState state);
typedef void OnDragItem(int oldListIndex, int oldItemIndex, int newListIndex,
    int newItemIndex, BoardItemState state);

class BoardItem extends StatefulWidget {
  final BoardListState? boardList;
  final Widget? item;
  final int? index;
  final OnDropItem? onDropItem;
  final OnTapItem? onTapItem;
  final OnStartDragItem? onStartDragItem;
  final OnDragItem? onDragItem;
  final bool draggable;

  const BoardItem(
      {Key? key,
      this.boardList,
      this.item,
      this.index,
      this.onDropItem,
      this.onTapItem,
      this.onStartDragItem,
      this.draggable = true,
      this.onDragItem})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return BoardItemState();
  }
}

class BoardItemState extends State<BoardItem>
    with AutomaticKeepAliveClientMixin<BoardItem> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var boardList = widget.boardList!;

    return DragAndDropItemWrapper(
      parameters: _dragAndDropItemParameters(),
      child: CustomDragDropItemWidget(
        canDrag: widget.draggable,
        data: ListViewItemOrderParam(
            stageIndex: boardList.widget.index!, itemIndex: widget.index!),
        child: SizedBox(
          width: double.infinity,
          child: widget.item!,
        ),
      ),
    );
  }

  DragAndDropBuilderParameters _dragAndDropItemParameters() {
    return DragAndDropBuilderParameters(
      onItemReordered: _onItemReordered,
      onItemDraggingChanged: _onItemDraggingChanged,
      onPointerMove: _onPointerMove,
      onPointerUp: (event) => _cancelTimer(),
      axis: Axis.horizontal,
    );
  }

  void _onItemReordered(
      DragAndDropItem reorderedItem, DragAndDropItem receiverItem) {
    final ListViewItemOrderParam oldItem =
        (reorderedItem as CustomDragDropItemWidget).data;
    final ListViewItemOrderParam newItem =
        (receiverItem as CustomDragDropItemWidget).data;
    widget.onDropItem!(
      newItem.stageIndex,
      max(0, newItem.itemIndex - 1),
      oldItem.stageIndex,
      oldItem.itemIndex,
      this,
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    var boardList = widget.boardList;
    var boardView = boardList!.widget.boardView;
    boardView!.onItemPointerMove(event);
    boardList.onItemPointerMove(event);
  }

  void _onItemDraggingChanged(DragAndDropItem item, bool dragging) {
    var boardList = widget.boardList!;
    boardList.setIsDraggingItem(dragging);
    if (dragging)
      widget.onStartDragItem!(
        boardList.widget.index!,
        widget.index!,
        this,
      );
  }

  void _cancelTimer() {
    // if (_timer?.isActive == true) {
    //   _timer?.cancel();
    // }
  }
}

class ListViewItemOrderParam {
  final int stageIndex;
  int itemIndex;

  ListViewItemOrderParam({
    required this.stageIndex,
    required this.itemIndex,
  });

  @override
  String toString() {
    return "{stageIndex: $stageIndex, itemIndex: $itemIndex}";
  }
}
