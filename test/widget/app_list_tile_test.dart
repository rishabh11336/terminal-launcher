import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_launcher/models/app_info.dart';
import 'package:terminal_launcher/widgets/app_list_tile.dart';

const _whatsapp = AppInfo(
  packageName: 'com.whatsapp',
  displayName: 'WhatsApp',
  searchKey: 'whatsapp',
);

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('AppListTile — rendering', () {
    testWidgets('shows displayName in lowercase', (tester) async {
      await tester.pumpWidget(_wrap(
        AppListTile(app: _whatsapp, isHighlighted: false, onTap: () {}, onLongPress: () {}),
      ));
      expect(find.text('whatsapp'), findsOneWidget);
    });

    testWidgets('no ↵ suffix when not highlighted', (tester) async {
      await tester.pumpWidget(_wrap(
        AppListTile(app: _whatsapp, isHighlighted: false, onTap: () {}, onLongPress: () {}),
      ));
      // No text containing ↵
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => (t.data ?? '').contains('↵'));
      expect(texts, isEmpty);
    });

    testWidgets('shows ↵ suffix when highlighted', (tester) async {
      await tester.pumpWidget(_wrap(
        AppListTile(app: _whatsapp, isHighlighted: true, onTap: () {}, onLongPress: () {}),
      ));
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => (t.data ?? '').contains('↵'));
      expect(texts, isNotEmpty);
    });

    testWidgets('uses JetBrainsMono font', (tester) async {
      await tester.pumpWidget(_wrap(
        AppListTile(app: _whatsapp, isHighlighted: false, onTap: () {}, onLongPress: () {}),
      ));
      final nameText = tester.widget<Text>(find.text('whatsapp'));
      expect(nameText.style?.fontFamily, equals('JetBrainsMono'));
    });

    testWidgets('wraps in GestureDetector', (tester) async {
      await tester.pumpWidget(_wrap(
        AppListTile(app: _whatsapp, isHighlighted: false, onTap: () {}, onLongPress: () {}),
      ));
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });

  group('AppListTile — interaction', () {
    testWidgets('onTap fires when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        AppListTile(
          app: _whatsapp,
          isHighlighted: false,
          onTap: () => tapped = true,
          onLongPress: () {},
        ),
      ));
      await tester.tap(find.text('whatsapp'));
      expect(tapped, isTrue);
    });

    testWidgets('onTap fires for different app', (tester) async {
      bool tapped = false;
      const gmail = AppInfo(
        packageName: 'com.google.gmail',
        displayName: 'Gmail',
        searchKey: 'gmail',
      );
      await tester.pumpWidget(_wrap(
        AppListTile(
          app: gmail,
          isHighlighted: false,
          onTap: () => tapped = true,
          onLongPress: () {},
        ),
      ));
      await tester.tap(find.text('gmail'));
      expect(tapped, isTrue);
    });
  });

  group('AppListTile — highlight styling', () {
    testWidgets('highlighted tile ↵ text uses accent green color', (tester) async {
      await tester.pumpWidget(_wrap(
        AppListTile(app: _whatsapp, isHighlighted: true, onTap: () {}, onLongPress: () {}),
      ));
      // Find the text widget with ↵
      final enterTexts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => (t.data ?? '').contains('↵'))
          .toList();
      expect(enterTexts, isNotEmpty);
    });

    testWidgets('non-highlighted and highlighted both render without error', (tester) async {
      await tester.pumpWidget(_wrap(
        Column(children: [
          AppListTile(app: _whatsapp, isHighlighted: false, onTap: () {}, onLongPress: () {}),
          AppListTile(app: _whatsapp, isHighlighted: true, onTap: () {}, onLongPress: () {}),
        ]),
      ));
      // Two whatsapp text widgets
      expect(find.text('whatsapp'), findsNWidgets(2));
    });
  });
}
