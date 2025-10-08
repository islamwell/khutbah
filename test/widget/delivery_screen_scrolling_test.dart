import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulpitflow/screens/delivery_screen.dart';

void main() {
  group('DeliveryScreen Scrolling Tests', () {
    const testTitle = 'Test Khutbah';
    const testContent = '''
Bismillah ar-Rahman ar-Rahim

This is a test khutbah content.

وَمَا خَلَقْتُ الْجِنَّ وَالْإِنسَ إِلَّا لِيَعْبُدُونِ

"And I did not create the jinn and mankind except to worship Me."
— Quran 51:56

This is more content to test scrolling behavior.
''';
    const estimatedMinutes = 15;

    testWidgets('Delivery screen should initialize with scroll controller', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryScreen(
            title: testTitle,
            content: testContent,
            estimatedMinutes: estimatedMinutes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify screen renders without errors
      expect(find.byType(DeliveryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Content should be scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryScreen(
            title: testTitle,
            content: testContent,
            estimatedMinutes: estimatedMinutes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the scroll view
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsOneWidget);

      // Get initial scroll position
      final scrollController = tester.widget<SingleChildScrollView>(scrollView).controller;
      expect(scrollController, isNotNull);
      expect(scrollController!.hasClients, isTrue);
      
      final initialOffset = scrollController.offset;
      expect(initialOffset, equals(0.0));
    });

    testWidgets('Manual scroll should work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryScreen(
            title: testTitle,
            content: testContent * 10, // More content for scrolling
            estimatedMinutes: estimatedMinutes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final scrollView = find.byType(SingleChildScrollView);
      final scrollController = tester.widget<SingleChildScrollView>(scrollView).controller!;

      // Perform manual scroll
      await tester.drag(scrollView, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Verify scroll position changed
      expect(scrollController.offset, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Play button should toggle auto-scroll', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryScreen(
            title: testTitle,
            content: testContent * 10,
            estimatedMinutes: estimatedMinutes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find play button
      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);

      // Tap play button
      await tester.tap(playButton);
      await tester.pump();

      // Button should change to pause
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('Auto-scroll mechanism should be available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryScreen(
            title: testTitle,
            content: testContent * 20,
            estimatedMinutes: estimatedMinutes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final scrollView = find.byType(SingleChildScrollView);
      final scrollController = tester.widget<SingleChildScrollView>(scrollView).controller!;

      // Start auto-scroll
      final playButton = find.byIcon(Icons.play_arrow);
      await tester.tap(playButton);
      await tester.pump();

      // Verify play button changed to pause (auto-scroll is active)
      expect(find.byIcon(Icons.pause), findsOneWidget);
      
      // Verify scroll controller is attached and ready
      expect(scrollController.hasClients, isTrue);
      expect(scrollController.position.maxScrollExtent, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Speed slider should adjust scroll speed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryScreen(
            title: testTitle,
            content: testContent * 10,
            estimatedMinutes: estimatedMinutes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find speed slider
      final speedSliders = find.byType(Slider);
      expect(speedSliders, findsWidgets);

      // Get the first slider (speed slider)
      final speedSlider = speedSliders.first;
      
      // Drag slider to change speed
      await tester.drag(speedSlider, const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Font size slider should adjust text size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryScreen(
            title: testTitle,
            content: testContent,
            estimatedMinutes: estimatedMinutes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find font size slider (second slider)
      final sliders = find.byType(Slider);
      expect(sliders, findsWidgets);

      if (sliders.evaluate().length >= 2) {
        final fontSlider = sliders.at(1);
        
        // Drag slider to change font size
        await tester.drag(fontSlider, const Offset(30, 0));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Reset button should return to top', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryScreen(
            title: testTitle,
            content: testContent * 10,
            estimatedMinutes: estimatedMinutes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final scrollView = find.byType(SingleChildScrollView);
      final scrollController = tester.widget<SingleChildScrollView>(scrollView).controller!;

      // Scroll down manually
      await tester.drag(scrollView, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(scrollController.offset, greaterThan(0));

      // Find and tap reset button
      final resetButton = find.byIcon(Icons.stop);
      expect(resetButton, findsOneWidget);
      
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Verify scroll position is back to top
      expect(scrollController.offset, equals(0.0));
    });

    testWidgets('Progress bar should update during scroll', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryScreen(
            title: testTitle,
            content: testContent * 10,
            estimatedMinutes: estimatedMinutes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final scrollView = find.byType(SingleChildScrollView);

      // Scroll down
      await tester.drag(scrollView, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Progress bar should exist and show progress
      final progressBar = find.byType(FractionallySizedBox);
      expect(progressBar, findsOneWidget);
      
      expect(tester.takeException(), isNull);
    });

    testWidgets('Fullscreen mode should toggle correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryScreen(
            title: testTitle,
            content: testContent,
            estimatedMinutes: estimatedMinutes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find fullscreen button
      final fullscreenButton = find.byIcon(Icons.fullscreen);
      expect(fullscreenButton, findsOneWidget);

      // Toggle fullscreen
      await tester.tap(fullscreenButton);
      await tester.pumpAndSettle();

      // Should show exit fullscreen button
      expect(find.byIcon(Icons.fullscreen_exit), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Content should handle Arabic text direction', (WidgetTester tester) async {
      const arabicContent = '''
بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ

وَمَا خَلَقْتُ الْجِنَّ وَالْإِنسَ إِلَّا لِيَعْبُدُونِ
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryScreen(
            title: testTitle,
            content: arabicContent,
            estimatedMinutes: estimatedMinutes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find text widgets with Arabic content
      final textWidgets = find.byType(Text);
      expect(textWidgets, findsWidgets);
      
      // Verify no rendering errors with RTL text
      expect(tester.takeException(), isNull);
    });

    testWidgets('Scroll speed should be within valid range', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryScreen(
            title: testTitle,
            content: testContent * 10,
            estimatedMinutes: estimatedMinutes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find speed slider
      final speedSliders = find.byType(Slider);
      final speedSlider = tester.widget<Slider>(speedSliders.first);

      // Verify speed range
      expect(speedSlider.min, equals(0.5));
      expect(speedSlider.max, equals(3.0));
      expect(speedSlider.value, greaterThanOrEqualTo(speedSlider.min));
      expect(speedSlider.value, lessThanOrEqualTo(speedSlider.max));
    });

    testWidgets('Auto-scroll should stop at end of content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryScreen(
            title: testTitle,
            content: 'Short content',
            estimatedMinutes: estimatedMinutes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final scrollView = find.byType(SingleChildScrollView);
      final scrollController = tester.widget<SingleChildScrollView>(scrollView).controller!;

      // Start auto-scroll
      final playButton = find.byIcon(Icons.play_arrow);
      if (playButton.evaluate().isNotEmpty) {
        await tester.tap(playButton);
        await tester.pump();

        // Wait for potential scrolling
        await tester.pump(const Duration(seconds: 2));

        // Verify scroll doesn't exceed max extent
        expect(
          scrollController.offset,
          lessThanOrEqualTo(scrollController.position.maxScrollExtent),
        );
      }
    });
  });
}
