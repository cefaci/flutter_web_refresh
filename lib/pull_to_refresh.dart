import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Fixed issue: https://github.com/flutter/flutter/issues/39389
class DragGesturePullToRefresh extends VerticalDragGestureRecognizer {
  static const int exceedsLoadingTime = 3000;

  late BuildContext _context;
  late WebViewController _controller;

  // loading
  Completer<void> completer = Completer<void>();
  late int msWaitToRestart;
  int  msLoading = 0;
  bool isLoading = true;

  // drag
  int    dragStartYDiff = 0;
  double dragHeightEnd = 200;
  bool   dragStarted = false;
  double dragDistance = 0;

  @override
  //override rejectGesture here
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }

  void _clearDrag() {
    dragStarted = false;
    dragDistance = 0;
  }

  /// [context] RefreshIndicator
  DragGesturePullToRefresh setContext(BuildContext context) { _context = context; return this; }
  /// [controller] WebViewController
  DragGesturePullToRefresh setController(WebViewController controller) { _controller = controller; return this; }

  /// [dragHeightEnd] End height for starting the refresh
  DragGesturePullToRefresh setDragHeightEnd(double value)      { dragHeightEnd = value;   return this; }
  /// [msWaitToRestart] milliseconds to reallow pull to refresh if the website
  /// didn't load in msWaitToRestart time
  DragGesturePullToRefresh setWaitToRestart(int value)  { msWaitToRestart = value; return this; }
  /// [dragStartYDiff] add some offset as page top is not always obviously page top, e.g. 10
  DragGesturePullToRefresh setDragStartYDiff(int value) { dragStartYDiff = value;  return this; }

  /// start refresh
  Future<void> refresh() {
    if (!completer.isCompleted) {
      completer.complete();
    }
    completer = Completer<void>();
    started();
    _controller.reload();
    return completer.future;
  }

  /// Loading started
  void started() {
    msLoading = DateTime.now().millisecondsSinceEpoch;
    isLoading = true;
  }

  /// Loading finished
  void finished() {
    msLoading = 0;
    isLoading = false;
    // hide the RefreshIndicator
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  FixedScrollMetrics _getMetrics(double minScrollExtent, double maxScrollExtent,
      double pixels, double viewportDimension, AxisDirection axisDirection) {
    return FixedScrollMetrics(
      minScrollExtent: minScrollExtent,
      maxScrollExtent: maxScrollExtent,
      pixels: pixels,
      viewportDimension: viewportDimension,
      axisDirection: axisDirection, devicePixelRatio: 1
    );
  }

  /// [msWaitToRestart] milliseconds to reallow pull to refresh if the website
  /// didn't load in msWaitToRestart time
  ///
  /// [dragStartYDiff] add some offset as page top is not always obviously page top, e.g. 10
  DragGesturePullToRefresh([this.msWaitToRestart = exceedsLoadingTime, this.dragStartYDiff = 0]) {
    onStart = (DragStartDetails dragDetails) async {
      //debugPrint('DragGesturePullToRefresh(): $dragDetails');
      if (!isLoading ||
          // Reallow pull to refresh if the website didn't load in msWaitToRestart time
          (msLoading > 0 && (DateTime.now().millisecondsSinceEpoch - msLoading) > msWaitToRestart)) {
        Offset scrollPos = await _controller.getScrollPosition();

        // Only allow RefreshIndicator if you are at the top of page!
        if (scrollPos.dy <= dragStartYDiff) {
          dragStarted = true;
          dragDistance = 0;
          ScrollStartNotification(
            metrics: _getMetrics(0, dragHeightEnd, 0, dragHeightEnd, AxisDirection.down),
            dragDetails: dragDetails,
            context: _context
          ).dispatch(_context);
        }
      }
    };
    onUpdate = (DragUpdateDetails dragDetails) {
      if (dragStarted) {
        double dy = dragDetails.delta.dy;
        dragDistance += dy;
        ScrollUpdateNotification(
          metrics: _getMetrics(
            dy > 0 ? 0 : dragDistance, dragHeightEnd,
            dy > 0 ? (-1) * dy : dragDistance, dragHeightEnd,
            dragDistance < 0 ? AxisDirection.up : AxisDirection.down),
            context: _context,
            scrollDelta: (-1) * dy
        ).dispatch(_context);
        if (dragDistance < 0) {
          _clearDrag();
        }
      }
    };
    onEnd = (DragEndDetails dragDetails) {
      if (dragStarted) {
        ScrollEndNotification(
            metrics: _getMetrics(0, dragHeightEnd, dragDistance, dragHeightEnd, AxisDirection.down),
            context: _context
        ).dispatch(_context);
        _clearDrag();
      }
    };
    onCancel = () {
      if (dragStarted) {
        ScrollUpdateNotification(
          metrics: _getMetrics(0, dragHeightEnd, 1, dragHeightEnd, AxisDirection.up),
          context: _context,
          scrollDelta: 0
        ).dispatch(_context);
        _clearDrag();
      }
    };
  }
}
