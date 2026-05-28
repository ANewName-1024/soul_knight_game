import 'dart:io';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import 'game/game.dart';
import 'game/hud_overlay.dart';
import 'game/game_screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MaterialApp(home: GamePage()));
}

enum GameState { start, playing, paused, gameOver, victory, levelTransition }

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late SoulKnightGame _game;
  bool _initialized = false;
  GameState _state = GameState.start;
  int _currentLevel = 1;
  int _lastKillCount = 0;
  int _lastWave = 1;
  int _transitionLevel = 1;

  @override
  void initState() {
    super.initState();
    _game = SoulKnightGame();
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case GameState.start:
        return StartScreen(onStart: _startGame);
      case GameState.paused:
        return _buildGameWithOverlay(child: PauseOverlay(
          onResume: _resumeGame,
          onRestart: _restartGame,
          onQuit: _quitGame,
        ));
      case GameState.gameOver:
        return _buildGameWithOverlay(child: GameOverOverlay(
          killCount: _lastKillCount, waveReached: _lastWave,
          onRestart: _restartGame, onQuit: _quitGame,
        ));
      case GameState.victory:
        return _buildGameWithOverlay(child: VictoryOverlay(
          killCount: _lastKillCount, waveReached: _lastWave,
          onNextLevel: _nextLevel, onQuit: _quitGame,
        ));
      case GameState.levelTransition:
        return _buildGameWithOverlay(child: LevelTransition(
          level: _transitionLevel,
          onComplete: () => setState(() => _state = GameState.playing),
        ));
      case GameState.playing:
        return _buildCurrentLayout();
    }
  }

  Widget _buildCurrentLayout() {
    final isMobile = !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux;
    if (isMobile) {
      return Stack(children: [
        GameWidget(game: _game),
        HUDOverlay(game: _game),
        Positioned(top: 8, right: 8, child: _PauseButton(onTap: _pauseGame)),
        const Positioned(left: 15, bottom: 15, child: _FixedJoystickBase()),
        Positioned.fill(child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onTapDown: _onTapDown,
          child: Container(color: Colors.transparent),
        )),
      ]);
    } else {
      return KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (event) {
          _game.onKeyEvent(event, HardwareKeyboard.instance.logicalKeysPressed);
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyP) _pauseGame();
        },
        child: Stack(children: [
          GameWidget(game: _game),
          HUDOverlay(game: _game),
          Positioned(top: 8, right: 8, child: _PauseButton(onTap: _pauseGame)),
        ]),
      );
    }
  }

  Widget _buildGameWithOverlay({required Widget child}) {
    final isMobile = !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux;
    if (isMobile) {
      return Stack(children: [GameWidget(game: _game), child]);
    } else {
      return KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyP) {
            if (_state == GameState.paused) _resumeGame();
          }
        },
        child: Stack(children: [GameWidget(game: _game), child]),
      );
    }
  }

  void _startGame() {
    _currentLevel = 1;
    _game.reset();
    setState(() => _state = GameState.playing);
  }

  void _pauseGame() {
    _lastKillCount = _game.killCount;
    _lastWave = _game.waveNumber;
    setState(() => _state = GameState.paused);
  }

  void _resumeGame() { setState(() => _state = GameState.playing); }

  void _restartGame() {
    _currentLevel = 1;
    _game.reset();
    setState(() => _state = GameState.playing);
  }

  void _nextLevel() {
    _currentLevel++;
    _game.startNextLevel();
    setState(() => _state = GameState.playing);
  }

  void _quitGame() { setState(() => _state = GameState.start); }

  void _onPanStart(DragStartDetails d) {
    final pos = d.localPosition;
    if (pos.dy > 420) return;
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

  void _onPanUpdate(DragUpdateDetails d) {
    if (!TouchInputUpdate.instance.isDragging) return;
    _calcJoystick(d.localPosition.dx, d.localPosition.dy);
  }

  void _onPanEnd(DragEndDetails d) {
    TouchInputUpdate.instance.isDragging = false;
    TouchInputUpdate.instance.isLongPress = false;
    TouchInput.touchDirection = Vector2.zero();
    TouchInputUpdate.instance.update();
  }

  void _onTapDown(TapDownDetails d) {
    if (d.localPosition.dx >= 288) _game.playerForceFire();
  }

  void _calcJoystick(double dx, double dy) {
    final jc = TouchInputUpdate.instance.joystickCenter;
    final ddx = dx - jc.x;
    final ddy = dy - jc.y;
    final dist = ddx * ddx + ddy * ddy;
    if (dist < 100) { TouchInput.touchDirection = Vector2.zero(); return; }
    final len = dist > 2500 ? 50.0 : dist / 50.0;
    final dir = Vector2(ddx, ddy)..normalize();
    TouchInput.touchDirection = dir * (len / 50.0);
    TouchInputUpdate.instance.update();
  }
}

class _PauseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PauseButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white70, width: 1.5),
        ),
        child: const Icon(Icons.pause, color: Colors.white70, size: 20),
      ),
    );
  }
}

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
    canvas.drawCircle(Offset(cx, cy), 55, Paint()..color = Colors.white.withAlpha(20));
    canvas.drawCircle(Offset(cx, cy), 55, Paint()..color = Colors.white.withAlpha(50)..style = PaintingStyle.stroke..strokeWidth = 2);
    final dir = TouchInput.touchDirection;
    final isDragging = TouchInputUpdate.instance.isDragging;
    if (dir.length > 0.1 && isDragging) {
      canvas.drawCircle(Offset(cx + dir.x * 40, cy + dir.y * 40), 25, Paint()..color = Colors.white.withAlpha(140));
    } else {
      canvas.drawCircle(Offset(cx, cy), 8, Paint()..color = Colors.white.withAlpha(60));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}