import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  WebViewController _controller = WebViewController();
  late DragGesturePullToRefresh dragGesturePullToRefresh;

  @override
  void initState() {
    super.initState();

    dragGesturePullToRefresh = DragGesturePullToRefresh();
    dragGesturePullToRefresh.setContext(context).setController(_controller);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            dragGesturePullToRefresh.started();
          },
          onPageFinished: (String url) {
            dragGesturePullToRefresh.finished();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('MyWebViewWidget:onWebResourceError(): ${error.description}');
            dragGesturePullToRefresh.finished();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));

    setState(() {});

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // remove listener
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // on portrait / landscape or other change, recalculate height
    dragGesturePullToRefresh.setHeight(MediaQuery.of(context).size.height);
  }

  @override
  Widget build(context) {
    return RefreshIndicator(
        onRefresh: () => dragGesturePullToRefresh.refresh(),
        child: Builder(
          builder: (context) => WebViewWidget(
            controller: _controller,
            gestureRecognizers: {Factory(() => dragGesturePullToRefresh)},
          ),
        ),
      );
  }
}
