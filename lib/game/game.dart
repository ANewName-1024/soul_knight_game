import 'dart:io';
import 'dart:math' show Random, atan2, cos, sin;
import 'package:flame/collisions.dart';
import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
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
  int _waveNumber = 1;
  int _enemiesKilledThisWave = 0;
  
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

    _spawnInitialEnemies();
  }

  /// 重置游戏（重新开始）
  void reset() {
    // 移除所有敌人和子弹
    final toRemove = children.toList();
    for (final c in toRemove) {
      if (c is Enemy || c is Bullet || c is MagicBullet || c is MissileBullet || c is Coin || c is WeaponPickup || c is BossEnemy || c is EnemyBullet) {
        c.removeFromParent();
      }
    }
    // 重置玩家
    player.reset();
    player.weapon = Pistol();
    // 重置波次
    _waveNumber = 1;
    _enemiesKilledThisWave = 0;
    killCount = 0;
    // 重置技能
    for (final s in skills) { s.currentCooldown = 0; }
    _spawnInitialEnemies();
  }

  /// 下一关
  void startNextLevel() {
    final toRemove = children.toList();
    for (final c in toRemove) {
      if (c is Enemy || c is Bullet || c is MagicBullet || c is MissileBullet || c is Coin || c is WeaponPickup || c is BossEnemy || c is EnemyBullet) {
        c.removeFromParent();
      }
    }
    player.reset();
    player.weapon = Pistol();
    _enemiesKilledThisWave = 0;
    _spawnInitialEnemies();
  }

  void _spawnInitialEnemies() {
    for (int i = 0; i < 3; i++) {
      _spawnEnemy();
    }
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

    final typeRoll = _random.nextDouble();
    Enemy enemy;
    if (_waveNumber >= 3 && typeRoll < 0.25) {
      enemy = ShooterEnemy(position: pos, target: player, isElite: isElite, maxHp: 3);
    } else {
      enemy = ChaserEnemy(position: pos, target: player, isElite: isElite, maxHp: 2);
    }

    final hpScale = 1.0 + (_waveNumber - 1) * 0.2;
    enemy.hp = (enemy.hp * hpScale).ceil();

    add(enemy);
  }

  void addBullet(Vector2 position, Vector2 direction, [int damage = 1, int penetrate = 0, double speedBonus = 0]) {
    add(Bullet(position: position, direction: direction, damage: damage, penetrate: penetrate, speedBonus: speedBonus, owner: player));
  }
  
  void addMagicBullet(Vector2 position, Vector2 direction, [int damage = 2]) {
    add(MagicBullet(position: position, direction: direction, damage: damage, owner: player));
  }
  
  void addMissileBullet(Vector2 position, Vector2 direction, [int damage = 3]) {
    add(MissileBullet(position: position, direction: direction, damage: damage, owner: player));
  }

  int killCount = 0;
  
  void onEnemyKilled() { killCount++; _enemiesKilledThisWave++; }
  void onPlayerDamaged() {}

  void checkWaveProgress() {
    if (_enemiesKilledThisWave >= 10 + _waveNumber * 2) {
      _waveNumber++;
      _enemiesKilledThisWave = 0;
      if (_waveNumber % 3 == 0) _spawnBoss();
    }
  }

  void _spawnBoss() {
    final side = _random.nextInt(4);
    Vector2 pos;
    switch (side) {
      case 0: pos = Vector2(_random.nextDouble() * GameConstants.gameWidth, -60); break;
      case 1: pos = Vector2(GameConstants.gameWidth + 60, _random.nextDouble() * GameConstants.gameHeight); break;
      case 2: pos = Vector2(_random.nextDouble() * GameConstants.gameWidth, GameConstants.gameHeight + 60); break;
      default: pos = Vector2(-60, _random.nextDouble() * GameConstants.gameHeight);
    }
    add(BossEnemy(position: pos, target: player, hp: 30 + _waveNumber * 5, maxHp: 30 + _waveNumber * 5));
  }
  
  void triggerSkill(int index) {
    if (index < 0 || index >= skills.length) return;
    final skill = skills[index];
    if (!skill.canUse()) return;
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
  int get waveNumber => _waveNumber;
}

// ============ ENTITY CLASSES ============

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

// ============ BULLETS ============

class Bullet extends PositionComponent with HasGameReference<SoulKnightGame> {
  Vector2 direction;
  final double _speed;
  final int damage;
  final int penetrate;
  final Player owner;
  final bool isPlayerBullet;

  Bullet({
    required Vector2 position,
    required Vector2 direction,
    this.damage = 1,
    this.penetrate = 0,
    double speedBonus = 0,
    required this.owner,
    this.isPlayerBullet = true,
  }) : direction = direction.clone(),
       _speed = GameConstants.bulletSpeed * (1 + speedBonus) {
    size = Vector2.all(GameConstants.bulletSize);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFFFFEB3B),
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * _speed * dt;

    if (position.x < -50 || position.x > GameConstants.gameWidth + 50 ||
        position.y < -50 || position.y > GameConstants.gameHeight + 50) {
      removeFromParent();
      return;
    }

    if (isPlayerBullet) {
      for (final enemy in children.query<Enemy>()) {
        if (toRect().overlaps(enemy.toRect())) {
          enemy.takeDamage(damage);
          if (penetrate <= 0) { removeFromParent(); return; }
        }
      }
    }
  }

  void destroy() { removeFromParent(); }
}

class MagicBullet extends PositionComponent with HasGameReference<SoulKnightGame> {
  Vector2 direction;
  final double _speed = 200;
  final int damage;
  final double _maxDistance = 300;
  double _traveled = 0;
  final Player owner;

  MagicBullet({
    required Vector2 position,
    required Vector2 direction,
    this.damage = 2,
    required this.owner,
  }) : direction = direction.clone() {
    size = Vector2.all(12);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: 6));
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFFE91E63),
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    final delta = direction * _speed * dt;
    position += delta;
    _traveled += delta.length;

    if (_traveled >= _maxDistance) { _explode(); return; }
    if (position.x < -50 || position.x > GameConstants.gameWidth + 50 ||
        position.y < -50 || position.y > GameConstants.gameHeight + 50) {
      removeFromParent(); return;
    }
    
    for (final enemy in children.query<Enemy>()) {
      if (toRect().overlaps(enemy.toRect())) { _explode(); return; }
    }
  }

  void _explode() {
    const radius = 60.0;
    for (final enemy in children.query<Enemy>()) {
      final dist = (enemy.position - position).length;
      if (dist < radius) enemy.takeDamage(damage);
    }
    removeFromParent();
  }
}

class MissileBullet extends PositionComponent with HasGameReference<SoulKnightGame> {
  Vector2 direction;
  final double _speed = 250;
  final int damage;
  final double _turnRate = 3.0;
  final Player owner;

  MissileBullet({
    required Vector2 position,
    required Vector2 direction,
    this.damage = 3,
    required this.owner,
  }) : direction = direction.clone() {
    size = Vector2.all(10);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: 5));
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFFF44336),
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    final enemies = children.query<Enemy>();
    if (enemies.isNotEmpty) {
      Enemy? nearest;
      double minDist = double.infinity;
      for (final e in enemies) {
        final dist = (e.position - position).length;
        if (dist < minDist) { minDist = dist; nearest = e; }
      }
      
      if (nearest != null) {
        final targetDir = (nearest.position - position)..normalize();
        final currentAngle = atan2(direction.y, direction.x);
        final targetAngle = atan2(targetDir.y, targetDir.x);
        var angleDiff = targetAngle - currentAngle;
        while (angleDiff > 3.14159) angleDiff -= 6.28318;
        while (angleDiff < -3.14159) angleDiff += 6.28318;
        final maxTurn = _turnRate * dt;
        final turn = angleDiff.clamp(-maxTurn, maxTurn);
        direction = Vector2(cos(currentAngle + turn), sin(currentAngle + turn));
      }
    }

    position += direction * _speed * dt;

    if (position.x < -100 || position.x > GameConstants.gameWidth + 100 ||
        position.y < -100 || position.y > GameConstants.gameHeight + 100) {
      removeFromParent(); return;
    }
    
    for (final enemy in children.query<Enemy>()) {
      if (toRect().overlaps(enemy.toRect())) {
        enemy.takeDamage(damage);
        removeFromParent();
        return;
      }
    }
  }
}

// ============ ENEMIES ============

enum EnemyState { idle, chasing, shooting, dead }

class Enemy extends PositionComponent with HasGameReference<SoulKnightGame>, CollisionCallbacks {
  final Player target;
  final bool isElite;
  
  int hp;
  final int maxHp;
  EnemyState state = EnemyState.idle;
  double shootTimer = 0;
  final double shootInterval;
  final double shootRange;
  final int damage;
  final int goldDrop;
  final Random _rand = Random();

  Enemy({
    required Vector2 position,
    required this.target,
    this.isElite = false,
    this.hp = 2,
    required this.maxHp,
    this.shootInterval = 0,
    this.shootRange = 0,
    this.damage = 1,
    this.goldDrop = 1,
  }) : super(position: position) {
    size = Vector2.all(GameConstants.enemySize);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: GameConstants.enemySize / 2 - 1));
    _addVisual();
  }

  void _addVisual() {
    final bodyColor = isElite ? const Color(0xFFFFD700) : const Color(0xFFE53935);
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = bodyColor,
      anchor: Anchor.center,
    ));
    add(RectangleComponent(
      size: Vector2(4, 4),
      position: Vector2(-4, -size.y / 4),
      paint: Paint()..color = Colors.white,
      anchor: Anchor.center,
    ));
    add(RectangleComponent(
      size: Vector2(4, 4),
      position: Vector2(4, -size.y / 4),
      paint: Paint()..color = Colors.white,
      anchor: Anchor.center,
    ));
    if (isElite) {
      add(RectangleComponent(
        size: size + Vector2.all(4),
        paint: Paint()
          ..color = const Color(0xFFFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
        anchor: Anchor.center,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state == EnemyState.dead) return;

    final dist = (target.position - position).length;
    final toPlayer = (target.position - position)..normalize();

    if (shootInterval > 0 && dist <= shootRange) {
      _shootAtPlayer(dt, toPlayer);
    } else {
      _chasePlayer(dt, toPlayer, dist);
    }

    position.x = position.x.clamp(0, GameConstants.gameWidth);
    position.y = position.y.clamp(0, GameConstants.gameHeight);
  }

  void _shootAtPlayer(double dt, Vector2 toPlayer) {
    state = EnemyState.shooting;
    shootTimer -= dt;
    if (shootTimer <= 0) {
      shootTimer = shootInterval;
      _fireBullet(toPlayer);
    }
  }

  void _chasePlayer(double dt, Vector2 toPlayer, double dist) {
    state = EnemyState.chasing;
    final speed = GameConstants.enemySpeed * (isElite ? 1.3 : 1.0) * dt;
    position += toPlayer * speed;
  }

  void _fireBullet(Vector2 direction) {
    add(EnemyBullet(position: position.clone(), direction: direction, damage: damage, owner: target));
  }

  void takeDamage(int dmg) {
    hp -= dmg;
    if (hp <= 0) _die();
  }

  void _die() {
    state = EnemyState.dead;
    game.onEnemyKilled();
    final dropCount = goldDrop + (_rand.nextDouble() < 0.3 ? 1 : 0);
    for (int i = 0; i < dropCount; i++) {
      add(Coin(position: position.clone() + Vector2.all(_rand.nextDouble() * 20 - 10)));
    }
    removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    if (other is Bullet && other.isPlayerBullet) {
      takeDamage(other.damage);
      other.destroy();
    }
    if (other is Player && !target.activeShield && !target.isInvincible) {
      target.takeDamage(damage);
    }
  }
}

class ChaserEnemy extends Enemy {
  ChaserEnemy({
    required super.position,
    required super.target,
    super.isElite = false,
    super.hp = 2,
    required super.maxHp,
    super.damage = 1,
    super.goldDrop = 1,
  }) : super();
}

class ShooterEnemy extends Enemy {
  ShooterEnemy({
    required super.position,
    required super.target,
    super.isElite = false,
    super.hp = 3,
    required super.maxHp,
    super.shootInterval = 2.0,
    super.shootRange = 250,
    super.damage = 1,
    super.goldDrop = 2,
  }) : super();

  @override
  void _addVisual() {
    final bodyColor = isElite ? const Color(0xFFFFD700) : const Color(0xFF7B1FA2);
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = bodyColor,
      anchor: Anchor.center,
    ));
    add(RectangleComponent(
      size: Vector2(4, 4),
      position: Vector2(-4, -size.y / 4),
      paint: Paint()..color = Colors.white,
      anchor: Anchor.center,
    ));
    add(RectangleComponent(
      size: Vector2(4, 4),
      position: Vector2(4, -size.y / 4),
      paint: Paint()..color = Colors.white,
      anchor: Anchor.center,
    ));
    add(RectangleComponent(
      size: Vector2(4, 10),
      position: Vector2(0, -GameConstants.enemySize / 2 - 5),
      paint: Paint()..color = Colors.grey,
      anchor: Anchor.center,
    ));
    if (isElite) {
      add(RectangleComponent(
        size: size + Vector2.all(4),
        paint: Paint()
          ..color = const Color(0xFFFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
        anchor: Anchor.center,
      ));
    }
  }
}

class BossEnemy extends PositionComponent with HasGameReference<SoulKnightGame>, CollisionCallbacks {
  final Player target;
  int hp;
  final int maxHp;
  int phase = 1;
  double attackTimer = 0;
  double specialTimer = 0;
  bool isDeadFlag = false;

  BossEnemy({required Vector2 position, required this.target, this.hp = 30, required this.maxHp}) 
      : super(position: position) {
    size = Vector2(60, 60);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: 30));
    _addVisual();
  }

  void _addVisual() {
    final color = phase == 1 ? const Color(0xFFD32F2F) : const Color(0xFF212121);
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = color,
      anchor: Anchor.center,
    ));
    add(RectangleComponent(
      size: size + Vector2.all(4),
      paint: Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDeadFlag) return;

    final toPlayer = (target.position - position)..normalize();
    final dist = (target.position - position).length;

    if (dist > 120) {
      position += toPlayer * 80 * dt;
    } else if (dist < 80) {
      position -= toPlayer * 80 * dt;
    }

    attackTimer -= dt;
    if (attackTimer <= 0) {
      attackTimer = phase == 1 ? 1.5 : 0.8;
      _phaseAttack(toPlayer);
    }

    specialTimer -= dt;
    if (specialTimer <= 0) {
      specialTimer = phase == 1 ? 8.0 : 5.0;
      _specialAttack();
    }

    position.x = position.x.clamp(0, GameConstants.gameWidth);
    position.y = position.y.clamp(0, GameConstants.gameHeight);
  }

  void _phaseAttack(Vector2 toPlayer) {
    final count = phase == 1 ? 3 : 5;
    for (int i = 0; i < count; i++) {
      final angle = atan2(toPlayer.y, toPlayer.x) + (i - count / 2) * 0.15;
      final dir = Vector2(cos(angle), sin(angle));
      add(EnemyBullet(position: position.clone(), direction: dir, damage: 2, owner: target));
    }
  }

  void _specialAttack() {
    if (phase == 1) {
      for (int i = 0; i < 8; i++) {
        final angle = (i / 8) * 6.28318;
        final dir = Vector2(cos(angle), sin(angle));
        add(EnemyBullet(position: position.clone(), direction: dir, damage: 1, owner: target));
      }
    } else {
      for (int i = 0; i < 16; i++) {
        final angle = (i / 16) * 6.28318;
        final dir = Vector2(cos(angle), sin(angle));
        add(EnemyBullet(position: position.clone(), direction: dir, damage: 2, owner: target));
      }
    }
  }

  void takeDamage(int dmg) {
    hp -= dmg;
    if (hp <= maxHp ~/ 2 && phase == 1) {
      phase = 2;
      _addVisual();
    }
    if (hp <= 0) _die();
  }

  void _die() {
    isDeadFlag = true;
    game.onEnemyKilled();
    game.onEnemyKilled();
    game.onEnemyKilled();
    for (int i = 0; i < 10; i++) {
      add(Coin(position: position.clone() + Vector2.all(Random().nextDouble() * 40 - 20)));
    }
    removeFromParent();
  }

  @override
  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    if (other is Bullet && other.isPlayerBullet) {
      takeDamage(other.damage);
      other.destroy();
    }
  }
}

class EnemyBullet extends PositionComponent with HasGameReference<SoulKnightGame> {
  Vector2 direction;
  final double _speed = 150;
  final int damage;
  final Player owner;

  EnemyBullet({
    required Vector2 position,
    required Vector2 direction,
    this.damage = 1,
    required this.owner,
  }) : direction = direction.clone() {
    size = Vector2.all(GameConstants.bulletSize);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFFFF5722),
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * _speed * dt;

    if (position.x < -50 || position.x > GameConstants.gameWidth + 50 ||
        position.y < -50 || position.y > GameConstants.gameHeight + 50) {
      removeFromParent();
      return;
    }

    if (toRect().overlaps(owner.toRect())) {
      if (!owner.activeShield && !owner.isInvincible) {
        owner.takeDamage(damage);
      }
      removeFromParent();
    }
  }
}

// ============ PICKUPS ============

class Coin extends PositionComponent with HasGameReference<SoulKnightGame> {
  final double _lifetime = 8.0;
  double _timer = 0;

  Coin({required Vector2 position}) : super(position: position) {
    size = Vector2(12, 12);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFFFFD700),
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer > _lifetime) {
      removeFromParent();
      return;
    }
    final toPlayer = (game.player.position - position)..normalize();
    position += toPlayer * 200 * dt;
  }

  @override
  void onCollision(Set<Vector2> points, Component other) {
    if (other is Player) {
      game.onEnemyKilled();
      removeFromParent();
    }
  }
}

class WeaponPickup extends PositionComponent with HasGameReference<SoulKnightGame> {
  final Weapon weapon;
  final double _lifetime = 10.0;
  double _timer = 0;

  WeaponPickup({required Vector2 position, required this.weapon}) : super(position: position) {
    size = Vector2(20, 20);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = Color(weapon.colorValue),
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer > _lifetime) {
      removeFromParent();
      return;
    }
    final toPlayer = (game.player.position - position)..normalize();
    position += toPlayer * 150 * dt;
  }

  @override
  void onCollision(Set<Vector2> points, Component other) {
    if (other is Player) {
      if (other.weapon == null) {
        other.weapon = weapon;
      } else if (other.backupWeapons.length < 2) {
        other.backupWeapons.add(weapon);
      }
      removeFromParent();
    }
  }
}