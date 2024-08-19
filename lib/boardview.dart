library boardview;

import 'dart:math';

import 'package:boardview/boardview_controller.dart';
import 'package:flutter/material.dart';
import 'dart:core';
import 'package:boardview/board_list.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

const triggerScrollHorizontal = 20.0;
const triggerScrollVertical = 70.0;

class BoardView extends StatefulWidget {
  final List<BoardList> lists;
  final double width;
  final double margin;
  final bool showBottomScrollBar;
  final BoardViewController? boardViewController;

  BoardView({
    Key? key,
    this.showBottomScrollBar = true,
    this.boardViewController,
    required this.lists,
    this.width = 350,
    required this.margin,
  }) : super(key: key);

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

  ScrollController scrollController = new ScrollController();

  List<BoardListState> listStates = [];

  OnDropItem? onDropItem;
  OnDropList? onDropList;

  bool isScrolling = false;

  var pointer;

  List<BoardList> get lists => widget.lists;
  AutoScrollController scrollBarController = AutoScrollController();

  double get scrollSinglePixels => scrollController.positions.single.pixels;

  double get width => widget.width - widget.margin * 4;

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
    var listIndex = draggedListIndex;
    var state = listStates[listIndex!];
    var itemIndex = draggedItemIndex;
    if (topItemY != null) {
      topItemY = topItemY! + state.itemStates[itemIndex! + 1].height;
    }
    if (bottomItemY != null) {
      bottomItemY = bottomItemY! + state.itemStates[itemIndex! + 1].height;
    }
    var items = lists[listIndex].items;
    var item = items![itemIndex!];
    items.removeAt(itemIndex);
    var itemState = state.itemStates[itemIndex];
    state.itemStates.removeAt(itemIndex);
    draggedItemIndex = itemIndex + 1;
    items.insert(itemIndex, item);
    state.itemStates.insert(itemIndex, itemState);
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
    var items = lists[draggedListIndex!].items;
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
    var list = lists[draggedListIndex!];
    var listState = listStates[draggedListIndex!];
    lists.removeAt(draggedListIndex!);
    listStates.removeAt(draggedListIndex!);
    if (draggedListIndex != null) {
      draggedListIndex = draggedListIndex! + 1;
    }
    lists.insert(draggedListIndex!, list);
    listStates.insert(draggedListIndex!, listState);
    canDrag = false;
    if (scrollController.hasClients) {
      int? tempListIndex = draggedListIndex;
      _animateTo(_nextPage).whenComplete(() {
        _setCurrentPos();
        _setCurrentPage(_nextPage);
        _rebuild();
        RenderBox object = _findListStateRenderObject(tempListIndex!);
        Offset pos = object.localToGlobal(Offset.zero);
        leftListX = pos.dx;
        rightListX = pos.dx + object.size.width;
        _resetCanDrag();
      });
    }
    _rebuild();
  }

  RenderBox _findListStateRenderObject(int tempListIndex) =>
      listStates[tempListIndex].context.findRenderObject() as RenderBox;

  void _setCurrentPage(int value) {
    currentPage = value;
    //
    if (widget.showBottomScrollBar)
      scrollBarController.scrollToIndex(currentPage,
          preferPosition: AutoScrollPosition.middle);
  }

  void moveRight() async {
    var items = lists[draggedListIndex!].items;
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
    if (scrollController.hasClients) {
      int? tempListIndex = draggedListIndex;
      int? tempItemIndex = draggedItemIndex;
      _animateTo(_nextPage).whenComplete(() {
        _setCurrentPos();
        _setCurrentPage(_nextPage);
        _rebuild();
        if (draggedListIndex != null &&
            lists[draggedListIndex!].movable == true) {
          RenderBox object = _findListStateRenderObject(tempListIndex!);
          Offset pos = object.localToGlobal(Offset.zero);
          leftListX = pos.dx;
          rightListX = pos.dx + object.size.width;
          RenderBox box =
              _findItemStateRenderObject(tempListIndex, tempItemIndex);
          Offset itemPos = box.localToGlobal(Offset.zero);
          topItemY = itemPos.dy;
          bottomItemY = itemPos.dy + box.size.height;
        }
        _resetCanDrag();
      });
    }
    _rebuild();
  }

  RenderBox _findItemStateRenderObject(int tempListIndex, int? tempItemIndex) {
    return listStates[tempListIndex]
        .itemStates[tempItemIndex!]
        .context
        .findRenderObject() as RenderBox;
  }

  Future<void> _animateTo(int currentIndex) {
    return scrollController.animateTo(currentIndex * (width + widget.margin),
        duration: new Duration(milliseconds: 400), curve: Curves.ease);
  }

  void _resetCanDrag() async {
    Future.delayed(Duration(milliseconds: 600), () {
      canDrag = true;
    });
  }

  void moveListLeft() {
    var list = lists[draggedListIndex!];
    var listState = listStates[draggedListIndex!];
    lists.removeAt(draggedListIndex!);
    listStates.removeAt(draggedListIndex!);
    if (draggedListIndex != null) {
      draggedListIndex = draggedListIndex! - 1;
    }
    lists.insert(draggedListIndex!, list);
    listStates.insert(draggedListIndex!, listState);
    canDrag = false;
    if (scrollController.hasClients && currentPage > 0) {
      int? tempListIndex = draggedListIndex;
      _animateTo(_previousPage).whenComplete(() {
        _setCurrentPos();
        _setCurrentPage(_previousPage);
        _rebuild();
        RenderBox object = _findListStateRenderObject(tempListIndex!);
        Offset pos = object.localToGlobal(Offset.zero);
        leftListX = pos.dx;
        rightListX = pos.dx + object.size.width;
        _resetCanDrag();
      });
    }
    _rebuild();
  }

  int get _previousPage => currentPage > 0 ? currentPage - 1 : currentPage;

  int get _nextPage => currentPage + 1;

  void moveLeft() {
    var items = lists[draggedListIndex!].items;
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
    if (scrollController.hasClients && currentPage > 0) {
      int? tempListIndex = draggedListIndex;
      int? tempItemIndex = draggedItemIndex;
      _animateTo(_previousPage).whenComplete(() {
        _setCurrentPos();
        _setCurrentPage(_previousPage);
        _rebuild();
        if (draggedListIndex != null &&
            lists[draggedListIndex!].movable == true) {
          RenderBox object = _findListStateRenderObject(tempListIndex!);
          Offset pos = object.localToGlobal(Offset.zero);
          leftListX = pos.dx;
          rightListX = pos.dx + object.size.width;
          RenderBox box =
              _findItemStateRenderObject(tempListIndex, tempItemIndex);
          Offset itemPos = box.localToGlobal(Offset.zero);
          topItemY = itemPos.dy;
          bottomItemY = itemPos.dy + box.size.height;
        }
        _resetCanDrag();
      });
    }
    _rebuild();
  }

  double currentPos = 0;
  int currentPage = 0;

  final GlobalKey boardKey = GlobalKey();
  double? boardHeight;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      if (!scrollController.hasClients) return;
      try {
        _setBoardHeight();
        if (canDrag) {
          if (scrollSinglePixels > width * .01 + currentPos) {
            canDrag = false;
            _animateTo(_nextPage).then((value) {
              _setCurrentPos();
              _setCurrentPage(_nextPage);
              canDrag = true;
              _rebuild();
            });
          } else {
            if (scrollSinglePixels < currentPos - width * .01) {
              canDrag = false;
              _animateTo(_previousPage).then((value) {
                _setCurrentPos();
                _setCurrentPage(_previousPage);
                canDrag = true;
                _rebuild();
              });
            } else {
              _animateTo(currentPage).whenComplete(() {
                _setCurrentPos();
              });
            }
          }
        }
      } catch (e) {}
    });
    Widget listWidget = ListView.builder(
      physics: ClampingScrollPhysics(),
      itemCount: lists.length,
      scrollDirection: Axis.horizontal,
      addAutomaticKeepAlives: true,
      controller: scrollController,
      itemBuilder: (BuildContext context, int index) {
        var list = lists[index];
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
            decoration: list.decoration,
            padding: list.padding,
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
            decoration: list.decoration,
            padding: list.padding,
          );
        }

        var temp = Container(
            width: width,
            margin: EdgeInsets.only(
              left: index == 0 ? widget.margin * 2 : widget.margin,
              right: index == lists.length - 1 ? widget.margin * 2 : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[Expanded(child: list)],
            ));
        return temp;
      },
    );

    List<Widget> stackWidgets = <Widget>[listWidget];

    if (initialX != null &&
        initialY != null &&
        offsetX != null &&
        offsetY != null &&
        dx != null &&
        dy != null &&
        height != null) {
      if (canDrag && dxInit != null && dyInit != null) {
        _handleDragging();
      }
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _rebuild();
      });
      stackWidgets.add(Positioned(
        width: width,
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
            _rebuild();
          }
        },
        onPointerDown: (opd) {
          RenderBox box = context.findRenderObject() as RenderBox;
          Offset pos = box.localToGlobal(opd.position);
          offsetX = pos.dx;
          offsetY = pos.dy;
          pointer = opd;
          _rebuild();
        },
        onPointerUp: (opu) {
          if (onDropItem != null) {
            int? tempDraggedItemIndex = draggedItemIndex;
            int? tempDraggedListIndex = draggedListIndex;
            onDropItem!(tempDraggedListIndex, tempDraggedItemIndex);
          }
          if (onDropList != null) {
            int? tempDraggedListIndex = draggedListIndex;

            onDropList!(tempDraggedListIndex);
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
          _rebuild();
        },
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: stackWidgets,
              ),
            ),
            if (widget.showBottomScrollBar) _buildScrollBar()
          ],
        ),
      ),
    );
  }

  void _handleDragging() {
    if (draggedItemIndex != null &&
        draggedItem != null &&
        topItemY != null &&
        bottomItemY != null) {
      _handleDraggingItem();
    } else {
      _handleDraggingList();
    }
  }

  void _handleDraggingList() {
    if ((lists.length > draggedListIndex! + 1 &&
            (lists[draggedListIndex! + 1].customWidget == null &&
                lists[draggedListIndex! + 1].draggable)) &&
        dx! > rightListX!) {
      //move right
      moveListRight();
    }

    if (0 <= draggedListIndex! - 1 && (dx! < 32)) {
      //move left
      moveListLeft();
    }
  }

  void _handleDraggingItem() {
    //move left
    if (0 <= draggedListIndex! - 1 &&
        dx! < leftListX! + triggerScrollHorizontal) {
      moveLeft();
    }
    //move right
    if ((lists.length > draggedListIndex! + 1 &&
            lists[draggedListIndex! + 1].customWidget == null) &&
        dx! > rightListX! - triggerScrollHorizontal) {
      moveRight();
    }
    var boardListController = listStates[draggedListIndex!].boardListController;
    //scroll up
    if (dy! < topListY! + triggerScrollVertical) {
      _triggerScrollDragItemUp(boardListController);
    }
    //move up
    if (0 <= draggedItemIndex! - 1 &&
        dy! <
            topItemY! -
                listStates[draggedListIndex!]
                        .itemStates[draggedItemIndex! - 1]
                        .height /
                    2) {
      moveUp();
    }
    double? tempBottom = bottomListY;
    //scroll down
    if (dy! > tempBottom! - triggerScrollVertical) {
      _triggerScrollDragItemDown(boardListController);
    }
    //move down
    if (lists[draggedListIndex!].items!.length > draggedItemIndex! + 1 &&
        dy! >
            bottomItemY! +
                listStates[draggedListIndex!]
                        .itemStates[draggedItemIndex! + 1]
                        .height /
                    2) {
      moveDown();
    }
  }

  void _triggerScrollDragItemUp(ScrollController boardListController) {
    if (!boardListController.hasClients) return;
    if (isScrolling) return;
    double pos = boardListController.position.pixels;
    if (pos <= -5) return;
    isScrolling = true;
    boardListController
        .animateTo(max(pos - 5, -5),
            duration: new Duration(milliseconds: 10), curve: Curves.ease)
        .whenComplete(() {
      pos -= boardListController.position.pixels;
      if (initialY == null) initialY = 0;
      isScrolling = false;
      if (topItemY != null) {
        topItemY = topItemY! + pos;
      }
      if (bottomItemY != null) {
        bottomItemY = bottomItemY! + pos;
      }
      _rebuild();
    });
  }

  void _triggerScrollDragItemDown(ScrollController boardListController) {
    if (!boardListController.hasClients) return;
    if (isScrolling) return;
    double pos = boardListController.position.pixels;
    double maxExtent = boardListController.position.maxScrollExtent;
    if (pos >= maxExtent) return;
    isScrolling = true;

    boardListController
        .animateTo(min(pos + 5, maxExtent + 5),
            duration: new Duration(milliseconds: 10), curve: Curves.ease)
        .whenComplete(() {
      pos -= boardListController.position.pixels;
      if (initialY == null) initialY = 0;
      isScrolling = false;
      if (topItemY != null) {
        topItemY = topItemY! + pos;
      }
      if (bottomItemY != null) {
        bottomItemY = bottomItemY! + pos;
      }
      _rebuild();
    });
  }

  void _setCurrentPos() {
    if (!scrollController.hasClients) return;
    currentPos = scrollSinglePixels;
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Widget _buildScrollBar() {
    final length =
        lists.length - lists.where((e) => e.customWidget != null).length;
    final barLength = length > 5 ? 5 : length;

    final itemSize = 11.0;
    return SizedBox(
      height: 30,
      width: itemSize * barLength,
      child: ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        controller: scrollBarController,
        scrollDirection: Axis.horizontal,
        itemCount: length,
        itemBuilder: (context, index) {
          final isHighlight = currentPage == index;
          final double dotSize = isHighlight ? 7 : 5;
          return AutoScrollTag(
            key: ValueKey(index),
            controller: scrollBarController,
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
    _rebuild();
  }

  void run() {
    if (pointer != null) {
      dx = pointer.position.dx;
      dy = pointer.position.dy;
      _rebuild();
    }
  }
}
