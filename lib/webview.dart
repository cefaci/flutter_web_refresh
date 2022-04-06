import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
  late DragGesturePullToRefresh dragGesturePullToRefresh;

  @override
  void initState() {
    super.initState();

    dragGesturePullToRefresh = DragGesturePullToRefresh();
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
    dragGesturePullToRefresh.setHeight(MediaQuery.of(context).size.height);
  }

  @override
  Widget build(context) {
    return
        // NotificationListener(
        // onNotification: (scrollNotification) {
        //  debugPrint('MyWebViewWidget:NotificationListener(): $scrollNotification');
        //  return true;
        // }, child:
      RefreshIndicator(
        onRefresh: () => dragGesturePullToRefresh.refresh(),
        child: Builder(
          builder: (context) => WebView(
            initialUrl: widget.initialUrl,
            javascriptMode: JavascriptMode.unrestricted,
            zoomEnabled: true,
            gestureNavigationEnabled: true,
            gestureRecognizers: {Factory(() => dragGesturePullToRefresh)},
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
              dragGesturePullToRefresh
                  .setContext(context)
                  .setController(_controller);
            },
            onPageStarted: (String url) { dragGesturePullToRefresh.started(); },
            onPageFinished: (finish) {    dragGesturePullToRefresh.finished();},
            onWebResourceError: (error) {
              debugPrint(
                  'MyWebViewWidget:onWebResourceError(): ${error.description}');
              dragGesturePullToRefresh.finished();
            },
          ),
        ),
      );
  }
}
