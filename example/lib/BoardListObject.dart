import 'package:example/BoardItemObject.dart';

class BoardListObject {
  String? title;
  List<BoardItemObject>? items;
  int? itemCount;

  BoardListObject({this.title, this.items, this.itemCount}) {
    title ??= "";
    items ??= [];
    itemCount ??= 0;
  }
}
