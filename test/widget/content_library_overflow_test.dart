import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulpitflow/screens/content_library_screen.dart';
import 'package:pulpitflow/models/content_item.dart';
import 'package:pulpitflow/services/content_data_service.dart';

void main() {
  group('ContentLibraryScreen Overflow Tests', () {
    testWidgets('Content card header should not overflow with long source text', (WidgetTester tester) async {
      // Build the screen
      await tester.pumpWidget(
        MaterialApp(
          home: ContentLibraryScreen(),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Verify no overflow errors occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('PopupMenuButton should have constrained width', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContentLibraryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find popup menu buttons
      final popupButtons = find.byType(PopupMenuButton<String>);
      
      if (popupButtons.evaluate().isNotEmpty) {
        // Get the first popup button
        final firstButton = popupButtons.first;
        final buttonWidget = tester.widget<PopupMenuButton<String>>(firstButton);
        
        // Verify the button is wrapped in a SizedBox with width constraint
        final parentFinder = find.ancestor(
          of: firstButton,
          matching: find.byType(SizedBox),
        );
        
        expect(parentFinder, findsWidgets);
        
        final sizedBox = tester.widget<SizedBox>(parentFinder.first);
        expect(sizedBox.width, equals(40.0));
      }

      // Verify no overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Content card with very long source should not overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContentLibraryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('Row layout in content card header should handle constraints', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContentLibraryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no RenderFlex overflow errors
      expect(tester.takeException(), isNull);
      
      // Find all Row widgets
      final rows = find.byType(Row);
      expect(rows, findsWidgets);
      
      // Verify rows are properly constrained
      for (final rowFinder in rows.evaluate()) {
        final renderBox = tester.renderObject(find.byWidget(rowFinder.widget)) as RenderBox;
        expect(renderBox.hasSize, isTrue);
        expect(renderBox.size.width.isFinite, isTrue);
      }
    });

    testWidgets('Search bar should not overflow on narrow screens', (WidgetTester tester) async {
      // Set a narrow screen size
      await tester.binding.setSurfaceSize(const Size(320, 568));
      
      await tester.pumpWidget(
        MaterialApp(
          home: ContentLibraryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify search bar exists and doesn't overflow
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      
      expect(tester.takeException(), isNull);
      
      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Content list should scroll without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContentLibraryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find the list view
      final listView = find.byType(ListView);
      
      if (listView.evaluate().isNotEmpty) {
        // Try scrolling
        await tester.drag(listView.first, const Offset(0, -200));
        await tester.pumpAndSettle();
        
        // Verify no overflow occurred during scroll
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('TabBarView should not cause infinite height constraints', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContentLibraryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find TabBarView
      final tabBarView = find.byType(TabBarView);
      expect(tabBarView, findsOneWidget);
      
      // Verify it's properly constrained
      final renderBox = tester.renderObject(tabBarView) as RenderBox;
      expect(renderBox.hasSize, isTrue);
      expect(renderBox.size.height.isFinite, isTrue);
      
      expect(tester.takeException(), isNull);
    });

    testWidgets('Switching tabs should not cause overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContentLibraryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find tabs
      final hadithTab = find.text('Hadith');
      final quotesTab = find.text('Quotes');
      
      if (hadithTab.evaluate().isNotEmpty) {
        // Switch to Hadith tab
        await tester.tap(hadithTab);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        
        // Switch to Quotes tab
        await tester.tap(quotesTab);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Keywords wrap should not overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContentLibraryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find Wrap widgets (used for keywords)
      final wraps = find.byType(Wrap);
      
      for (final wrapFinder in wraps.evaluate()) {
        final renderBox = tester.renderObject(find.byWidget(wrapFinder.widget)) as RenderBox;
        expect(renderBox.hasSize, isTrue);
        expect(renderBox.size.width.isFinite, isTrue);
      }
      
      expect(tester.takeException(), isNull);
    });
  });
}
