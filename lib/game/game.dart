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
  
  static bool get isMobile => !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux;
  
  /// 技能系统
  final List<Skill> skills = [
    Skill(cooldown: 5.0, name: 'Shield'),    // Q - 护盾
    Skill(cooldown: 8.0, name: 'Blast'),     // W - 冲击波
    Skill(cooldown: 12.0, name: 'Speed'),    // E - 加速
    Skill(cooldown: 30.0, name: 'Barrage'),  // R - 弹幕风暴
  ];
  
  /// 触摸射击方向（右侧屏幕射击朝向）
  Vector2 _touchShootDirection = Vector2(0, -1);
  
  double _touchFireTimer = 0;
  
  // PC模式射击计时器
  double _pcFireTimer = 0;

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
      _handlePcAutoFire(dt);
    } else {
      _handleTouchMovement(dt);
      _handleTouchFire(dt);
    }
    
    // 更新技能冷却
    for (final skill in skills) {
      skill.update(dt);
    }

    _enemySpawnTimer += dt;
    if (_enemySpawnTimer >= GameConstants.enemySpawnInterval) {
      _enemySpawnTimer = 0;
      _spawnEnemy();
    }
  }

  // ==================== PC输入 ====================
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
  
  void _handlePcAutoFire(double dt) {
    _pcFireTimer -= dt;
    if (_pcFireTimer <= 0) {
      _pcFireTimer = GameConstants.fireRate;
      player.forceFireTowardsNearest();
    }
  }
  
  // ==================== 移动端输入 ====================
  void _handleTouchMovement(double dt) {
    if (!isMobile) return;
    
    if (TouchInput.isDragging && TouchInput.touchDirection.length > 0.1) {
      player.move(TouchInput.touchDirection.clone() * GameConstants.playerSpeed * dt);
    }
  }
  
  void _handleTouchFire(double dt) {
    if (!isMobile) return;
    
    // 长按连射
    if (TouchInput.isLongPress) {
      _touchFireTimer -= dt;
      if (_touchFireTimer <= 0) {
        _touchFireTimer = GameConstants.fireRate;
        player.forceFireTowardsNearest();
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      _keysPressed.add(event.logicalKey);
      // 技能快捷键
      if (event.logicalKey == LogicalKeyboardKey.keyQ) triggerSkill(0);
      if (event.logicalKey == LogicalKeyboardKey.keyW) triggerSkill(1);
      if (event.logicalKey == LogicalKeyboardKey.keyE) triggerSkill(2);
      if (event.logicalKey == LogicalKeyboardKey.keyR) triggerSkill(3);
    } else if (event is KeyUpEvent) {
      _keysPressed.remove(event.logicalKey);
    }
    return super.onKeyEvent(event, keysPressed);
  }

  void _spawnEnemy() {
    final side = _random.nextInt(4);
    Vector2 pos;
    switch (side) {
      case 0: pos = Vector2(_random.nextDouble() * GameConstants.gameWidth, -GameConstants.enemySize); break;
      case 1: pos = Vector2(GameConstants.gameWidth + GameConstants.enemySize, _random.nextDouble() * GameConstants.gameHeight); break;
      case 2: pos = Vector2(_random.nextDouble() * GameConstants.gameWidth, GameConstants.gameHeight + GameConstants.enemySize); break;
      default: pos = Vector2(-GameConstants.enemySize, _random.nextDouble() * GameConstants.gameHeight);
    }
    add(Enemy(position: pos, target: player));
  }

  void addBullet(Vector2 position, Vector2 direction) {
    add(Bullet(position: position, direction: direction));
  }

  void onEnemyKilled() {}
  void onPlayerDamaged() {}
  
  // ==================== 技能系统 ====================
  void triggerSkill(int index) {
    if (index < 0 || index >= skills.length) return;
    final skill = skills[index];
    if (!skill.canUse()) {
      debugPrint('Skill ${skill.name} on cooldown: ${skill.cooldownRemaining.toStringAsFixed(1)}s');
      return;
    }
    skill.use();
    _activateSkill(index);
    debugPrint('Skill activated: ${skill.name}');
  }
  
  void _activateSkill(int index) {
    switch (index) {
      case 0: // Q - 护盾：抵挡一次伤害
        player.activeShield = true;
        break;
      case 1: // W - 冲击波：推开周围敌人
        _doBlastWave();
        break;
      case 2: // E - 加速：提升移速3秒
        player.speedBoost = true;
        player.speedBoostTimer = 3.0;
        break;
      case 3: // R - 弹幕风暴：8方向射出多发子弹
        _doBarrage();
        break;
    }
  }
  
  void _doBlastWave() {
    const blastRadius = 150.0;
    for (final enemy in children.query<Enemy>()) {
      final dist = (enemy.position - player.position).length;
      if (dist < blastRadius) {
        final dir = (enemy.position - player.position)..normalize();
        enemy.position += dir * 50;  // 推开50像素
      }
    }
  }
  
  void _doBarrage() {
    const count = 12;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 3.14159265 * 2;
      final dir = Vector2(dirX(angle), dirY(angle));
      addBullet(player.position.clone(), dir);
    }
  }
  
  double dirX(double angle) => (angle == 0) ? 1.0 : (angle - 3.14159265 / 2).abs() < 0.01 ? 0.0 : 
      (angle - 3.14159265 / 2).abs() < 3.14159265 / 2 ? 1.0 : -1.0;
  double dirY(double angle) => (angle == 0) ? 0.0 : (angle - 3.14159265 / 2).abs() < 0.01 ? 1.0 : 
      (angle - 3.14159265 / 2).abs() < 3.14159265 / 2 ? 0.0 : -1.0;
  
  void playerForceFire() {
    player.forceFireTowardsNearest();
  }
}

/// 技能数据
class Skill {
  final String name;
  final double cooldown;  // 秒
  double currentCooldown = 0;
  
  Skill({required this.cooldown, required this.name});
  
  bool canUse() => currentCooldown <= 0;
  
  void use() {
    currentCooldown = cooldown;
  }
  
  void update(double dt) {
    if (currentCooldown > 0) {
      currentCooldown -= dt;
    }
  }
  
  double get cooldownRemaining => currentCooldown > 0 ? currentCooldown : 0;
}

/// 全局触摸状态
class TouchInput {
  static Vector2 touchDirection = Vector2.zero();
  static Vector2 joystickCenter = Vector2.zero();
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