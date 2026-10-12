import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paraspa/core/utils/format.dart';
import 'package:paraspa/core/widgets/brand_mark.dart';
import 'package:paraspa/core/widgets/segmented_tabs.dart';
import 'package:paraspa/core/widgets/swap_avatar.dart';
import 'package:paraspa/main.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ParaspaApp()));
    await tester.pump();

    expect(find.byType(BrandMark), findsOneWidget);
  });

  testWidgets('SegmentedTabs reports the tapped index', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SegmentedTabs(
              labels: const ['Incoming', 'Sent', 'All'],
              counts: const [2, 3, 5],
              selected: selected,
              onChanged: (i) => setState(() => selected = i),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sent'));
    await tester.pump();
    expect(selected, 1);
  });

  group('format helpers', () {
    test('initials', () {
      expect(SwapAvatar.initialsOf('Priya Nair'), 'PN');
      expect(SwapAvatar.initialsOf('  sashank '), 'S');
      expect(SwapAvatar.initialsOf(''), '?');
    });

    test('compactRange', () {
      expect(compactRange('18:00:00', '20:00:00'), '18–20');
      expect(compactRange('09:30:00', '11:00:00'), '9:30–11');
    });

    test('relativeTime', () {
      final now = DateTime(2026, 10, 10, 12);
      expect(relativeTime(DateTime(2026, 10, 10, 11, 30), now: now), '30m ago');
      expect(relativeTime(DateTime(2026, 10, 9, 20), now: now), 'Yesterday');
      expect(relativeTime(DateTime(2026, 10, 3, 8), now: now), 'Oct 3');
    });

    test('greeting', () {
      expect(greetingFor(DateTime(2026, 1, 1, 8)), 'Good morning');
      expect(greetingFor(DateTime(2026, 1, 1, 20)), 'Good evening');
    });
  });
}
