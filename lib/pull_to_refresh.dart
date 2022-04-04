import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Fixed issue: https://github.com/flutter/flutter/issues/39389
class AllowVerticalDragGestureRecognizer extends VerticalDragGestureRecognizer {
  @override
  //override rejectGesture here
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

class DragGesturePullToRefresh {
  static const double EXCEEDS_LOADING_TIME = 3000;
  static const double REFRESH_DISTANCE_MIN = .2;

  late WebViewController _controller;

  // loading
  Completer<void> completer = Completer<void>();
  int msLoading = 0;
  bool isLoading = true;

  // drag
  bool dragStarted = false;
  double dragDistance = 0;
  double refreshDistance = 200;

  Factory<OneSequenceGestureRecognizer> dragGestureRecognizer(final GlobalKey<RefreshIndicatorState> refreshIndicatorKey) {
    return Factory<OneSequenceGestureRecognizer>(() => AllowVerticalDragGestureRecognizer()
    // Got the original idea from https://stackoverflow.com/users/15862916/shalin-shah:
    // https://stackoverflow.com/questions/57656045/pull-down-to-refresh-webview-page-in-flutter
      ..onDown = (DragDownDetails dragDownDetails) {
        // if the page is still loading don't allow refreshing again
        if (!isLoading ||
            (msLoading > 0 && (DateTime.now().millisecondsSinceEpoch - msLoading) > EXCEEDS_LOADING_TIME)) {
          _controller.getScrollY().then((scrollYPos) {
            if (scrollYPos == 0) {
              dragStarted = true;
              dragDistance = 0;
            }
          });
        }
      }
      ..onUpdate = (DragUpdateDetails dragUpdateDetails) {
        calculateDrag(refreshIndicatorKey, dragUpdateDetails.delta.dy);
      }
      ..onEnd = (DragEndDetails dragEndDetails) { clearDrag(); }
      ..onCancel = () { clearDrag(); });
  }

  void setController(WebViewController controller){ _controller = controller; }
  void setRefreshDistance(double height){ refreshDistance = height * REFRESH_DISTANCE_MIN; }

  Completer<void> refresh() {
    if (!completer.isCompleted) {
      completer.complete();
    }
    completer = Completer<void>();
    started();
    return completer;
  }

  void started() {
    msLoading = DateTime.now().millisecondsSinceEpoch;
    isLoading = true;
  }

  void finished() {
    msLoading = 0;
    isLoading = false;
    // hide the RefreshIndicator
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  void clearDrag() {
    dragStarted = false;
    dragDistance = 0;
  }

  void calculateDrag(final GlobalKey<RefreshIndicatorState> refreshIndicatorKey, double dy) async {
    if (dragStarted && dy >= 0) {
      dragDistance += dy;
      // Show the RefreshIndicator
      if (dragDistance > refreshDistance) {
        debugPrint(
            'DragGesturePullToRefresh:refreshPage(): $dragDistance > $refreshDistance');
        clearDrag();
        unawaited(refreshIndicatorKey.currentState?.show());
      }
    /*
      The web page scrolling is not blocked, when you start to drag down from the top position of
      the page to start the refresh process, e.g. like in the chrome browser. So the refresh process
      is stopped if start to drag down from the page top position and then up before reaching
      the distance to start the refresh process.
    */
    } else {
      clearDrag();
    }
  }
}
