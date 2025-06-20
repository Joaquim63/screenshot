import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/screenshot_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isOverlayActive = false;
  bool isLoading = false;
  final ScreenshotService _screenshotService = ScreenshotService();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _checkOverlayStatus();
  }

  // Solicita as permissões necessárias
  Future<void> _requestPermissions() async {
    await [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.photos,
    ].request();
  }

  // Verifica se o overlay está ativo
  Future<void> _checkOverlayStatus() async {
    final isActive = await FlutterOverlayWindow.isActive();
    if (mounted) {
      setState(() {
        isOverlayActive = isActive;
      });
    }
  }

  // Ativa o overlay (botão flutuante)
  Future<void> _startOverlay() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Solicita permissão para overlay
      final bool? hasPermission =
          await FlutterOverlayWindow.requestPermission();

      if (hasPermission == true) {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          overlayTitle: "Screenshot",
          overlayContent: 'Toque para capturar tela',
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.auto,
          width: 100,
          height: 100,
        );

        setState(() {
          isOverlayActive = true;
        });

        _showSnackBar('Botão flutuante ativado!', Colors.green);
      } else {
        _showSnackBar('Permissão negada. Ative nas configurações.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erro ao ativar overlay: $e', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Desativa o overlay
  Future<void> _stopOverlay() async {
    setState(() {
      isLoading = true;
    });

    try {
      await FlutterOverlayWindow.closeOverlay();
      setState(() {
        isOverlayActive = false;
      });
      _showSnackBar('Botão flutuante desativado!', Colors.orange);
    } catch (e) {
      _showSnackBar('Erro ao desativar overlay: $e', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Testa a captura de tela
  Future<void> _testScreenshot() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _screenshotService.takeScreenshot();
      _showSnackBar('Screenshot capturado com sucesso!', Colors.green);
    } catch (e) {
      _showSnackBar('Erro ao capturar screenshot: $e', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Mostra mensagem na tela
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Screenshot App'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone principal
            Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.screenshot,
                size: 80,
                color: Colors.blue,
              ),
            ),

            SizedBox(height: 30),

            // Título
            Text(
              'Captura de Tela',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),

            SizedBox(height: 10),

            // Descrição
            Text(
              'Ative o botão flutuante para capturar a tela\na qualquer momento',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 40),

            // Botão principal
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : (isOverlayActive ? _stopOverlay : _startOverlay),
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(isOverlayActive ? Icons.stop : Icons.play_arrow),
                label: Text(
                  isLoading
                      ? 'Carregando...'
                      : (isOverlayActive
                          ? 'Desativar Overlay'
                          : 'Ativar Overlay'),
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOverlayActive ? Colors.red : Colors.blue,
                ),
              ),
            ),

            SizedBox(height: 20),

            // Botão de teste
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : _testScreenshot,
                icon: Icon(Icons.camera_alt),
                label: Text('Testar Screenshot'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: BorderSide(color: Colors.blue),
                ),
              ),
            ),

            SizedBox(height: 30),

            // Status do overlay
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOverlayActive ? Colors.green[50] : Colors.grey[100],
                border: Border.all(
                  color: isOverlayActive ? Colors.green : Colors.grey,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isOverlayActive ? Icons.check_circle : Icons.info,
                    color: isOverlayActive ? Colors.green : Colors.grey[600],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOverlayActive ? 'Overlay Ativo' : 'Overlay Inativo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOverlayActive
                                ? Colors.green[800]
                                : Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          isOverlayActive
                              ? 'O botão flutuante está ativo. Toque nele para capturar a tela.'
                              : 'Ative o overlay para usar o botão flutuante.',
                          style: TextStyle(
                            color: isOverlayActive
                                ? Colors.green[700]
                                : Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Instruções
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Como usar:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Toque em "Ativar Overlay"\n'
                    '2. Permita que o app apareça sobre outros apps\n'
                    '3. Use o botão flutuante azul para capturar telas\n'
                    '4. As imagens serão salvas na galeria',
                    style: TextStyle(
                      color: Colors.blue[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
