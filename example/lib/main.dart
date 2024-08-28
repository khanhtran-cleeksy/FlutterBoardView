import 'package:boardview/board_item.dart';
import 'package:boardview/board_list.dart';
import 'package:boardview/boardview.dart';
import 'package:boardview/boardview_controller.dart';
import 'package:example/BoardItemObject.dart';
import 'package:example/BoardListObject.dart';
import 'package:example/config_refresher.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshConfiguration(
      headerBuilder: () => RefreshHeaderIndicator(),
      footerBuilder: () => RefreshHeaderIndicator(),
      child: MaterialApp(
        home: BoardViewExample(),
      ),
    );
  }
}

class BoardViewExample extends StatefulWidget {
  @override
  _BoardViewExampleState createState() => _BoardViewExampleState();
}

class _BoardViewExampleState extends State<BoardViewExample>
    with AutomaticKeepAliveClientMixin<BoardViewExample> {
  List<BoardListObject> _listData = List.generate(
    3,
    (index) => BoardListObject(
      title: "List title $index",
      items: List.generate(index.isEven ? 10 : 2, (index) {
        return BoardItemObject(title: "Item ${index + 1}");
      }),
      itemCount: index.isEven ? 10 : 2,
    ),
  );

  bool _movable = false;

  BoardViewController boardViewController = new BoardViewController();
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  @mustCallSuper
  Widget build(BuildContext context) {
    super.build(context);
    List<BoardList> _lists = [];
    for (int i = 0; i < _listData.length; i++) {
      _lists.add(_createBoardList(_listData[i], i) as BoardList);
    }
    _lists.add(BoardList(
      onDropList: (int? listIndex, int? oldListIndex) {
        //Update our local list data
        var list = _listData[oldListIndex!];
        _listData.removeAt(oldListIndex);
        _listData.insert(listIndex!, list);
      },
      movable: false,
      headerBackgroundColor: Color.fromARGB(255, 235, 236, 240),
      backgroundColor: Color.fromARGB(255, 235, 236, 240),
      customWidget: Container(color: Colors.black, width: 30, height: 50),
    ));
    return Scaffold(
      appBar: AppBar(
        title: Text("Board View"),
      ),
      body: SafeArea(
        child: SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          physics: ClampingScrollPhysics(),

          // physics: ClampingScrollPhysics(),
          onRefresh: () async {
            await Future.delayed(Duration(milliseconds: 2000));
            _refreshController.refreshCompleted();
          },
          child: BoardView(
            lists: _lists,
            showBottomScrollBar: true,
            margin: 8,
            width: MediaQuery.of(context).size.width,
            boardViewController: boardViewController,
          ),
        ),
      ),
    );
  }

  Widget buildBoardItem(BoardItemObject itemObject) {
    return BoardItem(
      onStartDragItem: (int? listIndex, int? itemIndex, BoardItemState? state) {
        setState(() {
          _movable = true;
        });
      },
      onDropItem: (int? listIndex, int? itemIndex, int? oldListIndex,
          int? oldItemIndex, BoardItemState? state) {
        setState(() {
          _movable = false;
        });
        //Used to update our local item data
        var item = _listData[oldListIndex!].items![oldItemIndex!];
        _listData[oldListIndex].items!.removeAt(oldItemIndex);
        _listData[listIndex!].items!.insert(itemIndex!, item);
      },
      onTapItem:
          (int? listIndex, int? itemIndex, BoardItemState? state) async {},
      item: Card(
        child: Container(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(itemObject.title!),
          ),
        ),
      ),
    );
  }

  Widget _createBoardList(BoardListObject list, int i) {
    List<BoardItem> items = [];
    for (int i = 0; i < list.items!.length; i++) {
      items.insert(i, buildBoardItem(list.items![i]) as BoardItem);
    }

    return BoardList(
      onStartDragList: (int? listIndex) {},
      movable: !(_movable && i == 1),
      // customWidget: list.items!.length == 20
      //     ? Container(
      //         color: Colors.black,
      //         height: 1000,
      //       )
      //     : null,
      onTapList: (int? listIndex) async {},
      draggable: (items.length != 30),
      onDropList: (int? listIndex, int? oldListIndex) {
        //Update our local list data
        var list = _listData[oldListIndex!];
        _listData.removeAt(oldListIndex);
        _listData.insert(listIndex!, list);
      },
      onLoadMore: _onLoadMore,
      headerBackgroundColor: Color.fromARGB(255, 235, 236, 240),
      backgroundColor: Color.fromARGB(255, 235, 236, 240),
      header: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Text(
              list.title!,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ],
      items: items,
      loadMore: list.itemCount != null && list.items!.length < list.itemCount!,
    );

    // return BoardList(
    //   customWidget: Container(color: Colors.green, width: 50, height: 50),
    //   // footer: Container(color: Colors.green, width: 50, height: 50),
    // );
  }

  Future<bool> _onLoadMore(int listIndex) async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      final data = List.generate(10, (index) {
        return BoardItemObject(title: "Item more");
      });
      _listData[listIndex].items!.addAll(data);
    });
    return true;
  }

  @override
  bool get wantKeepAlive => true;
}
