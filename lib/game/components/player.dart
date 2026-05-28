import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import '../game.dart';

class Player extends PositionComponent with HasGameReference<SoulKnightGame> {
  int hp = GameConstants.playerMaxHp;
  double _fireTimer = 0;
  
  /// 速度加成状态
  bool speedBoost = false;
  double speedBoostTimer = 0;
  
  /// 护盾状态
  bool activeShield = false;
  
  /// 受伤无敌帧
  bool isInvincible = false;
  double invincibilityTimer = 0;

  Player({required Vector2 position}) : super(position: position) {
    size = Vector2.all(GameConstants.playerSize);
    anchor = Anchor.center;
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

    // 射击冷却
    _fireTimer -= dt;
    if (_fireTimer <= 0) {
      _fireTimer = GameConstants.fireRate;
      _shoot();
    }

    // 边界限制
    position.x = position.x.clamp(0, GameConstants.gameWidth);
    position.y = position.y.clamp(0, GameConstants.gameHeight);
    
    // 速度加成计时
    if (speedBoostTimer > 0) {
      speedBoostTimer -= dt;
      if (speedBoostTimer <= 0) {
        speedBoost = false;
      }
    }
    
    // 无敌帧计时
    if (invincibilityTimer > 0) {
      invincibilityTimer -= dt;
      if (invincibilityTimer <= 0) {
        isInvincible = false;
      }
    }
  }

  void _shoot() {
    final enemies = game.children.whereType<Enemy>().toList();
    if (enemies.isEmpty) return;

    Enemy? nearest;
    double minDist = double.infinity;
    for (final e in enemies) {
      final dist = (e.position - position).length;
      if (dist < minDist) {
        minDist = dist;
        nearest = e;
      }
    }

    if (nearest != null) {
      final dir = (nearest.position - position)..normalize();
      game.addBullet(position.clone(), dir);
    }
  }

  void move(Vector2 delta) {
    // 速度加成时 ×1.5
    final speed = speedBoost ? 1.5 : 1.0;
    position += delta * speed;
  }

  void takeDamage(int amount) {
    if (isInvincible) return;
    
    if (activeShield) {
      // 护盾抵消
      activeShield = false;
      return;
    }
    
    hp -= amount;
    isInvincible = true;
    invincibilityTimer = 1.0;  // 1秒无敌
    
    game.onPlayerDamaged();
    
    if (hp <= 0) {
      game.onEnemyKilled(); // 复用死亡回调
    }
  }

  void reset() {
    hp = GameConstants.playerMaxHp;
    speedBoost = false;
    speedBoostTimer = 0;
    activeShield = false;
    isInvincible = false;
    invincibilityTimer = 0;
    position = Vector2(GameConstants.gameWidth / 2, GameConstants.gameHeight / 2);
  }
  
  /// 强制射击最近敌人（移动端/技能用）
  void forceFireTowardsNearest() {
    final enemies = game.children.whereType<Enemy>().toList();
    if (enemies.isEmpty) {
      // 没有敌人时向上射击
      game.addBullet(position.clone(), Vector2(0, -1));
      return;
    }
    
    Enemy? nearest;
    double minDist = double.infinity;
    for (final e in enemies) {
      final dist = (e.position - position).length;
      if (dist < minDist) {
        minDist = dist;
        nearest = e;
      }
    }
    
    if (nearest != null) {
      final dir = (nearest.position - position)..normalize();
      game.addBullet(position.clone(), dir);
    }
  }
}

class Enemy extends PositionComponent with HasGameReference<SoulKnightGame> {
  final Player target;
  final double _baseSpeed = GameConstants.enemySpeed;
  int hp = 3;

  Enemy({required Vector2 position, required this.target}) : super(position: position) {
    size = Vector2.all(GameConstants.enemySize);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFFE53935),
      anchor: Anchor.center,
    ));
    final eyePaint = Paint()..color = Colors.white;
    add(RectangleComponent(
      size: Vector2(6, 6),
      position: Vector2(-6, -4),
      paint: eyePaint,
      anchor: Anchor.center,
    ));
    add(RectangleComponent(
      size: Vector2(6, 6),
      position: Vector2(6, -4),
      paint: eyePaint,
      anchor: Anchor.center,
    ));
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
    if (hp <= 0) {
      game.onEnemyKilled();
      removeFromParent();
    }
  }
}

class Bullet extends PositionComponent with HasGameReference<SoulKnightGame> {
  final Vector2 direction;
  final double _speed = GameConstants.bulletSpeed;

  Bullet({required Vector2 position, required Vector2 direction})
      : direction = direction.clone(),
        super(position: position) {
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

    if (position.x < -50 ||
        position.x > GameConstants.gameWidth + 50 ||
        position.y < -50 ||
        position.y > GameConstants.gameHeight + 50) {
      removeFromParent();
      return;
    }

    final enemies = game.children.whereType<Enemy>().toList();
    for (final enemy in enemies) {
      if (toRect().overlaps(enemy.toRect())) {
        enemy.takeDamage(GameConstants.bulletDamage);
        removeFromParent();
        return;
      }
    }
  }
}