import 'BoardItemObject.dart';

class BoardListObject {
  String? title;
  List<BoardItemObject>? items;
  int? itemCount;

  BoardListObject({this.title, this.items, this.itemCount}) {
    if (this.title == null) {
      this.title = "";
    }
    if (this.items == null) {
      this.items = [];
    }
    if (this.itemCount == null) {
      this.itemCount = 0;
    }
  }
}
