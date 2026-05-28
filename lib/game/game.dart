import 'dart:math';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/game_constants.dart';
import 'components/player.dart';

class SoulKnightGame extends FlameGame<World>
    with HasKeyboardHandlerComponents, TapCallbacks {
  final Vector2 gameSize = Vector2(
    GameConstants.gameWidth,
    GameConstants.gameHeight,
  );

  late Player player;
  final Random _random = Random();
  double _enemySpawnTimer = 0;
  final Set<LogicalKeyboardKey> _keysPressed = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 设置固定尺寸视口（游戏逻辑分辨率）
    camera.viewport = FixedSizeViewport(gameSize.x, gameSize.y);
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();

    // 背景色（深色地牢风格）
    add(RectangleComponent(
      position: Vector2.zero(),
      size: gameSize,
      paint: Paint()..color = const Color(0xFF1A1A2E),
    ));

    player = Player(position: gameSize / 2);
    add(player);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _handleMovement(dt);

    _enemySpawnTimer += dt;
    if (_enemySpawnTimer >= GameConstants.enemySpawnInterval) {
      _enemySpawnTimer = 0;
      _spawnEnemy();
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      _keysPressed.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _keysPressed.remove(event.logicalKey);
    }
    return super.onKeyEvent(event, keysPressed);
  }

  void _handleMovement(double dt) {
    double dx = 0, dy = 0;
    if (_keysPressed.contains(LogicalKeyboardKey.keyW) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      dy -= 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyS) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      dy += 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyA) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      dx -= 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyD) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      dx += 1;
    }
    if (dx != 0 || dy != 0) {
      final dir = Vector2(dx, dy)..normalize();
      player.move(dir * GameConstants.playerSpeed * dt);
    }
  }

  void _spawnEnemy() {
    final side = _random.nextInt(4);
    Vector2 pos;
    switch (side) {
      case 0:
        pos = Vector2(
            _random.nextDouble() * GameConstants.gameWidth, -GameConstants.enemySize);
        break;
      case 1:
        pos = Vector2(
            GameConstants.gameWidth + GameConstants.enemySize,
            _random.nextDouble() * GameConstants.gameHeight);
        break;
      case 2:
        pos = Vector2(
            _random.nextDouble() * GameConstants.gameWidth,
            GameConstants.gameHeight + GameConstants.enemySize);
        break;
      default:
        pos = Vector2(
            -GameConstants.enemySize,
            _random.nextDouble() * GameConstants.gameHeight);
        break;
    }
    add(Enemy(position: pos, target: player));
  }

  void addBullet(Vector2 position, Vector2 direction) {
    add(Bullet(position: position, direction: direction));
  }

  void onEnemyKilled() {}
  void onPlayerDamaged() {}
}