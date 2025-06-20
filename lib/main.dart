import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'widgets/overlay_widget.dart';

void main() {
  runApp(MyApp());
}

// Função de entrada para o overlay (botão flutuante)
@pragma("vm:entry-point")
void overlayMain() {
  runApp(OverlayApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screenshot App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

// Aplicativo que roda no overlay (botão flutuante)
class OverlayApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screenshot Overlay',
      debugShowCheckedModeBanner: false,
      home: OverlayWidget(),
    );
  }
}
