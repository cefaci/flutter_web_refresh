import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_web_refresh/pull_to_refresh.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MyWebViewWidget extends StatefulWidget {
  final String initialUrl;

  const MyWebViewWidget({
    Key? key,
    required this.initialUrl,
  }) : super(key: key);

  @override
  State<MyWebViewWidget> createState() => _MyWebViewWidgetState();
}

class _MyWebViewWidgetState extends State<MyWebViewWidget>
    with WidgetsBindingObserver {
  late WebViewController _controller;

  // Drag to refresh helpers
  final DragGesturePullToRefresh pullToRefresh = DragGesturePullToRefresh();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addObserver(this);
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  void dispose() {
    // remove listener
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // on portrait / landscape or other change, recalculate height
    pullToRefresh.setHeight(MediaQuery.of(context).size.height);
  }

  @override
  Widget build(context) {
    return NotificationListener(
      onNotification: (scrollNotification) {
        debugPrint(
            'MyWebViewWidget:NotificationListener(): $scrollNotification');
        return true;
      },
      child: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () {
          Completer<void> completer = pullToRefresh.refresh();
          _controller.reload();
          return completer.future;
        },
        child: Builder(
          builder: (BuildContext context) {
            return WebView(
              initialUrl: widget.initialUrl,
              javascriptMode: JavascriptMode.unrestricted,
              zoomEnabled: true,
              gestureNavigationEnabled: true,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                pullToRefresh.dragGestureRecognizer(_refreshIndicatorKey),
              },
              onWebViewCreated: (WebViewController webViewController) {
                _controller = webViewController;
                pullToRefresh.setContext(context);
                pullToRefresh.setController(_controller);
              },
              onPageStarted: (String url) {
                pullToRefresh.started();
              },
              onPageFinished: (finish) {
                pullToRefresh.finished();
              },
              onWebResourceError: (error) {
                debugPrint(
                    'MyWebViewWidget:onWebResourceError(): ${error.description}');
                pullToRefresh.finished();
              },
            );
          },
        ),
      ),
    );
  }
}
