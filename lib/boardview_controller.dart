import 'package:flutter/animation.dart';

import 'boardview.dart';

class BoardViewController {
  BoardViewController();

  late BoardViewState state;

  Future<void> animateTo(int index, {Duration? duration, Curve? curve}) async {
    double offset = index * (state.widget.width + state.widget.margin!);
    if (state.scrollController.hasClients) {
      state.canDrag = false;
      await state.scrollController.animateTo(offset,
          duration: duration ?? new Duration(milliseconds: 400),
          curve: curve ?? Curves.ease);
      state.canDrag = true;
    }
  }
}
