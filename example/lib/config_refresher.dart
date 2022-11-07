import 'package:flutter/cupertino.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class RefreshHeaderIndicator extends RefreshIndicator {
  @override
  double get height => 50;

  @override
  State<StatefulWidget> createState() {
    return RefreshHeaderIndicatorState();
  }
}

class RefreshHeaderIndicatorState
    extends RefreshIndicatorState<RefreshHeaderIndicator> {
  @override
  Widget buildContent(BuildContext context, RefreshStatus mode) {
    return CupertinoActivityIndicator(
      animating: mode == RefreshStatus.refreshing,
    );
  }
}

class RefreshFooterIndicator extends LoadIndicator {
  @override
  double get height => 60;

  @override
  State<StatefulWidget> createState() {
    return RefreshFooterIndicatorState();
  }
}

class RefreshFooterIndicatorState
    extends LoadIndicatorState<RefreshFooterIndicator> {
  @override
  Widget buildContent(BuildContext context, LoadStatus mode) {
    return CupertinoActivityIndicator(
      animating: mode == LoadStatus.loading,
    );
  }
}
