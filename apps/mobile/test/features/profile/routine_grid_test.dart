import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/profile/domain/routine_grid.dart';
import 'package:oitenta/features/scheduling/domain/availability.dart';

AvailabilityWindow w(int day, int start, int end) => AvailabilityWindow(
  weekday: day,
  startMinute: start * 60,
  endMinute: end * 60,
);

/// Células livres de um dia, pelo rótulo da linha ("8h", "10h"…).
List<String> freeLabels(RoutineGrid g, int day) => [
  for (var r = 0; r < RoutineGrid.rowCount; r++)
    if (g.isFree(day, r)) RoutineGrid.rowLabels[r],
];

void main() {
  group('formato (MP11)', () {
    test('7 linhas de 2h (8h…20h, 8:00–22:00) × 7 dias (Seg…Dom)', () {
      expect(RoutineGrid.rowLabels, [
        '8h',
        '10h',
        '12h',
        '14h',
        '16h',
        '18h',
        '20h',
      ]);
      expect(RoutineGrid.rowCount, 7);
      expect(RoutineGrid.dayLabels, [
        'Seg',
        'Ter',
        'Qua',
        'Qui',
        'Sex',
        'Sáb',
        'Dom',
      ]);
      expect(RoutineGrid.dayCount, 7);
    });

    test('a linha r vai de (8 + 2r)h a (10 + 2r)h', () {
      expect(RoutineGrid.rowStartMinute(0), 480);
      expect(RoutineGrid.rowEndMinute(0), 600);
      expect(RoutineGrid.rowStartMinute(6), 1200);
      expect(RoutineGrid.rowEndMinute(6), 1320);
    });

    test('a grade vazia não tem células livres', () {
      final g = RoutineGrid.empty();
      expect(g.cellCount, 0);
      expect(g.isEmpty, isTrue);
      expect(g.freeHours, 0);
      expect(g.toWindows(), isEmpty);
    });
  });

  group('fromWindows: célula livre só se couber inteira numa janela', () {
    test('12:00–18:00 da segunda marca 12h, 14h e 16h da segunda', () {
      final g = RoutineGrid.fromWindows([w(0, 12, 18)]);
      expect(freeLabels(g, 0), ['12h', '14h', '16h']);
      for (var d = 1; d < 7; d++) {
        expect(freeLabels(g, d), isEmpty);
      }
    });

    test('06:00–12:00 (manhã do onboarding) marca 8h e 10h', () {
      final g = RoutineGrid.fromWindows([w(2, 6, 12)]);
      expect(freeLabels(g, 2), ['8h', '10h']);
    });

    test('18:00–23:00 (noite do onboarding) marca 18h e 20h', () {
      final g = RoutineGrid.fromWindows([w(4, 18, 23)]);
      expect(freeLabels(g, 4), ['18h', '20h']);
    });

    test('09:00–11:00 cobre só parte das células e não marca nada', () {
      final g = RoutineGrid.fromWindows([w(0, 9, 11)]);
      expect(g.isEmpty, isTrue);
    });

    test('janelas de dias diferentes não se misturam', () {
      final g = RoutineGrid.fromWindows([w(0, 12, 18), w(2, 18, 23)]);
      expect(freeLabels(g, 0), ['12h', '14h', '16h']);
      expect(freeLabels(g, 1), isEmpty);
      expect(freeLabels(g, 2), ['18h', '20h']);
      expect(g.cellCount, 5);
    });
  });

  group('toWindows: a grade inteira vira a disponibilidade', () {
    test('14h, 16h e 18h da segunda viram uma janela só 14:00–20:00', () {
      final g = RoutineGrid.empty().toggle(0, 3).toggle(0, 4).toggle(0, 5);
      expect(g.toWindows(), [w(0, 14, 20)]);
    });

    test('células separadas (10h e 14h) viram duas janelas', () {
      final g = RoutineGrid.empty().toggle(1, 1).toggle(1, 3);
      expect(g.toWindows(), [w(1, 10, 12), w(1, 14, 16)]);
    });

    test('a última linha fecha às 22:00', () {
      final g = RoutineGrid.empty().toggle(6, 5).toggle(6, 6);
      expect(g.toWindows(), [w(6, 18, 22)]);
    });

    test('o resultado vem ordenado por dia e hora', () {
      final g = RoutineGrid.empty()
          .toggle(2, 0) // Qua 8h
          .toggle(0, 6) // Seg 20h
          .toggle(0, 0); // Seg 8h
      expect(g.toWindows(), [w(0, 8, 10), w(0, 20, 22), w(2, 8, 10)]);
    });

    test('ida e volta: fromWindows(toWindows(x)) == x', () {
      final x = RoutineGrid.empty()
          .toggle(0, 0)
          .toggle(0, 1)
          .toggle(0, 4)
          .toggle(3, 6)
          .toggle(6, 2);
      expect(RoutineGrid.fromWindows(x.toWindows()), x);
    });
  });

  group('toggle, contagem e igualdade', () {
    test('toggle marca e desmarca sem mudar a grade original', () {
      final a = RoutineGrid.empty();
      final b = a.toggle(3, 2);
      expect(a.isFree(3, 2), isFalse);
      expect(b.isFree(3, 2), isTrue);
      expect(b.toggle(3, 2).isFree(3, 2), isFalse);
    });

    test('dia ou linha fora da grade dá RangeError', () {
      final g = RoutineGrid.empty();
      expect(() => g.toggle(7, 0), throwsRangeError);
      expect(() => g.toggle(-1, 0), throwsRangeError);
      expect(() => g.toggle(0, 7), throwsRangeError);
      expect(() => g.isFree(0, -1), throwsRangeError);
    });

    test('freeHours = células × 2 (rotina do protótipo: 52h)', () {
      // `defaultRotina()` do Bora App.dc.html.
      var g = RoutineGrid.empty();
      for (var d = 0; d < 7; d++) {
        for (var h = 0; h < 7; h++) {
          final free = d < 5
              ? (h >= 3 && !(d == 2 && h >= 5))
              : (h >= 1 && h <= 4);
          if (free) g = g.toggle(d, h);
        }
      }
      expect(g.cellCount, 26);
      expect(g.freeHours, 52);
    });

    test('grades com as mesmas células são iguais', () {
      final a = RoutineGrid.empty().toggle(0, 0).toggle(1, 1);
      final b = RoutineGrid.empty().toggle(1, 1).toggle(0, 0);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == RoutineGrid.empty(), isFalse);
    });
  });
}
