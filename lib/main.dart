import 'dart:io';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import 'game/game.dart';
import 'game/hud_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MaterialApp(home: GamePage()));
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late SoulKnightGame _game;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _game = SoulKnightGame();
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: isMobile ? _buildMobileLayout() : _buildPcLayout(),
    );
  }

  Widget _buildPcLayout() {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (event) {
        _game.onKeyEvent(event, HardwareKeyboard.instance.logicalKeysPressed);
      },
      child: GameWidget(game: _game),
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // 游戏画布
        GameWidget(game: _game),

        // HUD层
        HUDOverlay(game: _game),

        // 左下角固定摇杆底座
        const Positioned(left: 15, bottom: 15, child: _FixedJoystickBase()),

        // 右下角技能按钮
        _SkillButtonsOverlay(game: _game),

        // 触控手势层
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (d) => _onPanStart(d.localPosition),
            onPanUpdate: (d) => _onPanUpdate(d.localPosition),
            onPanEnd: (_) => _onPanEnd(),
            onTapDown: (d) => _onTapDown(d.localPosition),
            child: Container(color: Colors.transparent),
          ),
        ),

        // HUD刷新定时器（每200ms强制刷新）
        if (_initialized)
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: _HUFTimer(game: _game),
            ),
          ),
      ],
    );
  }

  void _onPanStart(Offset pos) {
    final y = pos.dy;
    if (y > 420) return; // 底部按钮区域

    if (pos.dx < 288) {
      TouchInputUpdate.instance.joystickCenter = Vector2(pos.dx, pos.dy);
      TouchInputUpdate.instance.isDragging = true;
      TouchInputUpdate.instance.update();
      _calcJoystick(pos.dx, pos.dy);
    } else {
      TouchInputUpdate.instance.isLongPress = true;
      _game.playerForceFire();
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

  void _onTapDown(Offset pos) {
    if (pos.dx >= 288) {
      _game.playerForceFire();
    }
  }
}

/// 强制刷新HUD的定时器Widget
class _HUFTimer extends StatefulWidget {
  final SoulKnightGame game;
  const _HUFTimer({required this.game});
  @override
  State<_HUFTimer> createState() => _HUFTimerState();
}

class _HUFTimerState extends State<_HUFTimer> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        HUDFresher.instance.refresh();
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// 固定摇杆底座
class _FixedJoystickBase extends StatefulWidget {
  const _FixedJoystickBase();
  @override
  State<_FixedJoystickBase> createState() => _FixedJoystickBaseState();
}

class _FixedJoystickBaseState extends State<_FixedJoystickBase> {
  @override
  void initState() {
    super.initState();
    TouchInputUpdate.instance.addListener(_onUpdate);
  }
  @override
  void dispose() {
    TouchInputUpdate.instance.removeListener(_onUpdate);
    super.dispose();
  }
  void _onUpdate() { if (mounted) setState(() {}); }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130, height: 130,
      child: CustomPaint(painter: _JoystickBasePainter()),
    );
  }
}

class _JoystickBasePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const baseR = 55.0;

    // 半透明底座
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

    // 摇杆位置
    final dir = TouchInput.touchDirection;
    final isDragging = TouchInputUpdate.instance.isDragging;
    if (dir.length > 0.1 && isDragging) {
      const knobR = 25.0;
      const maxR = 40.0;
      canvas.drawCircle(
        Offset(cx + dir.x * maxR, cy + dir.y * maxR), knobR,
        Paint()..color = Colors.white.withAlpha(140),
      );
    } else {
      canvas.drawCircle(
        Offset(cx, cy), 8,
        Paint()..color = Colors.white.withAlpha(60),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 技能按钮
class _SkillButtonsOverlay extends StatelessWidget {
  final SoulKnightGame game;
  const _SkillButtonsOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    // 技能按钮已整合到HUDOverlay底部
    // 这里只显示武器切换按钮
    return const SizedBox.shrink();
  }
}

/// 全局触摸状态
class TouchInput {
  static Vector2 touchDirection = Vector2.zero();
  static bool isFiring = false;
  static bool isDragging = false;
  static bool isLongPress = false;

  static void reset() {
    touchDirection = Vector2.zero();
    isFiring = false;
    isDragging = false;
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

  void update() { notifyListeners(); }
}