import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/config/app_config.dart';
import 'package:oitenta/core/di/app_dependencies.dart';
import 'package:oitenta/core/routes/app_router.dart';
import 'package:oitenta/core/routes/app_routes.dart';
import 'package:oitenta/core/widgets/app_shell.dart';
import 'package:oitenta/features/goals/data/http_single_tasks_repository.dart';
import 'package:oitenta/features/goals/data/sample_single_tasks_repository.dart';
import 'package:oitenta/features/goals/presentation/single_tasks_pages.dart';
import 'package:oitenta/features/scheduling/data/http_commitments_repository.dart';
import 'package:oitenta/features/scheduling/data/sample_commitments_repository.dart';
import 'package:oitenta/features/scheduling/presentation/commitment_form_pages.dart';

import '../helpers/test_app.dart';

/// Esqueleto da rodada de compromissos e tarefas únicas (passo 0.6).
void main() {
  group('rotas', () {
    testWidgets('/semana/compromisso abre o formulário dentro do shell', (
      tester,
    ) async {
      await pumpApp(tester, location: AppRoutes.commitmentNew);
      expect(find.byType(CommitmentFormPage), findsOneWidget);
      expect(find.byType(BoraTabBar), findsOneWidget);
    });

    testWidgets('/semana/compromisso/:id abre o formulário de edição', (
      tester,
    ) async {
      await pumpApp(tester, location: AppRoutes.commitmentEdit('violao'));
      final page = tester.widget<CommitmentFormPage>(
        find.byType(CommitmentFormPage),
      );
      expect(page.commitmentId, 'violao');
    });

    testWidgets('/tarefas abre Tarefas únicas dentro do shell', (tester) async {
      await pumpApp(tester, location: AppRoutes.singleTasks);
      expect(find.byType(SingleTasksPage), findsOneWidget);
      expect(find.byType(BoraTabBar), findsOneWidget);
    });

    test('aba ativa: compromisso é Semana; tarefas é Hoje', () {
      expect(tabFor(AppRoutes.commitmentNew), AppTab.week);
      expect(tabFor(AppRoutes.commitmentEdit('x')), AppTab.week);
      expect(tabFor(AppRoutes.singleTasks), AppTab.today);
    });
  });

  group('DI', () {
    test('modo sample usa os repositórios de exemplo', () {
      final d = AppDependencies.sample();
      expect(d.commitments, isA<SampleCommitmentsRepository>());
      expect(d.singleTasks, isA<SampleSingleTasksRepository>());
    });

    test('modo http usa os repositórios HTTP', () {
      final d = AppDependencies.http(showDemo: false);
      expect(d.commitments, isA<HttpCommitmentsRepository>());
      expect(d.singleTasks, isA<HttpSingleTasksRepository>());
    });
  });

  test('SEMESTER_END: sem a variável, vale 2026-12-12 (MC3)', () {
    expect(AppConfig.semesterEnd, '2026-12-12');
  });
}
