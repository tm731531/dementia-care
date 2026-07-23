import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';

void main() => runApp(const ProviderScope(child: App()));

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '照護紀錄',
        theme: careTheme,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(body: Center(child: Text('照護紀錄', key: Key('home-title')))),
      );
}
