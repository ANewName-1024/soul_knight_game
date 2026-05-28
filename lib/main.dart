import 'dart:io';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import 'game/game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MaterialApp(home: GamePage()));
}

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = SoulKnightGame();
    final isMobile = !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: isMobile ? _buildMobileLayout(game) : _buildPcLayout(game),
    );
  }

  Widget _buildPcLayout(SoulKnightGame game) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (event) {
        game.onKeyEvent(event, HardwareKeyboard.instance.logicalKeysPressed);
      },
      child: GameWidget(game: game),
    );
  }

  Widget _buildMobileLayout(SoulKnightGame game) {
    return Stack(
      children: [
        GameWidget(game: game),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (d) => _onPanStart(d.localPosition, constraints),
                onPanUpdate: (d) => _onPanUpdate(d.localPosition, constraints),
                onPanEnd: (_) => _onPanEnd(),
                onTapDown: (d) => _onTapDown(d.localPosition),
                child: Container(color: Colors.transparent),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onPanStart(Offset pos, BoxConstraints constraints) {
    final scale = constraints.maxHeight / 480;
    final x = pos.dx / scale;
    
    if (x < 288) {
      TouchInput.joystickCenter = Vector2(80 * scale, 400 * scale);
      TouchInput.isDragging = true;
      _calcJoystick((pos.dx - TouchInput.joystickCenter.x) / scale, (pos.dy - TouchInput.joystickCenter.y) / scale);
    } else {
      TouchInput.isFiring = true;
    }
  }

  void _onPanUpdate(Offset pos, BoxConstraints constraints) {
    if (!TouchInput.isDragging) return;
    final scale = constraints.maxHeight / 480;
    _calcJoystick((pos.dx - TouchInput.joystickCenter.x) / scale, (pos.dy - TouchInput.joystickCenter.y) / scale);
  }

  void _calcJoystick(double dx, double dy) {
    final dist = dx * dx + dy * dy;
    if (dist < 100) {
      TouchInput.touchDirection = Vector2.zero();
      return;
    }
    final len = dist > 2500 ? 50.0 : dist / 50.0;
    final normalized = len / 50.0;
    final dir = Vector2(dx, dy)..normalize();
    TouchInput.touchDirection = dir * normalized;
  }

  void _onPanEnd() {
    TouchInput.isDragging = false;
    TouchInput.touchDirection = Vector2.zero();
  }

  void _onTapDown(Offset pos) {
    final gameScale = 288 / pos.dx;
    if (pos.dx >= 288) {
      TouchInput.isFiring = true;
      Future.delayed(const Duration(milliseconds: 150), () {
        TouchInput.isFiring = false;
      });
    }
  }
}

class TouchInput {
  static Vector2 touchDirection = Vector2.zero();
  static Vector2 joystickCenter = Vector2.zero();
  static bool isFiring = false;
  static bool isDragging = false;
  
  static void reset() {
    touchDirection = Vector2.zero();
    isFiring = false;
    isDragging = false;
  }
}