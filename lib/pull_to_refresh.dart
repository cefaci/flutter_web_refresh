import 'package:flutter/cupertino.dart';
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

class DragGesturePullToRefresh extends StatelessWidget{
  static const double EXCEEDS_LOADING_TIME = 3000;

  late BuildContext _context;
  late WebViewController _controller;

  // loading
  Completer<void> completer = Completer<void>();
  int msLoading = 0;
  bool isLoading = true;

  // drag
  double height = 200;
  bool dragStarted = false;
  double dragDistance = 0;

  Factory<OneSequenceGestureRecognizer> dragGestureRecognizer(final GlobalKey<RefreshIndicatorState> refreshIndicatorKey) {
    return Factory<OneSequenceGestureRecognizer>(() => VerticalDragGestureRecognizer()
    // Got the original idea from https://stackoverflow.com/users/15862916/shalin-shah:
    // https://stackoverflow.com/questions/57656045/pull-down-to-refresh-webview-page-in-flutter
      ..onStart = (DragStartDetails dragDetails) {
        if (!isLoading ||
            (msLoading > 0 && (DateTime.now().millisecondsSinceEpoch - msLoading) > EXCEEDS_LOADING_TIME)) {
          _controller.getScrollY().then((scrollYPos) {
            if (scrollYPos == 0) {
              dragStarted = true;
              dragDistance = 0;
              ScrollStartNotification(
                  metrics: FixedScrollMetrics(
                    minScrollExtent: 0,
                    maxScrollExtent: height,
                    pixels: 0,
                    viewportDimension: height,
                    axisDirection: AxisDirection.down),
                  dragDetails: dragDetails,
                  context: _context).dispatch(_context);
            }
          });
        }
      }
      ..onUpdate = (DragUpdateDetails dragDetails) {
        if (dragStarted) {
          double dy = dragDetails.delta.dy;
          dragDistance += dy;
          ScrollUpdateNotification(
              metrics: FixedScrollMetrics(
                  minScrollExtent : dy > 0 ? 0 : dragDistance,
                  maxScrollExtent : height,
                  pixels : dy > 0 ? (-1) * dy : dragDistance,
                  viewportDimension : height,
                  axisDirection : dragDistance < 0 ? AxisDirection.up : AxisDirection.down),
              context: _context,
              scrollDelta: (-1) * dy).dispatch(_context);
          if(dragDistance < 0){
            clearDrag();
          }
        }
      }
      ..onEnd = (DragEndDetails dragDetails) {
        ScrollEndNotification(
            metrics: FixedScrollMetrics(
                minScrollExtent : 0,
                maxScrollExtent : height,
                pixels : dragDistance,
                viewportDimension : height,
                axisDirection : AxisDirection.down),
            context: _context
          ).dispatch(_context);
        clearDrag();
      }
      ..onCancel = () {
        ScrollUpdateNotification(
            metrics: FixedScrollMetrics(
                minScrollExtent : 0,
                maxScrollExtent : height,
                pixels : 1,
                viewportDimension : height,
                axisDirection : AxisDirection.up),
            context: _context,
            scrollDelta: 0).dispatch(_context);
        clearDrag();
      });
  }

  void setContext(BuildContext context){ _context = context; }
  void setController(WebViewController controller){ _controller = controller; }
  void setHeight(double height){ this.height = height;  }

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

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
