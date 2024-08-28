import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'board_item.dart';
import 'boardview.dart';
import 'loadmore.dart';

const triggerScrollVertical = 100.0;

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
  final bool isDraggingItem;

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
    this.isDraggingItem = false,
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
  ScrollController scrollController = new ScrollController();
  final listKey = GlobalKey();
  Timer? _timer;

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
      boardView.draggedItem = item;
      boardView.onDropList = onDropList;
      boardView.run();
      if (boardView.mounted) {
        boardView.setState(() {});
      }
    }
  }

  void autoScrollDown() {
    if (_timer?.isActive == true) return;
    //
    cancelTimer();
    const timerDuration = Duration(milliseconds: 270);
    const scrollDuration = Duration(milliseconds: 250);
    _timer = Timer.periodic(timerDuration, (timer) {
      if (scrollController.offset <
          scrollController.position.maxScrollExtent - 15) {
        scrollController.animateTo(
          scrollController.offset + triggerScrollVertical,
          duration: scrollDuration,
          curve: Curves.linear,
        );
      } else {
        cancelTimer();
      }
    });
  }

  void autoScrollUp() {
    if (_timer?.isActive == true) return;
    //
    cancelTimer();
    const timerDuration = Duration(milliseconds: 270);
    const scrollDuration = Duration(milliseconds: 250);
    _timer = Timer.periodic(timerDuration, (timer) {
      if (scrollController.offset > scrollController.position.minScrollExtent) {
        scrollController.animateTo(
          scrollController.offset - triggerScrollVertical,
          duration: scrollDuration,
          curve: Curves.linear,
        );
      } else {
        cancelTimer();
      }
    });
  }

  void cancelTimer() {
    if (_timer?.isActive == true) {
      _timer?.cancel();
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
              Expanded(
                key: listKey,
                child: widget.movable
                    ? _buildMovableList(boardView)
                    : widget.immovableWidget ?? SizedBox(),
              ),
            ],
          ),
        );
  }

  Widget _buildMovableList(BoardViewState boardView) {
    //
    return CupertinoScrollbar(
      radius: const Radius.circular(10),
      controller: scrollController,
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
          controller: scrollController,
          itemCount: widget.isDraggingItem
              ? widget.items!.length + 1
              : widget.items!.length,
          itemBuilder: (ctx, index) {
            if (widget.isDraggingItem && index == widget.items!.length) {
              return BoardItem(
                boardList: this,
                item: SizedBox(
                  height: scrollController.position.viewportDimension - 150,
                ),
                draggable: false,
                index: index,
              );
            }
            var item = widget.items![index];
            return BoardItem(
              boardList: this,
              item: item.item,
              draggable: item.draggable,
              index: index,
              onStartDragItem: item.onStartDragItem,
            );
          },
        ),
      ),
    );
  }
}
