import 'package:flutter_test/flutter_test.dart';
import 'package:kolamkari/services/gamification_service.dart';
import 'package:kolamkari/services/storage_service.dart';

void main() {
  group('GamificationService Level Calculation Tests', () {
    test('Calculates Level 1 for starting XP', () {
      final (level, title, curBase, nextBase) = GamificationService.calculateLevel(0);
      expect(level, equals(1));
      expect(title, equals('Kolam Explorer'));
      expect(curBase, equals(0));
      expect(nextBase, equals(150));
    });

    test('Calculates Level 2 for 150 XP', () {
      final (level, title, curBase, nextBase) = GamificationService.calculateLevel(150);
      expect(level, equals(2));
      expect(title, equals('Pattern Learner'));
      expect(curBase, equals(150));
      expect(nextBase, equals(350));
    });

    test('Calculates Level 4 for 650 XP', () {
      final (level, title, _, _) = GamificationService.calculateLevel(650);
      expect(level, equals(4));
      expect(title, equals('Kolam Creator'));
    });

    test('Calculates Level 8 (Heritage Keeper) for 3000+ XP', () {
      final (level, title, curBase, _) = GamificationService.calculateLevel(3500);
      expect(level, equals(8));
      expect(title, equals('Heritage Keeper'));
      expect(curBase, equals(3000));
    });

    test('awardXp awards 30 XP for "Analyse Kolam"', () async {
      final service = GamificationService(StorageService());
      final startXp = service.profile.xp;
      await service.awardXp(30, 'Analyse Kolam');
      expect(service.profile.xp, equals(startXp + 30));
    });
  });
}
