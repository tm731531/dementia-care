import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'spike/stt_spike_screen.dart';

void main() => runApp(const ProviderScope(child: App()));

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '照護紀錄',
        theme: careTheme,
        debugShowCheckedModeBanner: false,
        // Task 2 spike: on-device STT gate. Swap back to the real home
        // screen once spike/stt_spike.md records a GO decision.
        home: const SttSpikeScreen(),
      );
}
