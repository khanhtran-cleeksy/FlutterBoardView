import 'package:boardview/board_list.dart';
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
  late double height;
  double? width;

  @override
  bool get wantKeepAlive => true;

  void onDropItem(int? listIndex, int? itemIndex) {
    var boardList = widget.boardList;
    var boardView = boardList!.widget.boardView!;
    if (widget.onDropItem != null) {
      widget.onDropItem!(listIndex, itemIndex, boardView.startListIndex,
          boardView.startItemIndex, this);
    }
    boardView.draggedItemIndex = null;
    boardView.draggedListIndex = null;
    if (boardView.listStates[listIndex!].mounted) {
      boardView.listStates[listIndex].setState(() {});
    }
  }

  void _startDrag(Widget item, BuildContext context) {
    var boardList = widget.boardList;
    var boardView = boardList!.widget.boardView;
    if (boardView != null) {
      boardView.onDropItem = onDropItem;
      if (boardList.mounted) {
        boardList.setState(() {});
      }
      boardView.draggedItemIndex = widget.index;
      boardView.height = context.size!.height;
      boardView.draggedListIndex = boardList.widget.index;
      boardView.startListIndex = boardList.widget.index;
      boardView.startItemIndex = widget.index;
      boardView.draggedItem = item;
      if (widget.onStartDragItem != null) {
        widget.onStartDragItem!(boardList.widget.index, widget.index, this);
      }
      boardView.run();
      if (boardView.mounted) {
        boardView.setState(() {});
      }
    }
  }

  void afterFirstLayout(BuildContext context) {
    try {
      height = context.size!.height;
      width = context.size!.width;
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    var boardList = widget.boardList;
    var boardView = boardList!.widget.boardView;
    super.build(context);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => afterFirstLayout(context));
    if (boardList.itemStates.length > widget.index!) {
      boardList.itemStates.removeAt(widget.index!);
    }
    boardList.itemStates.insert(widget.index!, this);
    return GestureDetector(
      onTapDown: (otd) {
        if (widget.draggable) {
          RenderBox object = context.findRenderObject() as RenderBox;
          Offset pos = object.localToGlobal(Offset.zero);
          RenderBox box = boardList.context.findRenderObject() as RenderBox;
          Offset listPos = box.localToGlobal(Offset.zero);
          boardView!.leftListX = listPos.dx;
          boardView.topListY = listPos.dy;
          boardView.topItemY = pos.dy;
          boardView.bottomItemY = pos.dy + object.size.height;
          boardView.bottomListY = listPos.dy + box.size.height;
          boardView.rightListX = listPos.dx + box.size.width;
          boardView.initialX = pos.dx;
          boardView.initialY = pos.dy;
        }
      },
      onTapCancel: () {},
      onTap: () {
        if (widget.onTapItem != null) {
          widget.onTapItem!(boardList.widget.index, widget.index, this);
        }
      },
      onLongPress: () {
        if (widget.draggable) {
          _startDrag(widget, context);
        }
      },
      child: widget.item,
    );
  }
}
