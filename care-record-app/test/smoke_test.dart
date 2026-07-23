import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:care_record_app/core/theme.dart';

void main() {
  testWidgets('app boots and shows title on off-white bg', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: careTheme, home: const Scaffold(body: Text('照護紀錄'))),
    ));
    expect(find.text('照護紀錄'), findsOneWidget);
    expect(careTheme.scaffoldBackgroundColor, const Color(0xFFF5F5F5));
  });
}
