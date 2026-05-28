import 'dart:io';
import 'dart:math' show Random, atan2, cos, sin;
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import '../core/constants/game_constants.dart';
import 'components/player.dart';
import 'components/weapon.dart';

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
  
  static bool get isMobile =>
      !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux;
  
  final List<Skill> skills = [
    Skill(cooldown: 5.0, name: 'Shield'),
    Skill(cooldown: 8.0, name: 'Blast'),
    Skill(cooldown: 12.0, name: 'Speed'),
    Skill(cooldown: 30.0, name: 'Barrage'),
  ];

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
    player.weapon = Pistol();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isMobile) {
      _handleKeyboardMovement(dt);
      _handleKeyboardShoot(dt);
    } else {
      _handleTouchMovement(dt);
    }
    
    for (final skill in skills) skill.update(dt);

    _enemySpawnTimer += dt;
    if (_enemySpawnTimer >= GameConstants.enemySpawnInterval) {
      _enemySpawnTimer = 0;
      _spawnEnemy();
    }
  }

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
  
  void _handleKeyboardShoot(double dt) {
    _pcFireTimer -= dt;
    if (_pcFireTimer <= 0 && player.weapon != null) {
      _pcFireTimer = player.weapon!.finalFireRate;
      player.forceFireTowardsNearest();
    }
  }
  
  void _handleTouchMovement(double dt) {
    if (!isMobile) return;
    if (TouchInput.isDragging && TouchInput.touchDirection.length > 0.1) {
      player.move(TouchInput.touchDirection.clone() * GameConstants.playerSpeed * dt);
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      _keysPressed.add(event.logicalKey);
      if (event.logicalKey == LogicalKeyboardKey.keyQ) triggerSkill(0);
      if (event.logicalKey == LogicalKeyboardKey.keyW && !isMobile) triggerSkill(1);
      if (event.logicalKey == LogicalKeyboardKey.keyE) triggerSkill(2);
      if (event.logicalKey == LogicalKeyboardKey.keyR) triggerSkill(3);
      if (event.logicalKey == LogicalKeyboardKey.keyX) player.switchWeapon();
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
    final isElite = _random.nextDouble() < 0.2;
    add(Enemy(position: pos, target: player, isElite: isElite));
  }

  void addBullet(Vector2 position, Vector2 direction, [int damage = 1, int penetrate = 0, double speedBonus = 0]) {
    add(Bullet(position: position, direction: direction, damage: damage, penetrate: penetrate, speedBonus: speedBonus));
  }
  
  void addMagicBullet(Vector2 position, Vector2 direction, [int damage = 2]) {
    add(MagicBullet(position: position, direction: direction, damage: damage));
  }
  
  void addMissileBullet(Vector2 position, Vector2 direction, [int damage = 3]) {
    add(MissileBullet(position: position, direction: direction, damage: damage));
  }

  void onEnemyKilled() {}
  void onPlayerDamaged() {}
  
  void triggerSkill(int index) {
    if (index < 0 || index >= skills.length) return;
    final skill = skills[index];
    if (!skill.canUse()) {
      debugPrint('Skill ${skill.name} on cooldown: ${skill.cooldownRemaining.toStringAsFixed(1)}s');
      return;
    }
    skill.use();
    _activateSkill(index);
  }
  
  void _activateSkill(int index) {
    switch (index) {
      case 0: player.activeShield = true; break;
      case 1: _doBlastWave(); break;
      case 2:
        player.speedBoost = true;
        player.speedBoostTimer = 3.0;
        break;
      case 3: _doBarrage(); break;
    }
  }
  
  void _doBlastWave() {
    const blastRadius = 150.0;
    for (final enemy in children.query<Enemy>()) {
      final dist = (enemy.position - player.position).length;
      if (dist < blastRadius) {
        final dir = (enemy.position - player.position)..normalize();
        enemy.position += dir * 50;
      }
    }
  }
  
  void _doBarrage() {
    const count = 12;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 6.28318;
      final dir = Vector2(cos(angle), sin(angle));
      addBullet(player.position.clone(), dir, 1, 0);
    }
  }
  
  void playerForceFire() {
    player.forceFireTowardsNearest();
    if (TouchInput.isLongPress) TouchInput.isFiring = true;
  }
  
  String get weaponName => player.weaponName;
  int get ammo => player.ammo;
  double get fireCooldown => player.fireCooldown;
}

class Skill {
  final String name;
  final double cooldown;
  double currentCooldown = 0;
  
  Skill({required this.cooldown, required this.name});
  
  bool canUse() => currentCooldown <= 0;
  void use() { currentCooldown = cooldown; }
  void update(double dt) { if (currentCooldown > 0) currentCooldown -= dt; }
  double get cooldownRemaining => currentCooldown > 0 ? currentCooldown : 0;
}

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

class TouchInputUpdate extends ChangeNotifier {
  static final instance = TouchInputUpdate._();
  TouchInputUpdate._();
  
  Vector2 joystickCenter = Vector2.zero();
  bool isDragging = false;
  bool isLongPress = false;
  
  void update() { notifyListeners(); }
}