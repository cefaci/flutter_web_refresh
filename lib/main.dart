import 'package:flutter/material.dart';
import 'webview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  static const String TITLE = 'WebView with RefreshIndicator';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: TITLE,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        /* light theme settings */
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        /* dark theme settings */
      ),
      themeMode: ThemeMode.system,
      /* ThemeMode.system to follow system theme,
         ThemeMode.light for light theme,
         ThemeMode.dark for dark theme
      */
      home: Scaffold(
        appBar: AppBar(title: const Text(TITLE)),
        body: const SafeArea(
          child: MyWebViewWidget(initialUrl: 'https://flutter.dev'),
        ),
      ),
    );
  }
}