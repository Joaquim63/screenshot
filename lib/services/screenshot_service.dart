import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ScreenshotService {
  static const MethodChannel _channel = MethodChannel('screenshot_channel');

  // Captura screenshot usando método nativo
  Future<void> takeScreenshot() async {
    try {
      print('Iniciando captura de screenshot...');

      // Verifica permissões
      await _checkPermissions();

      // Usa apenas o método nativo (que salva automaticamente na galeria)
      bool success = await _captureNativeScreenshot();

      if (success) {
        print('Screenshot capturado com sucesso!');
      } else {
        // Fallback: tenta captura alternativa
        await _captureAlternativeScreenshot();
      }
    } catch (e) {
      print('Erro ao capturar screenshot: $e');
      throw Exception('Falha ao capturar screenshot: $e');
    }
  }

  // Verifica e solicita permissões necessárias
  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> permissions = await [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.photos,
    ].request();

    bool allGranted = permissions.values
        .every((status) => status == PermissionStatus.granted);

    if (!allGranted) {
      throw Exception('Permissões de armazenamento negadas');
    }
  }

  // Captura screenshot usando código nativo (Android)
  Future<bool> _captureNativeScreenshot() async {
    try {
      final result = await _channel.invokeMethod('takeScreenshot');
      return result == 'success';
    } catch (e) {
      print('Método nativo falhou: $e');
      return false;
    }
  }

  // Método alternativo simplificado (salva apenas em arquivo local)
  Future<void> _captureAlternativeScreenshot() async {
    try {
      print('Usando método alternativo...');

      final RenderRepaintBoundary? boundary = _findRenderRepaintBoundary();

      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          await _saveImageToLocalDirectory(byteData.buffer.asUint8List());
        }
      } else {
        throw Exception('Não foi possível encontrar boundary para captura');
      }
    } catch (e) {
      print('Captura alternativa falhou: $e');
      throw e;
    }
  }

  // Encontra o RenderRepaintBoundary da tela atual
  RenderRepaintBoundary? _findRenderRepaintBoundary() {
    try {
      final RenderObject? renderObject =
          WidgetsBinding.instance.renderViewElement?.renderObject;

      if (renderObject is RenderRepaintBoundary) {
        return renderObject;
      }

      return null;
    } catch (e) {
      print('Erro ao encontrar RenderRepaintBoundary: $e');
      return null;
    }
  }

  // Salva a imagem em diretório local (método simplificado)
  Future<void> _saveImageToLocalDirectory(Uint8List imageBytes) async {
    try {
      // Gera nome único para o arquivo
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'Screenshot_$timestamp.png';

      // Tenta salvar no diretório de Pictures
      Directory? picturesDir;

      if (Platform.isAndroid) {
        // Tenta diretório público de Pictures
        picturesDir = Directory('/storage/emulated/0/Pictures/Screenshots');

        if (!await picturesDir.exists()) {
          await picturesDir.create(recursive: true);
        }
      } else {
        // Para iOS ou fallback, usa diretório de documentos
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        picturesDir = Directory('${appDocDir.path}/Screenshots');

        if (!await picturesDir.exists()) {
          await picturesDir.create(recursive: true);
        }
      }

      // Salva o arquivo
      final File file = File('${picturesDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      print('Screenshot salvo em: ${file.path}');
    } catch (e) {
      print('Erro ao salvar imagem: $e');
      throw Exception('Falha ao salvar screenshot: $e');
    }
  }

  // Método para capturar screenshot de um widget específico
  Future<void> captureWidget(GlobalKey key) async {
    try {
      RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary != null) {
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          await _saveImageToLocalDirectory(byteData.buffer.asUint8List());
        }
      }
    } catch (e) {
      print('Erro ao capturar widget: $e');
      throw Exception('Falha ao capturar widget: $e');
    }
  }

  // Verifica se o serviço está disponível
  Future<bool> isAvailable() async {
    try {
      // Verifica se as permissões estão concedidas
      final permissions = await [
        Permission.storage,
        Permission.manageExternalStorage,
        Permission.photos,
      ].request();

      return permissions.values
          .every((status) => status == PermissionStatus.granted);
    } catch (e) {
      return false;
    }
  }

  // Obtém o diretório onde as screenshots são salvas
  Future<String> getScreenshotDirectory() async {
    try {
      if (Platform.isAndroid) {
        return '/storage/emulated/0/Pictures/Screenshots';
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        return '${directory.path}/Screenshots';
      }

      return '';
    } catch (e) {
      print('Erro ao obter diretório: $e');
      return '';
    }
  }

  // Lista todas as screenshots salvas pelo app
  Future<List<File>> getScreenshots() async {
    try {
      final String dirPath = await getScreenshotDirectory();
      final Directory dir = Directory(dirPath);

      if (await dir.exists()) {
        final List<FileSystemEntity> files = dir.listSync();
        return files
            .where((file) => file is File && file.path.endsWith('.png'))
            .cast<File>()
            .toList();
      }

      return [];
    } catch (e) {
      print('Erro ao listar screenshots: $e');
      return [];
    }
  }

  // Remove screenshot específico
  Future<bool> deleteScreenshot(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Erro ao deletar screenshot: $e');
      return false;
    }
  }

  // Compartilha screenshot
  Future<void> shareScreenshot(String filePath) async {
    try {
      // Implementação futura para compartilhamento
      // Pode usar package como share_plus
      print('Compartilhando screenshot: $filePath');
    } catch (e) {
      print('Erro ao compartilhar screenshot: $e');
    }
  }
}

// Classe para configurações de captura
class ScreenshotConfig {
  final double quality;
  final String format;
  final bool includeSystemUI;
  final String albumName;

  const ScreenshotConfig({
    this.quality = 1.0,
    this.format = 'png',
    this.includeSystemUI = true,
    this.albumName = 'Screenshots',
  });
}

// Enum para tipos de captura
enum ScreenshotType {
  fullScreen,
  currentApp,
  specificWidget,
}

// Classe para resultado da captura
class ScreenshotResult {
  final bool success;
  final String? filePath;
  final String? error;
  final DateTime timestamp;

  ScreenshotResult({
    required this.success,
    this.filePath,
    this.error,
    required this.timestamp,
  });
}
