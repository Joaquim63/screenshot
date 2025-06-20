import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_app/main.dart';

void main() {
  testWidgets('Screenshot app smoke test', (WidgetTester tester) async {
    // Constrói o app e dispara um frame
    await tester.pumpWidget(MyApp());

    // Verifica se o título está presente
    expect(find.text('Screenshot App'), findsOneWidget);

    // Verifica se o botão de ativar overlay está presente
    expect(find.text('Ativar Overlay'), findsOneWidget);

    // Verifica se o ícone de screenshot está presente
    expect(find.byIcon(Icons.screenshot), findsAtLeastNWidgets(1));
  });

  testWidgets('Home screen elements test', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Verifica elementos da tela principal
    expect(find.text('Captura de Tela'), findsOneWidget);
    expect(find.text('Testar Screenshot'), findsOneWidget);
    expect(find.text('Como usar:'), findsOneWidget);
  });

  testWidgets('Button tap test', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Encontra o botão de teste de screenshot
    final testButton = find.text('Testar Screenshot');
    expect(testButton, findsOneWidget);

    // Simula o toque no botão (sem executar a ação real)
    await tester.tap(testButton);
    await tester.pump();

    // O teste passa se não houver erros de execução
  });
}
