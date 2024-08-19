import 'package:flutter/cupertino.dart';

import 'board_item.dart';
import 'boardview.dart';
import 'loadmore.dart';

typedef void OnDropList(int? listIndex, int? oldListIndex);
typedef void OnTapList(int? listIndex);
typedef void OnStartDragList(int? listIndex);
typedef Future<bool> FutureCallBack(int listIndex);

class BoardList extends StatefulWidget {
  final List<Widget>? header;
  final Widget? customWidget;
  final Widget? footer;
  final List<BoardItem>? items;
  final bool loadMore;
  final bool movable;
  final Color? backgroundColor;
  final Color? headerBackgroundColor;
  final BoardViewState? boardView;
  final OnDropList? onDropList;
  final OnTapList? onTapList;
  final Widget? immovableWidget;
  final OnStartDragList? onStartDragList;
  final FutureCallBack? onLoadMore;
  final Decoration? decoration;
  final EdgeInsets? padding;
  final bool draggable;

  const BoardList({
    Key? key,
    this.header,
    this.items,
    this.loadMore = false,
    this.movable = true,
    this.footer,
    this.backgroundColor,
    this.headerBackgroundColor,
    this.boardView,
    this.padding = EdgeInsets.zero,
    this.draggable = true,
    this.index,
    this.onDropList,
    this.onTapList,
    this.onStartDragList,
    this.onLoadMore,
    this.customWidget,
    this.immovableWidget,
    this.decoration,
  }) : super(key: key);

  final int? index;

  @override
  State<StatefulWidget> createState() {
    return BoardListState();
  }
}

class BoardListState extends State<BoardList>
    with AutomaticKeepAliveClientMixin<BoardList> {
  List<BoardItemState> itemStates = [];
  ScrollController boardListController = new ScrollController();

  void onDropList(int? listIndex) {
    var boardView = widget.boardView;
    if (widget.onDropList != null) {
      widget.onDropList!(listIndex, boardView!.startListIndex);
    }
    boardView!.draggedListIndex = null;
    if (boardView.mounted) {
      boardView.setState(() {});
    }
  }

  void _startDrag(Widget item, BuildContext context) {
    var boardView = widget.boardView;
    if (boardView != null && widget.draggable) {
      if (widget.onStartDragList != null) {
        widget.onStartDragList!(widget.index);
      }
      boardView.startListIndex = widget.index;
      boardView.height = context.size!.height;
      boardView.draggedListIndex = widget.index!;
      boardView.draggedItemIndex = null;
      boardView.draggedItem = item;
      boardView.onDropList = onDropList;
      boardView.run();
      if (boardView.mounted) {
        boardView.setState(() {});
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Color? backgroundColor = Color.fromARGB(255, 255, 255, 255);

    if (widget.backgroundColor != null) {
      backgroundColor = widget.backgroundColor;
    }
    var boardView = widget.boardView;
    if (boardView!.listStates.length > widget.index!) {
      boardView.listStates.removeAt(widget.index!);
    }
    boardView.listStates.insert(widget.index!, this);

    return widget.customWidget ??
        Container(
          padding: EdgeInsets.only(
              top: widget.padding?.top ?? 0,
              bottom: widget.padding?.bottom ?? 0),
          decoration:
              widget.decoration ?? BoxDecoration(color: backgroundColor),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            // children: listWidgets as List<Widget>,
            children: [
              GestureDetector(
                onTap: () {
                  if (widget.onTapList != null) {
                    widget.onTapList!(widget.index);
                  }
                },
                onTapDown: (otd) {
                  if (widget.draggable) {
                    RenderBox object = context.findRenderObject() as RenderBox;
                    Offset pos = object.localToGlobal(Offset.zero);
                    boardView.initialX = pos.dx;
                    boardView.initialY = pos.dy;

                    boardView.rightListX = pos.dx + object.size.width;
                    boardView.leftListX = pos.dx;
                  }
                },
                onTapCancel: () {},
                onLongPress: () {
                  if (widget.draggable) {
                    _startDrag(widget, context);
                  }
                },
                child: Container(
                  color: widget.headerBackgroundColor,
                  padding: EdgeInsets.only(
                      right: widget.padding?.right ?? 0,
                      left: widget.padding?.left ?? 0),
                  child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: widget.header!),
                ),
              ),
              if (widget.items != null)
                Expanded(
                  child: widget.movable
                      ? _buildMovableList(boardView)
                      : widget.immovableWidget ?? SizedBox(),
                ),
            ],
          ),
        );
  }

  Widget _buildMovableList(BoardViewState boardView) {
    return CupertinoScrollbar(
      radius: const Radius.circular(10),
      controller: boardListController,
      child: LoadMore(
        isFinish: !widget.loadMore,
        onLoadMore: () {
          return widget.onLoadMore!(widget.index!);
        },
        child: ListView.builder(
          shrinkWrap: false,
          addAutomaticKeepAlives: true,
          padding: EdgeInsets.only(
              right: widget.padding?.right ?? 0,
              left: widget.padding?.left ?? 0),
          physics: AlwaysScrollableScrollPhysics(),
          controller: boardListController,
          itemCount: widget.items!.length,
          itemBuilder: (ctx, index) {
            var item = widget.items![index];
            return Opacity(
              opacity: (boardView.draggedItemIndex == index &&
                      boardView.draggedListIndex == widget.index)
                  ? 0.0
                  : 1,
              child: BoardItem(
                boardList: this,
                item: item.item,
                draggable: item.draggable,
                index: index,
                onDropItem: item.onDropItem,
                onTapItem: item.onTapItem,
                onDragItem: item.onDragItem,
                onStartDragItem: item.onStartDragItem,
              ),
            );
          },
        ),
      ),
    );
  }
}
