import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/screenshot_service.dart';

class OverlayWidget extends StatefulWidget {
  @override
  _OverlayWidgetState createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget>
    with SingleTickerProviderStateMixin {
  final ScreenshotService _screenshotService = ScreenshotService();
  bool _isCapturing = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.green,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Função principal para capturar screenshot
  Future<void> _takeScreenshot() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Animação de feedback visual
      _animationController.forward();

      // Vibração para feedback tátil
      HapticFeedback.mediumImpact();

      // Pequeno delay para mostrar a animação
      await Future.delayed(Duration(milliseconds: 150));

      // Captura o screenshot
      await _screenshotService.takeScreenshot();

      // Feedback de sucesso
      await _showSuccessAnimation();
    } catch (e) {
      print('Erro ao capturar screenshot no overlay: $e');
      await _showErrorAnimation();
    } finally {
      setState(() {
        _isCapturing = false;
      });

      // Reseta a animação
      _animationController.reverse();
    }
  }

  // Animação de sucesso
  Future<void> _showSuccessAnimation() async {
    HapticFeedback.lightImpact();

    // Pisca verde rapidamente
    for (int i = 0; i < 2; i++) {
      await Future.delayed(Duration(milliseconds: 100));
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Animação de erro
  Future<void> _showErrorAnimation() async {
    HapticFeedback.heavyImpact();

    // Vibra indicando erro
    await Future.delayed(Duration(milliseconds: 200));
  }

  // Fecha o overlay quando pressionado longamente
  Future<void> _onLongPress() async {
    try {
      HapticFeedback.heavyImpact();

      // Mostra dialog de confirmação (simplificado)
      await _showCloseConfirmation();
    } catch (e) {
      print('Erro ao tentar fechar overlay: $e');
    }
  }

  Future<void> _showCloseConfirmation() async {
    // Feedback visual de que foi pressionado longamente
    _animationController.forward();
    await Future.delayed(Duration(milliseconds: 300));
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          onTap: _isCapturing ? null : _takeScreenshot,
          onLongPress: _onLongPress,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isCapturing
                        ? _colorAnimation.value
                        : Colors.blue.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                      BoxShadow(
                        color:
                            (_isCapturing ? _colorAnimation.value : Colors.blue)
                                    ?.withOpacity(0.3) ??
                                Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ícone principal
                      if (!_isCapturing)
                        Icon(
                          Icons.screenshot,
                          color: Colors.white,
                          size: 35,
                        ),

                      // Loading quando está capturando
                      if (_isCapturing)
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),

                      // Indicador de toque longo (pequeno ponto)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Widget alternativo mais simples (caso o primeiro dê problema)
class SimpleOverlayWidget extends StatelessWidget {
  final ScreenshotService _screenshotService = ScreenshotService();

  Future<void> _takeScreenshot() async {
    try {
      HapticFeedback.mediumImpact();
      await _screenshotService.takeScreenshot();
    } catch (e) {
      print('Erro ao capturar screenshot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          onTap: _takeScreenshot,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.screenshot,
              color: Colors.white,
              size: 35,
            ),
          ),
        ),
      ),
    );
  }
}
