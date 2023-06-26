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
    if (widget.onDropList != null) {
      widget.onDropList!(listIndex, widget.boardView!.startListIndex);
    }
    widget.boardView!.draggedListIndex = null;
    if (widget.boardView!.mounted) {
      widget.boardView!.setState(() {});
    }
  }

  void _startDrag(Widget item, BuildContext context) {
    if (widget.boardView != null && widget.draggable) {
      if (widget.onStartDragList != null) {
        widget.onStartDragList!(widget.index);
      }
      widget.boardView!.startListIndex = widget.index;
      widget.boardView!.height = context.size!.height;
      widget.boardView!.draggedListIndex = widget.index!;
      widget.boardView!.draggedItemIndex = null;
      widget.boardView!.draggedItem = item;
      widget.boardView!.onDropList = onDropList;
      widget.boardView!.run();
      if (widget.boardView!.mounted) {
        widget.boardView!.setState(() {});
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
    if (widget.boardView!.listStates.length > widget.index!) {
      widget.boardView!.listStates.removeAt(widget.index!);
    }
    widget.boardView!.listStates.insert(widget.index!, this);

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
                    widget.boardView!.initialX = pos.dx;
                    widget.boardView!.initialY = pos.dy;

                    widget.boardView!.rightListX = pos.dx + object.size.width;
                    widget.boardView!.leftListX = pos.dx;
                  }
                },
                onTapCancel: () {},
                onLongPress: () {
                  if (!widget.boardView!.widget.isSelecting &&
                      widget.draggable) {
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
                Container(
                  child: Expanded(
                    child: widget.movable
                        ? CupertinoScrollbar(
                            radius: const Radius.circular(10),
                            child: LoadMore(
                              isFinish: !widget.loadMore,
                              onLoadMore: () {
                                return widget.onLoadMore!(widget.index!);
                              },
                              child: ListView.builder(
                                shrinkWrap: true,
                                addAutomaticKeepAlives: true,
                                padding: EdgeInsets.only(
                                    right: widget.padding?.right ?? 0,
                                    left: widget.padding?.left ?? 0),
                                physics: AlwaysScrollableScrollPhysics(),
                                controller: boardListController,
                                itemCount: widget.items!.length,
                                itemBuilder: (ctx, index) {
                                  if (widget.items![index].boardList == null ||
                                      widget.items![index].index != index ||
                                      widget.items![index].boardList!.widget
                                              .index !=
                                          widget.index ||
                                      widget.items![index].boardList != this) {
                                    widget.items![index] = BoardItem(
                                      boardList: this,
                                      item: widget.items![index].item,
                                      draggable: widget.items![index].draggable,
                                      index: index,
                                      onDropItem:
                                          widget.items![index].onDropItem,
                                      onTapItem: widget.items![index].onTapItem,
                                      onDragItem:
                                          widget.items![index].onDragItem,
                                      onStartDragItem:
                                          widget.items![index].onStartDragItem,
                                    );
                                  }
                                  return Opacity(
                                    opacity:
                                        (widget.boardView!.draggedItemIndex ==
                                                    index &&
                                                widget.boardView!
                                                        .draggedListIndex ==
                                                    widget.index)
                                            ? 0.0
                                            : 1,
                                    child: BoardItem(
                                      boardList: this,
                                      item: widget.items![index].item,
                                      draggable: widget.items![index].draggable,
                                      index: index,
                                      onDropItem:
                                          widget.items![index].onDropItem,
                                      onTapItem: widget.items![index].onTapItem,
                                      onDragItem:
                                          widget.items![index].onDragItem,
                                      onStartDragItem:
                                          widget.items![index].onStartDragItem,
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        : widget.immovableWidget ?? SizedBox(),
                  ),
                ),
            ],
          ),
        );
  }
}
