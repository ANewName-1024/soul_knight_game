import 'dart:math' show atan2, sqrt, cos, sin;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import '../game.dart';
import 'weapon.dart';

class Player extends PositionComponent with HasGameReference<SoulKnightGame> {
  int hp = GameConstants.playerMaxHp;
  
  Weapon? weapon;
  final List<Weapon> backupWeapons = [];
  
  bool speedBoost = false;
  double speedBoostTimer = 0;
  bool activeShield = false;
  bool isInvincible = false;
  double invincibilityTimer = 0;

  Player({required Vector2 position}) : super(position: position) {
    size = Vector2.all(GameConstants.playerSize);
    anchor = Anchor.center;
    weapon = Pistol();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF2196F3),
      anchor: Anchor.center,
    ));
    add(RectangleComponent(
      size: Vector2(4, 10),
      position: Vector2(0, -GameConstants.playerSize / 2 - 5),
      paint: Paint()..color = const Color(0xFF1565C0),
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    weapon?.update(dt);
    if (weapon != null && weapon!.cooldownTimer <= 0) {
      _shoot();
    }

    position.x = position.x.clamp(0, GameConstants.gameWidth);
    position.y = position.y.clamp(0, GameConstants.gameHeight);
    
    if (speedBoostTimer > 0) {
      speedBoostTimer -= dt;
      if (speedBoostTimer <= 0) speedBoost = false;
    }
    
    if (invincibilityTimer > 0) {
      invincibilityTimer -= dt;
      if (invincibilityTimer <= 0) isInvincible = false;
    }
  }

  void _shoot() {
    final enemies = game.children.whereType<Enemy>().toList();
    if (enemies.isEmpty) return;

    Enemy? nearest;
    double minDist = double.infinity;
    for (final e in enemies) {
      final dist = (e.position - position).length;
      if (dist < minDist) { minDist = dist; nearest = e; }
    }

    if (nearest != null) {
      final dir = (nearest.position - position)..normalize();
      weapon?.fire(position.clone(), dir, game);
    }
  }

  void move(Vector2 delta) {
    final speed = speedBoost ? 1.5 : 1.0;
    position += delta * speed;
  }

  void takeDamage(int amount) {
    if (isInvincible) return;
    if (activeShield) { activeShield = false; return; }
    
    hp -= amount;
    isInvincible = true;
    invincibilityTimer = 1.0;
    game.onPlayerDamaged();
    
    if (hp <= 0) { /* death */ }
  }

  void reset() {
    hp = GameConstants.playerMaxHp;
    speedBoost = false;
    speedBoostTimer = 0;
    activeShield = false;
    isInvincible = false;
    invincibilityTimer = 0;
    weapon = Pistol();
    backupWeapons.clear();
    position = Vector2(GameConstants.gameWidth / 2, GameConstants.gameHeight / 2);
  }
  
  void forceFireTowardsNearest() {
    final enemies = game.children.whereType<Enemy>().toList();
    
    if (enemies.isEmpty) {
      weapon?.fire(position.clone(), Vector2(0, -1), game);
      return;
    }
    
    Enemy? nearest;
    double minDist = double.infinity;
    for (final e in enemies) {
      final dist = (e.position - position).length;
      if (dist < minDist) { minDist = dist; nearest = e; }
    }
    
    if (nearest != null) {
      final dir = (nearest.position - position)..normalize();
      weapon?.fire(position.clone(), dir, game);
    }
  }
  
  void switchWeapon() {
    if (backupWeapons.isEmpty) return;
    backupWeapons.add(weapon!);
    weapon = backupWeapons.removeAt(0);
  }
  
  void pickupWeapon(Weapon w) {
    if (backupWeapons.length < 2) backupWeapons.add(w);
  }
  
  String get weaponName => weapon?.displayName ?? '空';
  int get ammo => weapon?.currentAmmo ?? -1;
  double get fireCooldown => weapon?.cooldownTimer ?? 0;
}

class Enemy extends PositionComponent with HasGameReference<SoulKnightGame> {
  final Player target;
  final double _baseSpeed = GameConstants.enemySpeed;
  int hp = 3;
  final bool isElite;
  final int maxHp;

  Enemy({required Vector2 position, required this.target, this.isElite = false})
      : maxHp = isElite ? 6 : 3 {
    hp = maxHp;
    size = Vector2.all(isElite ? GameConstants.enemySize * 1.3 : GameConstants.enemySize);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = isElite ? const Color(0xFF8B0000) : const Color(0xFFE53935),
      anchor: Anchor.center,
    ));
    if (isElite) {
      add(RectangleComponent(
        size: size + Vector2(4, 4),
        paint: Paint()
          ..color = const Color(0xFFFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
        anchor: Anchor.center,
      ));
    }
    final eyePaint = Paint()..color = Colors.white;
    add(RectangleComponent(size: Vector2(6, 6), position: Vector2(-6, -4), paint: eyePaint, anchor: Anchor.center));
    add(RectangleComponent(size: Vector2(6, 6), position: Vector2(6, -4), paint: eyePaint, anchor: Anchor.center));
  }

  @override
  void update(double dt) {
    super.update(dt);
    final dir = (target.position - position)..normalize();
    position += dir * _baseSpeed * dt;
    position.x = position.x.clamp(0, GameConstants.gameWidth);
    position.y = position.y.clamp(0, GameConstants.gameHeight);
  }

  void takeDamage(double amount) {
    hp -= amount.toInt();
    if (hp <= 0) { game.onEnemyKilled(); removeFromParent(); }
  }
}

class Bullet extends PositionComponent with HasGameReference<SoulKnightGame> {
  Vector2 direction;
  final double _speed;
  final int damage;
  final int penetrate;

  Bullet({
    required Vector2 position,
    required Vector2 direction,
    this.damage = 1,
    this.penetrate = 0,
    double speedBonus = 0,
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

    for (final enemy in game.children.whereType<Enemy>().toList()) {
      if (toRect().overlaps(enemy.toRect())) {
        enemy.takeDamage(damage.toDouble());
        removeFromParent();
        return;
      }
    }
  }
}

class MagicBullet extends PositionComponent with HasGameReference<SoulKnightGame> {
  Vector2 direction;
  final double _speed = 200;
  final int damage;
  final double _maxDistance = 300;
  double _traveled = 0;

  MagicBullet({
    required Vector2 position,
    required Vector2 direction,
    this.damage = 2,
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
    
    for (final enemy in game.children.whereType<Enemy>().toList()) {
      if (toRect().overlaps(enemy.toRect())) { _explode(); return; }
    }
  }

  void _explode() {
    const radius = 60.0;
    for (final enemy in game.children.whereType<Enemy>().toList()) {
      final dist = (enemy.position - position).length;
      if (dist < radius) enemy.takeDamage(damage.toDouble());
    }
    removeFromParent();
  }
}

class MissileBullet extends PositionComponent with HasGameReference<SoulKnightGame> {
  Vector2 direction;
  final double _speed = 250;
  final int damage;
  final double _turnRate = 3.0;

  MissileBullet({
    required Vector2 position,
    required Vector2 direction,
    this.damage = 3,
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

    final enemies = game.children.whereType<Enemy>().toList();
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
    
    for (final enemy in game.children.whereType<Enemy>().toList()) {
      if (toRect().overlaps(enemy.toRect())) {
        enemy.takeDamage(damage.toDouble());
        removeFromParent();
        return;
      }
    }
  }
}