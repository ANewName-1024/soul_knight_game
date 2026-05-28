import 'dart:io';
import 'dart:math' show Random;
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
  
  /// 是否为移动端
  static bool get isMobile => !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux;
  
  /// 触摸输入方向
  Vector2 touchDirection = Vector2.zero();
  
  /// 是否触摸射击
  bool touchFiring = false;
  
  /// 摇杆中心
  Vector2 joystickCenter = Vector2(80, 400);
  
  /// 是否在拖动
  bool isDragging = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewport = FixedSizeViewport(gameSize.x, gameSize.y);
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();

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
    
    if (!isMobile) {
      _handleKeyboardMovement(dt);
    } else {
      _handleTouchMovement(dt);
    }

    _enemySpawnTimer += dt;
    if (_enemySpawnTimer >= GameConstants.enemySpawnInterval) {
      _enemySpawnTimer = 0;
      _spawnEnemy();
    }
  }

  // PC键盘移动
  void _handleKeyboardMovement(double dt) {
    double dx = 0, dy = 0;
    if (_keysPressed.contains(LogicalKeyboardKey.keyW) || _keysPressed.contains(LogicalKeyboardKey.arrowUp)) dy -= 1;
    if (_keysPressed.contains(LogicalKeyboardKey.keyS) || _keysPressed.contains(LogicalKeyboardKey.arrowDown)) dy += 1;
    if (_keysPressed.contains(LogicalKeyboardKey.keyA) || _keysPressed.contains(LogicalKeyboardKey.arrowLeft)) dx -= 1;
    if (_keysPressed.contains(LogicalKeyboardKey.keyD) || _keysPressed.contains(LogicalKeyboardKey.arrowRight)) dx += 1;
    if (dx != 0 || dy != 0) {
      final dir = Vector2(dx, dy)..normalize();
      player.move(dir * GameConstants.playerSpeed * dt);
    }
  }

  // 移动端触摸移动
  void _handleTouchMovement(double dt) {
    if (!isMobile || !isDragging) return;
    
    if (touchDirection.length > 0.1) {
      player.move(touchDirection * GameConstants.playerSpeed * dt);
    }
    
    // 触摸射击
    if (touchFiring && touchDirection.length < 0.5) {
      player.forceFire();
      touchFiring = false;
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

  void _spawnEnemy() {
    final side = _random.nextInt(4);
    Vector2 pos;
    switch (side) {
      case 0:
        pos = Vector2(_random.nextDouble() * GameConstants.gameWidth, -GameConstants.enemySize);
        break;
      case 1:
        pos = Vector2(GameConstants.gameWidth + GameConstants.enemySize, _random.nextDouble() * GameConstants.gameHeight);
        break;
      case 2:
        pos = Vector2(_random.nextDouble() * GameConstants.gameWidth, GameConstants.gameHeight + GameConstants.enemySize);
        break;
      default:
        pos = Vector2(-GameConstants.enemySize, _random.nextDouble() * GameConstants.gameHeight);
    }
    add(Enemy(position: pos, target: player));
  }

  void addBullet(Vector2 position, Vector2 direction) {
    add(Bullet(position: position, direction: direction));
  }

  void onEnemyKilled() {}
  void onPlayerDamaged() {}
}