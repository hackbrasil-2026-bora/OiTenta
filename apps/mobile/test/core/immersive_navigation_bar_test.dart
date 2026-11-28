import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/system/immersive_navigation_bar.dart';

/// Chamadas de "esconder a barra de navegação" recebidas pelo canal da
/// plataforma.
List<MethodCall> _recordSystemUiCalls(WidgetTester tester) {
  final calls = <MethodCall>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemChrome.setEnabledSystemUIMode' ||
          call.method == 'SystemChrome.setEnabledSystemUIOverlays') {
        calls.add(call);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

/// Simula o Android avisando que as barras do sistema apareceram ou sumiram.
Future<void> _systemBarsVisible(WidgetTester tester, bool visible) async {
  final data = const JSONMethodCodec().encodeMethodCall(
    MethodCall('SystemChrome.systemUIChange', [visible]),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.platform.name,
    data,
    (_) {},
  );
}

void main() {
  testWidgets('no Android, esconde só a barra de navegação ao iniciar', (
    tester,
  ) async {
    final calls = _recordSystemUiCalls(tester);
    final bar = ImmersiveNavigationBar(isAndroid: true);

    await bar.start();

    expect(calls, hasLength(1));
    // Modo manual mantendo só a barra de status (hora e bateria).
    expect(calls.single.method, 'SystemChrome.setEnabledSystemUIOverlays');
    expect(calls.single.arguments, ['SystemUiOverlay.top']);
    bar.dispose();
  });

  testWidgets('a barra que aparece ao arrastar some sozinha depois de 3 s', (
    tester,
  ) async {
    final calls = _recordSystemUiCalls(tester);
    final bar = ImmersiveNavigationBar(isAndroid: true);
    await bar.start();
    calls.clear();

    await _systemBarsVisible(tester, true);
    await tester.pump(const Duration(seconds: 2));
    expect(calls, isEmpty, reason: 'ainda dentro dos 3 s');

    await tester.pump(const Duration(seconds: 1));
    expect(calls, hasLength(1));
    expect(calls.single.arguments, ['SystemUiOverlay.top']);
    bar.dispose();
  });

  testWidgets('quando a barra some por conta própria, não esconde de novo', (
    tester,
  ) async {
    final calls = _recordSystemUiCalls(tester);
    final bar = ImmersiveNavigationBar(isAndroid: true);
    await bar.start();
    calls.clear();

    await _systemBarsVisible(tester, false);
    await tester.pump(const Duration(seconds: 5));

    expect(calls, isEmpty);
    bar.dispose();
  });

  testWidgets('fora do Android, não mexe nas barras do sistema', (
    tester,
  ) async {
    final calls = _recordSystemUiCalls(tester);
    final bar = ImmersiveNavigationBar(isAndroid: false);

    await bar.start();
    await _systemBarsVisible(tester, true);
    await tester.pump(const Duration(seconds: 5));

    expect(calls, isEmpty);
    bar.dispose();
  });

  testWidgets('avisa as telas quando os botões aparecem e quando somem', (
    tester,
  ) async {
    _recordSystemUiCalls(tester);
    final bar = ImmersiveNavigationBar(isAndroid: true);
    await bar.start();
    expect(bar.visible.value, isFalse);

    await _systemBarsVisible(tester, true);
    expect(bar.visible.value, isTrue);

    await tester.pump(const Duration(seconds: 3));
    expect(bar.visible.value, isFalse, reason: 'escondeu de novo');
    bar.dispose();
  });

  testWidgets('deixa o fundo dos botões transparente, com ícones claros', (
    tester,
  ) async {
    _recordSystemUiCalls(tester);
    final bar = ImmersiveNavigationBar(isAndroid: true);
    await bar.start();

    final style = SystemChrome.latestStyle!;
    expect(style.systemNavigationBarColor, Colors.transparent);
    expect(style.systemNavigationBarContrastEnforced, isFalse);
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
    bar.dispose();
  });
}
