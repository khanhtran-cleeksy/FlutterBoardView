library boardview;

import 'package:boardview/boardview_controller.dart';
import 'package:flutter/material.dart';
import 'dart:core';
import 'package:boardview/board_list.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class BoardView extends StatefulWidget {
  final List<BoardList> lists;
  final double width;
  final Widget? middleWidget;
  final double? bottomPadding;
  final bool isSelecting;
  final double? margin;
  final EdgeInsets? padding;
  final Decoration? decoration;
  final bool scrollbar;
  final BoardViewController? boardViewController;
  final int dragDelay;
  final Function(bool)? itemInMiddleWidget;
  final OnDropBottomWidget? onDropItemInMiddleWidget;

  BoardView(
      {Key? key,
      this.itemInMiddleWidget,
      this.scrollbar = true,
      this.boardViewController,
      this.dragDelay = 600,
      this.onDropItemInMiddleWidget,
      this.isSelecting = false,
      required this.lists,
      this.width = 350,
      this.decoration,
      this.margin,
      this.middleWidget,
      this.padding,
      this.bottomPadding})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return BoardViewState();
  }
}

typedef void OnDropBottomWidget(
    int? listIndex, int? itemIndex, double percentX);
typedef void OnDropItem(int? listIndex, int? itemIndex);
typedef void OnDropList(int? listIndex);

class BoardViewState extends State<BoardView>
    with AutomaticKeepAliveClientMixin<BoardView> {
  Widget? draggedItem;
  int? draggedItemIndex;
  int? draggedListIndex;
  double? dx;
  double? dxInit;
  double? dyInit;
  double? dy;
  double? offsetX;
  double? offsetY;
  double? initialX = 0;
  double? initialY = 0;
  double? rightListX;
  double? leftListX;
  double? topListY;
  double? bottomListY;
  double? topItemY;
  double? bottomItemY;
  double? height;
  int? startListIndex;
  int? startItemIndex;

  bool canDrag = true;

  ScrollController boardViewController = new ScrollController();

  List<BoardListState> listStates = [];

  OnDropItem? onDropItem;
  OnDropList? onDropList;

  bool isScrolling = false;

  bool _isInWidget = false;

  GlobalKey _middleWidgetKey = GlobalKey();

  var pointer;

  List<BoardList> get boardList => widget.lists;
  AutoScrollController _controller = AutoScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.boardViewController != null) {
      widget.boardViewController!.state = this;
    }
  }

  void moveDown() {
    var state = listStates[draggedListIndex!];
    if (topItemY != null) {
      topItemY = topItemY! + state.itemStates[draggedItemIndex! + 1].height;
    }
    if (bottomItemY != null) {
      bottomItemY =
          bottomItemY! + state.itemStates[draggedItemIndex! + 1].height;
    }
    var items = boardList[draggedListIndex!].items;
    var item = items![draggedItemIndex!];
    items.removeAt(draggedItemIndex!);
    var itemState = state.itemStates[draggedItemIndex!];
    state.itemStates.removeAt(draggedItemIndex!);
    if (draggedItemIndex != null) {
      draggedItemIndex = draggedItemIndex! + 1;
    }
    items.insert(draggedItemIndex!, item);
    state.itemStates.insert(draggedItemIndex!, itemState);
    if (state.mounted) {
      state.setState(() {});
    }
  }

  void moveUp() {
    var state = listStates[draggedListIndex!];
    if (topItemY != null) {
      topItemY = topItemY! - state.itemStates[draggedItemIndex! - 1].height;
    }
    if (bottomItemY != null) {
      bottomItemY =
          bottomItemY! - state.itemStates[draggedItemIndex! - 1].height;
    }
    var items = boardList[draggedListIndex!].items;
    var item = items![draggedItemIndex!];
    items.removeAt(draggedItemIndex!);
    var itemState = state.itemStates[draggedItemIndex!];
    state.itemStates.removeAt(draggedItemIndex!);
    if (draggedItemIndex != null) {
      draggedItemIndex = draggedItemIndex! - 1;
    }
    items.insert(draggedItemIndex!, item);
    state.itemStates.insert(draggedItemIndex!, itemState);
    if (state.mounted) {
      state.setState(() {});
    }
  }

  void moveListRight() {
    var list = boardList[draggedListIndex!];
    var listState = listStates[draggedListIndex!];
    boardList.removeAt(draggedListIndex!);
    listStates.removeAt(draggedListIndex!);
    if (draggedListIndex != null) {
      draggedListIndex = draggedListIndex! + 1;
    }
    boardList.insert(draggedListIndex!, list);
    listStates.insert(draggedListIndex!, listState);
    canDrag = false;
    if (boardViewController.hasClients) {
      int? tempListIndex = draggedListIndex;
      boardViewController
          .animateTo((currentPage + 1) * (widget.width + widget.margin!),
              duration: new Duration(milliseconds: 400), curve: Curves.ease)
          .whenComplete(() {
        currentPos = boardViewController.positions.single.pixels;
        _setCurrentPage(currentPage + 1);
        setState(() {});
        RenderBox object =
            listStates[tempListIndex!].context.findRenderObject() as RenderBox;
        Offset pos = object.localToGlobal(Offset.zero);
        leftListX = pos.dx;
        rightListX = pos.dx + object.size.width;
        Future.delayed(new Duration(milliseconds: widget.dragDelay), () {
          canDrag = true;
        });
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _setCurrentPage(int value) {
    currentPage = value;
    //
    if (widget.scrollbar)
      _controller.scrollToIndex(currentPage,
          preferPosition: AutoScrollPosition.middle);
  }

  void moveRight() async {
    var items = boardList[draggedListIndex!].items;
    var item = items![draggedItemIndex!];
    var state = listStates[draggedListIndex!];
    var itemStates = state.itemStates;
    var itemState = itemStates[draggedItemIndex!];
    items.removeAt(draggedItemIndex!);
    itemStates.removeAt(draggedItemIndex!);
    if (state.mounted) {
      state.setState(() {});
    }
    if (draggedListIndex != null) {
      draggedListIndex = draggedListIndex! + 1;
    }
    double closestValue = 10000;
    draggedItemIndex = 0;
    for (int i = 0; i < itemStates.length; i++) {
      if (itemStates[i].mounted) {
        RenderBox box = itemStates[i].context.findRenderObject() as RenderBox;
        Offset pos = box.localToGlobal(Offset.zero);
        var temp = (pos.dy - dy! + (box.size.height / 2)).abs();
        if (temp < closestValue) {
          closestValue = temp;
          draggedItemIndex = i;
          dyInit = dy;
        }
      }
    }
    items.insert(draggedItemIndex!, item);
    itemStates.insert(draggedItemIndex!, itemState);
    canDrag = false;
    if (state.mounted) {
      state.setState(() {});
    }
    if (boardViewController.hasClients) {
      int? tempListIndex = draggedListIndex;
      int? tempItemIndex = draggedItemIndex;
      boardViewController
          .animateTo((currentPage + 1) * (widget.width + widget.margin!),
              duration: new Duration(milliseconds: 400), curve: Curves.ease)
          .whenComplete(() async {
        currentPos = boardViewController.positions.single.pixels;
        _setCurrentPage(currentPage + 1);
        setState(() {});
        if (draggedListIndex != null &&
            boardList[draggedListIndex!].movable == true) {
          RenderBox object = listStates[tempListIndex!]
              .context
              .findRenderObject() as RenderBox;
          Offset pos = object.localToGlobal(Offset.zero);
          leftListX = pos.dx;
          rightListX = pos.dx + object.size.width;
          RenderBox box = listStates[tempListIndex]
              .itemStates[tempItemIndex!]
              .context
              .findRenderObject() as RenderBox;
          Offset itemPos = box.localToGlobal(Offset.zero);
          topItemY = itemPos.dy;
          bottomItemY = itemPos.dy + box.size.height;
        }
        await Future.delayed(new Duration(milliseconds: widget.dragDelay), () {
          canDrag = true;
        });
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  void moveListLeft() {
    var list = boardList[draggedListIndex!];
    var listState = listStates[draggedListIndex!];
    boardList.removeAt(draggedListIndex!);
    listStates.removeAt(draggedListIndex!);
    if (draggedListIndex != null) {
      draggedListIndex = draggedListIndex! - 1;
    }
    boardList.insert(draggedListIndex!, list);
    listStates.insert(draggedListIndex!, listState);
    canDrag = false;
    if (boardViewController.hasClients && currentPage > 0) {
      int? tempListIndex = draggedListIndex;
      boardViewController
          .animateTo((currentPage - 1) * (widget.width + widget.margin!),
              duration: new Duration(milliseconds: 400), curve: Curves.ease)
          .then((value) {
        currentPos = boardViewController.positions.single.pixels;
        _setCurrentPage(currentPage > 0 ? currentPage - 1 : currentPage);
        setState(() {});
        RenderBox object =
            listStates[tempListIndex!].context.findRenderObject() as RenderBox;
        Offset pos = object.localToGlobal(Offset.zero);
        leftListX = pos.dx;
        rightListX = pos.dx + object.size.width;
        Future.delayed(new Duration(milliseconds: widget.dragDelay), () {
          canDrag = true;
        });
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  void moveLeft() {
    var items = boardList[draggedListIndex!].items;
    var item = items![draggedItemIndex!];
    var state = listStates[draggedListIndex!];
    var itemState = state.itemStates[draggedItemIndex!];
    items.removeAt(draggedItemIndex!);
    state.itemStates.removeAt(draggedItemIndex!);
    if (state.mounted) {
      state.setState(() {});
    }
    if (draggedListIndex != null) {
      draggedListIndex = draggedListIndex! - 1;
    }
    double closestValue = 10000;
    draggedItemIndex = 0;
    for (int i = 0; i < state.itemStates.length; i++) {
      if (state.itemStates[i].mounted) {
        RenderBox box =
            state.itemStates[i].context.findRenderObject() as RenderBox;
        Offset pos = box.localToGlobal(Offset.zero);
        var temp = (pos.dy - dy! + (box.size.height / 2)).abs();
        if (temp < closestValue) {
          closestValue = temp;
          draggedItemIndex = i;
          dyInit = dy;
        }
      }
    }
    items.insert(draggedItemIndex!, item);
    state.itemStates.insert(draggedItemIndex!, itemState);
    canDrag = false;
    if (state.mounted) {
      state.setState(() {});
    }
    if (boardViewController.hasClients && currentPage > 0) {
      int? tempListIndex = draggedListIndex;
      int? tempItemIndex = draggedItemIndex;
      boardViewController
          .animateTo((currentPage - 1) * (widget.width + widget.margin!),
              duration: new Duration(milliseconds: 400), curve: Curves.ease)
          .whenComplete(() {
        currentPos = boardViewController.positions.single.pixels;
        _setCurrentPage(currentPage > 0 ? currentPage - 1 : currentPage);
        setState(() {});
        if (draggedListIndex != null &&
            boardList[draggedListIndex!].movable == true) {
          RenderBox object = listStates[tempListIndex!]
              .context
              .findRenderObject() as RenderBox;
          Offset pos = object.localToGlobal(Offset.zero);
          leftListX = pos.dx;
          rightListX = pos.dx + object.size.width;
          RenderBox box = listStates[tempListIndex]
              .itemStates[tempItemIndex!]
              .context
              .findRenderObject() as RenderBox;
          Offset itemPos = box.localToGlobal(Offset.zero);
          topItemY = itemPos.dy;
          bottomItemY = itemPos.dy + box.size.height;
        }
        Future.delayed(new Duration(milliseconds: widget.dragDelay), () {
          canDrag = true;
        });
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  bool shown = true;
  double currentPos = 0;
  int currentPage = 0;

  final GlobalKey boardKey = GlobalKey();
  double? boardHeight;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (boardViewController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        try {
          _setBoardHeight();
          if (canDrag) {
            if (boardViewController.positions.single.pixels >
                (widget.width) * .01 + currentPos) {
              canDrag = false;
              boardViewController
                  .animateTo(
                      (currentPage + 1) * (widget.width + widget.margin!),
                      duration: new Duration(milliseconds: 300),
                      curve: Curves.ease)
                  .then((value) {
                currentPos = boardViewController.positions.single.pixels;
                _setCurrentPage(currentPage + 1);
                canDrag = true;
                setState(() {});
              });
            } else {
              if (boardViewController.positions.single.pixels <
                  currentPos - (widget.width) * .01) {
                canDrag = false;
                boardViewController
                    .animateTo(
                        (currentPage - 1) * (widget.width + widget.margin!),
                        duration: new Duration(milliseconds: 300),
                        curve: Curves.ease)
                    .then((value) {
                  currentPos = boardViewController.positions.single.pixels;
                  _setCurrentPage(
                      currentPage > 0 ? currentPage - 1 : currentPage);
                  canDrag = true;
                  setState(() {});
                });
              } else {
                boardViewController
                    .animateTo((currentPage) * (widget.width + widget.margin!),
                        duration: new Duration(milliseconds: 300),
                        curve: Curves.ease)
                    .then((value) {
                  currentPos = boardViewController.positions.single.pixels;
                });
              }
            }
          }
        } catch (e) {}
        bool _shown = boardViewController.position.maxScrollExtent != 0;
        if (_shown != shown) {
          setState(() {
            shown = _shown;
          });
        }
      });
    }
    Widget listWidget = ListView.builder(
      physics: ClampingScrollPhysics(),
      itemCount: boardList.length,
      scrollDirection: Axis.horizontal,
      addAutomaticKeepAlives: true,
      controller: boardViewController,
      itemBuilder: (BuildContext context, int index) {
        var list = boardList[index];
        if (list.boardView == null) {
          list = BoardList(
            items: list.items,
            loadMore: list.loadMore,
            headerBackgroundColor: list.headerBackgroundColor,
            backgroundColor: list.backgroundColor,
            footer: list.footer,
            header: list.header,
            boardView: this,
            movable: list.movable,
            draggable: list.draggable,
            onDropList: list.onDropList,
            onTapList: list.onTapList,
            immovableWidget: list.immovableWidget,
            onStartDragList: list.onStartDragList,
            onLoadMore: list.onLoadMore,
            customWidget: list.customWidget,
            decoration: list.decoration ?? widget.decoration,
            padding: list.padding ?? widget.padding,
          );
        }
        if (list.index != index) {
          list = BoardList(
            items: list.items,
            loadMore: list.loadMore,
            headerBackgroundColor: list.headerBackgroundColor,
            backgroundColor: list.backgroundColor,
            footer: list.footer,
            header: list.header,
            movable: list.movable,
            immovableWidget: list.immovableWidget,
            boardView: this,
            draggable: list.draggable,
            index: index,
            onDropList: list.onDropList,
            onTapList: list.onTapList,
            onStartDragList: list.onStartDragList,
            onLoadMore: list.onLoadMore,
            customWidget: list.customWidget,
            decoration: list.decoration ?? widget.decoration,
            padding: list.padding ?? widget.padding,
          );
        }

        var temp = Container(
            width: widget.width,
            padding: EdgeInsets.fromLTRB(0, 0, 0, widget.bottomPadding ?? 0),
            margin: EdgeInsets.fromLTRB(
                index == 0
                    ? widget.margin != null
                        ? widget.margin! * 2
                        : 32
                    : widget.margin ?? 16,
                0,
                index == boardList.length - 1
                    ? widget.margin != null
                        ? widget.margin! * 2
                        : 32
                    : 0,
                0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[Expanded(child: list)],
            ));
        if (draggedListIndex == index && draggedItemIndex == null) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            width: widget.width,
            padding: EdgeInsets.fromLTRB(0, 0, 0, widget.bottomPadding ?? 0),
            margin: EdgeInsets.fromLTRB(
                index == 0
                    ? widget.margin != null
                        ? widget.margin! * 2
                        : 32
                    : widget.margin ?? 16,
                0,
                index == boardList.length - 1
                    ? widget.margin != null
                        ? widget.margin! * 2
                        : 32
                    : 0,
                0),
            child: Opacity(
              opacity: 0.0,
              child: temp,
            ),
          );
        } else {
          return temp;
        }
      },
    );

    List<Widget> stackWidgets = <Widget>[listWidget];
    bool isInBottomWidget = false;
    if (dy != null) {
      if (MediaQuery.of(context).size.height - dy! < 80) {
        isInBottomWidget = true;
      }
    }
    if (widget.itemInMiddleWidget != null && _isInWidget != isInBottomWidget) {
      widget.itemInMiddleWidget!(isInBottomWidget);
      _isInWidget = isInBottomWidget;
    }
    if (initialX != null &&
        initialY != null &&
        offsetX != null &&
        offsetY != null &&
        dx != null &&
        dy != null &&
        height != null) {
      if (canDrag && dxInit != null && dyInit != null && !isInBottomWidget) {
        if (draggedItemIndex != null &&
            draggedItem != null &&
            topItemY != null &&
            bottomItemY != null) {
          //dragging item
          if (0 <= draggedListIndex! - 1 && dx! < leftListX! + 45) {
            //scroll left
            if (boardViewController.hasClients) {
              boardViewController.animateTo(
                  boardViewController.position.pixels - 5,
                  duration: new Duration(milliseconds: 10),
                  curve: Curves.ease);
              if (listStates[draggedListIndex!].mounted) {
                RenderBox object = listStates[draggedListIndex!]
                    .context
                    .findRenderObject() as RenderBox;
                Offset pos = object.localToGlobal(Offset.zero);
                leftListX = pos.dx;
                rightListX = pos.dx + object.size.width;
              }
            }
          }
          if (boardList.length > draggedListIndex! + 1 &&
              dx! > rightListX! - 45) {
            //scroll right
            if (boardViewController.hasClients) {
              boardViewController.animateTo(
                  boardViewController.position.pixels + 5,
                  duration: new Duration(milliseconds: 10),
                  curve: Curves.ease);
              if (listStates[draggedListIndex!].mounted) {
                RenderBox object = listStates[draggedListIndex!]
                    .context
                    .findRenderObject() as RenderBox;
                Offset pos = object.localToGlobal(Offset.zero);
                leftListX = pos.dx;
                rightListX = pos.dx + object.size.width;
              }
            }
          }
          if (0 <= draggedListIndex! - 1 &&
              (dx! < leftListX! &&
                  dx! < MediaQuery.of(context).size.width / 2)) {
            //move left
            moveLeft();
          }
          if (((boardList.length > draggedListIndex! + 1 &&
                      boardList[draggedListIndex! + 1].customWidget == null) &&
                  dx! > rightListX!) &&
              (dx! > MediaQuery.of(context).size.width / 2)) {
            //move right
            moveRight();
          }
          if (dy! < topListY! + 70) {
            //scroll up
            if (listStates[draggedListIndex!].boardListController.hasClients &&
                !isScrolling) {
              isScrolling = true;
              double pos = listStates[draggedListIndex!]
                  .boardListController
                  .position
                  .pixels;
              listStates[draggedListIndex!]
                  .boardListController
                  .animateTo(
                      listStates[draggedListIndex!]
                              .boardListController
                              .position
                              .pixels -
                          5,
                      duration: new Duration(milliseconds: 10),
                      curve: Curves.ease)
                  .whenComplete(() {
                pos -= listStates[draggedListIndex!]
                    .boardListController
                    .position
                    .pixels;
                if (initialY == null) initialY = 0;
//                if(widget.boardViewController != null) {
//                  initialY -= pos;
//                }
                isScrolling = false;
                if (topItemY != null) {
                  topItemY = topItemY! + pos;
                }
                if (bottomItemY != null) {
                  bottomItemY = bottomItemY! + pos;
                }
                if (mounted) {
                  setState(() {});
                }
              });
            }
          }
          if (0 <= draggedItemIndex! - 1 &&
              dy! <
                  topItemY! -
                      listStates[draggedListIndex!]
                              .itemStates[draggedItemIndex! - 1]
                              .height /
                          2) {
            //move up
            moveUp();
          }
          double? tempBottom = bottomListY;
          if (widget.middleWidget != null) {
            if (_middleWidgetKey.currentContext != null) {
              RenderBox _box = _middleWidgetKey.currentContext!
                  .findRenderObject() as RenderBox;
              tempBottom = _box.size.height;
            }
          }
          if (dy! > tempBottom! - 70) {
            //scroll down

            if (listStates[draggedListIndex!].boardListController.hasClients) {
              isScrolling = true;
              double pos = listStates[draggedListIndex!]
                  .boardListController
                  .position
                  .pixels;
              listStates[draggedListIndex!]
                  .boardListController
                  .animateTo(
                      listStates[draggedListIndex!]
                              .boardListController
                              .position
                              .pixels +
                          5,
                      duration: new Duration(milliseconds: 10),
                      curve: Curves.ease)
                  .whenComplete(() {
                pos -= listStates[draggedListIndex!]
                    .boardListController
                    .position
                    .pixels;
                if (initialY == null) initialY = 0;
//                if(widget.boardViewController != null) {
//                  initialY -= pos;
//                }
                isScrolling = false;
                if (topItemY != null) {
                  topItemY = topItemY! + pos;
                }
                if (bottomItemY != null) {
                  bottomItemY = bottomItemY! + pos;
                }
                if (mounted) {
                  setState(() {});
                }
              });
            }
          }
          if (boardList[draggedListIndex!].items!.length >
                  draggedItemIndex! + 1 &&
              listStates[draggedListIndex!].itemStates.length >
                  draggedItemIndex! + 1 &&
              dy! >
                  bottomItemY! +
                      listStates[draggedListIndex!]
                              .itemStates[draggedItemIndex! + 1]
                              .height /
                          2) {
            //move down
            moveDown();
          }
        } else {
          //dragging list
          if (0 <= draggedListIndex! - 1 && dx! < leftListX! + 45) {
            //scroll left
            if (boardViewController.hasClients) {
              boardViewController.animateTo(
                  boardViewController.position.pixels - 5,
                  duration: new Duration(milliseconds: 10),
                  curve: Curves.ease);
              if (leftListX != null) {
                leftListX = leftListX! + 5;
              }
              if (rightListX != null) {
                rightListX = rightListX! + 5;
              }
            }
          }

          if (boardList.length > draggedListIndex! + 1 &&
              dx! > rightListX! - 45) {
            //scroll right
            if (boardViewController.hasClients) {
              boardViewController.animateTo(
                  boardViewController.position.pixels + 5,
                  duration: new Duration(milliseconds: 10),
                  curve: Curves.ease);
              if (leftListX != null) {
                leftListX = leftListX! - 5;
              }
              if (rightListX != null) {
                rightListX = rightListX! - 5;
              }
            }
          }
          if ((boardList.length > draggedListIndex! + 1 &&
                  (boardList[draggedListIndex! + 1].customWidget == null &&
                      boardList[draggedListIndex! + 1].draggable)) &&
              dx! > rightListX!) {
            //move right
            moveListRight();
          }

          if (0 <= draggedListIndex! - 1 && (dx! < 32)) {
            //move left
            moveListLeft();
          }
        }
      }
      if (widget.middleWidget != null) {
        stackWidgets
            .add(Container(key: _middleWidgetKey, child: widget.middleWidget));
      }
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) {
          setState(() {});
        }
      });
      stackWidgets.add(Positioned(
        width: widget.width - 24,
        height: height,
        child: draggedItem!,
        left: (dx! - offsetX!) + initialX!,
        top: (dy! - offsetY!) + initialY!,
      ));
    }

    return SizedBox(
        height: boardHeight,
        key: boardKey,
        child: Listener(
            onPointerMove: (opm) {
              if (draggedItem != null) {
                if (dxInit == null) {
                  dxInit = opm.position.dx;
                }
                if (dyInit == null) {
                  dyInit = opm.position.dy;
                }
                dx = opm.position.dx;
                dy = opm.position.dy;
                if (mounted) {
                  setState(() {});
                }
              }
            },
            onPointerDown: (opd) {
              RenderBox box = context.findRenderObject() as RenderBox;
              Offset pos = box.localToGlobal(opd.position);
              offsetX = pos.dx;
              offsetY = pos.dy;
              pointer = opd;
              if (mounted) {
                setState(() {});
              }
            },
            onPointerUp: (opu) {
              if (onDropItem != null) {
                int? tempDraggedItemIndex = draggedItemIndex;
                int? tempDraggedListIndex = draggedListIndex;
                int? startDraggedItemIndex = startItemIndex;
                int? startDraggedListIndex = startListIndex;

                if (_isInWidget && widget.onDropItemInMiddleWidget != null) {
                  onDropItem!(startDraggedListIndex, startDraggedItemIndex);
                  widget.onDropItemInMiddleWidget!(
                      startDraggedListIndex,
                      startDraggedItemIndex,
                      opu.position.dx / MediaQuery.of(context).size.width);
                } else {
                  onDropItem!(tempDraggedListIndex, tempDraggedItemIndex);
                }
              }
              if (onDropList != null) {
                int? tempDraggedListIndex = draggedListIndex;
                if (_isInWidget && widget.onDropItemInMiddleWidget != null) {
                  onDropList!(tempDraggedListIndex);
                  widget.onDropItemInMiddleWidget!(tempDraggedListIndex, null,
                      opu.position.dx / MediaQuery.of(context).size.width);
                } else {
                  onDropList!(tempDraggedListIndex);
                }
              }
              draggedItem = null;
              offsetX = null;
              offsetY = null;
              initialX = null;
              initialY = null;
              dx = null;
              dy = null;
              draggedItemIndex = null;
              draggedListIndex = null;
              onDropItem = null;
              onDropList = null;
              dxInit = null;
              dyInit = null;
              leftListX = null;
              rightListX = null;
              topListY = null;
              bottomListY = null;
              topItemY = null;
              bottomItemY = null;
              startListIndex = null;
              startItemIndex = null;
              if (mounted) {
                setState(() {});
              }
            },
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: stackWidgets,
                  ),
                ),
                if (widget.scrollbar == true) _buildScrollBar()
              ],
            )));
  }

  Widget _buildScrollBar() {
    final length = boardList.length -
        boardList.where((e) => e.customWidget != null).length;
    final barLength = length > 5 ? 5 : length;

    final itemSize = 11.0;
    return SizedBox(
      height: 30,
      width: itemSize * barLength,
      child: ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        controller: _controller,
        scrollDirection: Axis.horizontal,
        itemCount: length,
        itemBuilder: (context, index) {
          final isHighlight = currentPage == index;
          final double dotSize = isHighlight ? 7 : 5;
          return AutoScrollTag(
            key: ValueKey(index),
            controller: _controller,
            index: index,
            child: Container(
              height: itemSize,
              width: itemSize,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isHighlight ? Color(0xFFA3AABB) : Color(0xFFD7DBE4),
                  borderRadius: BorderRadius.circular(100),
                ),
                height: dotSize,
                width: dotSize,
              ),
            ),
          );
        },
      ),
    );
  }

  ///This method to set height for Board View to improve performance
  ///Because of Widget with specific height perform better than Expanded by default
  void _setBoardHeight() async {
    final isKeyboardOpen = View.of(context).viewInsets.bottom != 0.0;
    //if isKeyboardOpen, return and wait for next frame run this method automatically
    if (isKeyboardOpen) return;
    if (boardHeight != null) return;
    if (boardKey.currentContext == null) return;
    //
    final box = boardKey.currentContext?.findRenderObject() as RenderBox?;
    final newHeight = box?.size.height;
    boardHeight = newHeight;
    setState(() {});
  }

  void run() {
    if (pointer != null) {
      dx = pointer.position.dx;
      dy = pointer.position.dy;
      if (mounted) {
        setState(() {});
      }
    }
  }
}
