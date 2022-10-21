import 'package:boardview/board_item.dart';
import 'package:boardview/board_list.dart';
import 'package:boardview/boardview.dart';
import 'package:boardview/boardview_controller.dart';
import 'package:example/BoardItemObject.dart';
import 'package:example/BoardListObject.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BoardViewExample(),
    );
  }
}

class BoardViewExample extends StatefulWidget {
  @override
  _BoardViewExampleState createState() => _BoardViewExampleState();
}

class _BoardViewExampleState extends State<BoardViewExample> {
  List<BoardListObject> _listData = [
    BoardListObject(
      title: "List title 1",
      items: List.generate(10, (index) {
        return BoardItemObject(title: "Item ${index + 1}");
      }),
      itemCount: 100,
    ),
    BoardListObject(
      title: "List title 2",
      items: List.generate(20, (index) {
        return BoardItemObject(title: "Item ${index + 1}");
      }),
      itemCount: 150,
    ),
    BoardListObject(
      title: "List title 3",
      items: List.generate(30, (index) {
        return BoardItemObject(title: "Item ${index + 1}");
      }),
      itemCount: 100,
    )
  ];

  BoardViewController boardViewController = new BoardViewController();

  @override
  Widget build(BuildContext context) {
    List<BoardList> _lists = [];
    for (int i = 0; i < _listData.length; i++) {
      _lists.add(_createBoardList(_listData[i]) as BoardList);
    }
    _lists.add(BoardList(
      onDropList: (int? listIndex, int? oldListIndex) {
        //Update our local list data
        var list = _listData[oldListIndex!];
        _listData.removeAt(oldListIndex);
        _listData.insert(listIndex!, list);
      },
      headerBackgroundColor: Color.fromARGB(255, 235, 236, 240),
      backgroundColor: Color.fromARGB(255, 235, 236, 240),
      customWidget: Container(color: Colors.red, width: 30, height: 50),
    ));
    return Scaffold(
      appBar: AppBar(
        title: Text("Board View"),
      ),
      body: BoardView(
        lists: _lists,
        margin: 16,
        width: MediaQuery.of(context).size.width - 64,
        decoration: BoxDecoration(color: Colors.red),
        boardViewController: boardViewController,
      ),
    );
  }

  Widget buildBoardItem(BoardItemObject itemObject) {
    return BoardItem(
      onStartDragItem:
          (int? listIndex, int? itemIndex, BoardItemState? state) {},
      onDropItem: (int? listIndex, int? itemIndex, int? oldListIndex,
          int? oldItemIndex, BoardItemState? state) {
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

  Widget _createBoardList(BoardListObject list) {
    List<BoardItem> items = [];
    for (int i = 0; i < list.items!.length; i++) {
      items.insert(i, buildBoardItem(list.items![i]) as BoardItem);
    }

    return BoardList(
      onStartDragList: (int? listIndex) {},
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
}
