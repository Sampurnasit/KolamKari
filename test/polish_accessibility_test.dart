import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolamkari/core/theme/app_theme.dart';
import 'package:kolamkari/data/models/user_profile.dart';
import 'package:kolamkari/ui/common/animated_flame_badge.dart';
import 'package:kolamkari/ui/common/badge_unlock_dialog.dart';
import 'package:kolamkari/ui/common/empty_state_widget.dart';
import 'package:kolamkari/ui/common/error_display_widget.dart';
import 'package:kolamkari/ui/common/loading_skeleton_widget.dart';
import 'package:kolamkari/ui/create/widgets/kolam_canvas_widget.dart';

void main() {
  group('Final Polish & Accessibility Widget Tests', () {
    testWidgets('EmptyStateWidget renders message and executes action callback', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.palette_outlined,
              title: 'Gallery Empty',
              message: 'Draw patterns on the canvas to begin.',
              actionLabel: 'Draw Now',
              onAction: () {
                actionTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Gallery Empty'), findsOneWidget);
      expect(find.text('Draw patterns on the canvas to begin.'), findsOneWidget);
      expect(find.text('Draw Now'), findsOneWidget);

      await tester.tap(find.text('Draw Now'));
      await tester.pump();

      expect(actionTriggered, isTrue);
    });

    testWidgets('LoadingSkeletonWidget animates smoothly without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSkeletonWidget(width: 200, height: 60),
          ),
        ),
      );

      expect(find.byType(LoadingSkeletonWidget), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LoadingSkeletonWidget), findsOneWidget);
    });

    testWidgets('ErrorDisplayWidget renders error card and executes onRetry', (tester) async {
      bool retryTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(
              title: 'Connection Lost',
              message: 'Failed to synchronize daily challenge.',
              onRetry: () {
                retryTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Connection Lost'), findsOneWidget);
      expect(find.text('Failed to synchronize daily challenge.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(retryTriggered, isTrue);
    });

    testWidgets('AnimatedFlameBadge pulses flame icon and shows streak count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedFlameBadge(streakDays: 5),
          ),
        ),
      );

      expect(find.text('5 Day Streak'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);

      // Advance animation
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('5 Day Streak'), findsOneWidget);
    });

    testWidgets('BadgeUnlockDialog displays celebratory emblem, title, and closes on button tap', (tester) async {
      const sampleBadge = BadgeItem(
        id: 'memory_master',
        title: 'Memory Master',
        description: 'Complete 20 Kolam Memory challenges.',
        iconEmoji: '🧠',
        unlocked: true,
        targetProgress: 20,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => BadgeUnlockDialog.show(context, sampleBadge),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('SACRED BADGE UNLOCKED!'), findsOneWidget);
      expect(find.text('Memory Master'), findsOneWidget);
      expect(find.text('🧠'), findsOneWidget);
      expect(find.text('Honored!'), findsOneWidget);

      await tester.tap(find.text('Honored!'));
      await tester.pumpAndSettle();

      expect(find.text('SACRED BADGE UNLOCKED!'), findsNothing);
    });

    testWidgets('KolamCanvasWidget wraps CustomPaint in RepaintBoundary for 60fps performance', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: KolamCanvasWidget(
                  gridSize: 5,
                  showDots: true,
                  strokes: [],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('AppTheme includes PageTransitionsTheme for seamless navigation', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      expect(lightTheme.pageTransitionsTheme, isNotNull);
      expect(darkTheme.pageTransitionsTheme, isNotNull);
    });
  });
}
