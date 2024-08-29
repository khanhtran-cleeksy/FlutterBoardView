import 'package:flutter/animation.dart';

import 'package:boardview/boardview.dart';

class BoardViewController {
  BoardViewController();

  late BoardViewState state;

  Future<void> animateTo(int index, {Duration? duration, Curve? curve}) async {
    final double offset = index * (state.width + state.widget.margin);
    if (state.scrollController.hasClients) {
      state.canDrag = false;
      await state.scrollController.animateTo(offset,
          duration: duration ?? const Duration(milliseconds: 400),
          curve: curve ?? Curves.ease);
      state.canDrag = true;
    }
  }
}
