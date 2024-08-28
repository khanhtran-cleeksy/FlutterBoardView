library boardview;

import 'package:boardview/board_item.dart';
import 'package:boardview/boardview_controller.dart';
import 'package:flutter/material.dart';
import 'dart:core';
import 'package:boardview/board_list.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

const triggerScrollHorizontal = 20.0;

class BoardView extends StatefulWidget {
  final List<BoardList> lists;
  final double width;
  final double margin;
  final bool showBottomScrollBar;
  final BoardViewController? boardViewController;
  final OnDropItem? onDropItem;
  BoardView({
    Key? key,
    this.showBottomScrollBar = true,
    this.boardViewController,
    required this.lists,
    this.width = 350,
    required this.margin,
    required this.onDropItem,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return BoardViewState();
  }
}

typedef void OnDropBottomWidget(
    int? listIndex, int? itemIndex, double percentX);

typedef void OnDropItem(int? listIndex, int? itemIndex, int? oldListIndex,
    int? oldItemIndex, BoardItemState state);
typedef void OnDropList(int? listIndex);

class BoardViewState extends State<BoardView>
    with AutomaticKeepAliveClientMixin<BoardView> {
  Widget? draggedItem;
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
  double? height;
  int? startListIndex;
  int? startItemIndex;

  bool canDrag = true;

  ScrollController scrollController = new ScrollController();

  List<BoardListState> listStates = [];

  OnDropList? onDropList;

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
            isDraggingItem: isDraggingItem,
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
            isDraggingItem: isDraggingItem,
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
          draggedListIndex = null;
          onDropList = null;
          dxInit = null;
          dyInit = null;
          leftListX = null;
          rightListX = null;
          topListY = null;
          bottomListY = null;
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
    _handleDraggingList();
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

  bool isMovingToList = false;

  BoardListState? targetList;
  bool isDraggingItem = false;

  void onItemPointerMove(PointerMoveEvent event) {
    _moveToList(int page) {
      if (scrollController.hasClients) {
        isMovingToList = true;
        _animateTo(page).whenComplete(() {
          _setCurrentPos();
          _setCurrentPage(page);
          _rebuild();
          Future.delayed(Duration(milliseconds: 500)).then(
            (value) => isMovingToList = false,
          );
        });
      }
    }

    if (isMovingToList) return;
    //
    final listWidth = widget.width;
    final trigger = widget.margin * 4 + triggerScrollHorizontal;
    final dx = event.position.dx;
    if ((lists.length > currentPage + 1 &&
            lists[currentPage + 1].customWidget == null) &&
        dx > listWidth - trigger) {
      _moveToList(_nextPage);
    }
    if (currentPage - 1 >= 0 && dx < trigger) {
      _moveToList(_previousPage);
    }
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

  void setTargetList(int stageIndex) {
    targetList = listStates[stageIndex];
  }

  void onItemPointerMoveList(PointerMoveEvent event) {
    if (targetList == null) return;
    final box =
        targetList!.listKey.currentContext!.findRenderObject() as RenderBox;
    final listHeight = box.size.height;
    final listDyOffset = box.localToGlobal(Offset.zero).dy;
    final itemPos = event.position.dy - listDyOffset;
    //
    if (itemPos >= listHeight) {
      return targetList!.autoScrollDown();
    }
    if (itemPos < 0) {
      return targetList!.autoScrollUp();
    }
    targetList!.cancelTimer();
  }

  void setIsDraggingItem(bool dragging) {
    if (isDraggingItem != dragging) {
      isDraggingItem = dragging;
      setState(() {});
    }
  }

  void onItemPointerUp() {
    if (targetList == null) return;
    targetList!.cancelTimer();
  }
}
