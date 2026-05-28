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
        
        // 固定显示的摇杆底座（左下角）
        const Positioned(left: 15, bottom: 15, child: _FixedJoystickBase()),
        
        // 右下角技能按钮
        _SkillButtonsOverlay(game: game),
        
        // 触控手势层
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (d) => _onPanStart(d.localPosition, game),
            onPanUpdate: (d) => _onPanUpdate(d.localPosition),
            onPanEnd: (_) => _onPanEnd(),
            onTapDown: (d) => _onTapDown(d.localPosition, game),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  void _onPanStart(Offset pos, SoulKnightGame game) {
    final x = pos.dx;
    final y = pos.dy;
    
    // 底部按钮区域跳过
    if (y > 420) return;
    
    if (x < 288) {
      TouchInputUpdate.instance.joystickCenter = Vector2(pos.dx, pos.dy);
      TouchInputUpdate.instance.isDragging = true;
      TouchInputUpdate.instance.update();
      _calcJoystick(pos.dx, pos.dy);
    } else {
      TouchInputUpdate.instance.isLongPress = true;
      game.playerForceFire();
    }
  }

  void _onPanUpdate(Offset pos) {
    if (!TouchInputUpdate.instance.isDragging) return;
    _calcJoystick(pos.dx, pos.dy);
  }

  void _calcJoystick(double dx, double dy) {
    final jc = TouchInputUpdate.instance.joystickCenter;
    final ddx = dx - jc.x;
    final ddy = dy - jc.y;
    final dist = ddx * ddx + ddy * ddy;
    
    if (dist < 100) {
      TouchInput.touchDirection = Vector2.zero();
      return;
    }
    
    final len = dist > 2500 ? 50.0 : dist / 50.0;
    final normalized = len / 50.0;
    final dir = Vector2(ddx, ddy)..normalize();
    TouchInput.touchDirection = dir * normalized;
    TouchInputUpdate.instance.update();
  }

  void _onPanEnd() {
    TouchInputUpdate.instance.isDragging = false;
    TouchInputUpdate.instance.isLongPress = false;
    TouchInput.touchDirection = Vector2.zero();
    TouchInputUpdate.instance.update();
  }

  void _onTapDown(Offset pos, SoulKnightGame game) {
    if (pos.dx >= 288) {
      game.playerForceFire();
    }
  }
}

/// 固定显示的摇杆底座
class _FixedJoystickBase extends StatelessWidget {
  const _FixedJoystickBase();
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130, height: 130,
      child: CustomPaint(
        painter: _JoystickBasePainter(),
      ),
    );
  }
}

class _JoystickBasePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const baseR = 55.0;
    
    canvas.drawCircle(
      Offset(cx, cy), baseR,
      Paint()..color = Colors.white.withAlpha(20),
    );
    canvas.drawCircle(
      Offset(cx, cy), baseR,
      Paint()
        ..color = Colors.white.withAlpha(50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    
    // 绘制当前摇杆位置
    final dir = TouchInput.touchDirection;
    if (dir.length > 0.1 && TouchInputUpdate.instance.isDragging) {
      const knobR = 25.0;
      const maxR = 40.0;
      final knobX = dir.x * maxR;
      final knobY = dir.y * maxR;
      canvas.drawCircle(
        Offset(cx + knobX, cy + knobY), knobR,
        Paint()..color = Colors.white.withAlpha(140),
      );
    } else {
      // 中心点
      canvas.drawCircle(
        Offset(cx, cy), 8,
        Paint()..color = Colors.white.withAlpha(60),
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant _JoystickBasePainter old) => true;
}

/// 右下角技能按钮
class _SkillButtonsOverlay extends StatelessWidget {
  final SoulKnightGame game;
  const _SkillButtonsOverlay({required this.game});
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 15,
      bottom: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SkillButton(
            label: 'R', color: Colors.purple,
            onTap: () => game.triggerSkill(3),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SkillButton(label: 'Q', color: Colors.blue, onTap: () => game.triggerSkill(0)),
              const SizedBox(width: 10),
              _SkillButton(label: 'W', color: Colors.green, onTap: () => game.triggerSkill(1)),
              const SizedBox(width: 10),
              _SkillButton(label: 'E', color: Colors.orange, onTap: () => game.triggerSkill(2)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  const _SkillButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45, height: 45,
        decoration: BoxDecoration(
          color: color.withAlpha(180),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withAlpha(100), width: 2),
        ),
        child: Center(
          child: Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
          )),
        ),
      ),
    );
  }
}

/// 全局触摸状态
class TouchInput {
  static Vector2 touchDirection = Vector2.zero();
  static bool isFiring = false;
  static bool isLongPress = false;
  
  static void reset() {
    touchDirection = Vector2.zero();
    isFiring = false;
    isLongPress = false;
  }
}

/// 触摸更新通知器
class TouchInputUpdate extends ChangeNotifier {
  static final instance = TouchInputUpdate._();
  TouchInputUpdate._();
  
  Vector2 joystickCenter = Vector2.zero();
  bool isDragging = false;
  bool isLongPress = false;
  
  void update() {
    notifyListeners();
  }
}