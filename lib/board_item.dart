import 'dart:math';

import 'package:boardview/board_list.dart';
import 'package:boardview/boardview.dart';
import 'package:boardview/custom_drag_drop_item.widget.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef void OnTapItem(int? listIndex, int? itemIndex, BoardItemState state);
typedef void OnStartDragItem(
    int? listIndex, int? itemIndex, BoardItemState state);
typedef void OnDragItem(int oldListIndex, int oldItemIndex, int newListIndex,
    int newItemIndex, BoardItemState state);

class BoardItem extends StatefulWidget {
  final BoardListState? boardList;
  final Widget? item;
  final int? index;
  final OnStartDragItem? onStartDragItem;
  final bool draggable;

  const BoardItem({
    Key? key,
    this.boardList,
    this.item,
    this.index,
    this.onStartDragItem,
    this.draggable = true,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return BoardItemState();
  }
}

class BoardItemState extends State<BoardItem>
    with AutomaticKeepAliveClientMixin<BoardItem> {
  BoardListState get boardList => widget.boardList!;

  BoardViewState get boardView => boardList.widget.boardView!;

  List<BoardListState> get listStates => boardView.listStates;

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
      itemOnWillAccept: (incoming, target) {
        final ListViewItemOrderParam data =
            (target as CustomDragDropItemWidget).data;
        boardView.setTargetList(data.stageIndex);
        return true;
      },
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      axis: Axis.horizontal,
    );
  }

  void _onItemReordered(
      DragAndDropItem reorderedItem, DragAndDropItem receiverItem) {
    final ListViewItemOrderParam oldItem =
        (reorderedItem as CustomDragDropItemWidget).data;
    final ListViewItemOrderParam newItem =
        (receiverItem as CustomDragDropItemWidget).data;
    print(newItem.itemIndex);
    boardView.widget.onDropItem!(
      newItem.stageIndex,
      newItem.itemIndex,
      oldItem.stageIndex,
      oldItem.itemIndex,
      this,
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    boardView.onItemPointerMove(event);
    boardView.onItemPointerMoveList(event);
  }

  void _onItemDraggingChanged(DragAndDropItem item, bool dragging) {
    boardView.setIsDraggingItem(dragging);
    if (dragging)
      widget.onStartDragItem!(
        boardList.widget.index!,
        widget.index!,
        this,
      );
  }

  void _onPointerUp(PointerUpEvent event) {
    boardView.onItemPointerUp();
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
