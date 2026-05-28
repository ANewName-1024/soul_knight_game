import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import '../game.dart';

class Player extends PositionComponent with HasGameReference<SoulKnightGame> {
  int hp = GameConstants.playerMaxHp;
  double _fireTimer = 0;

  Player({required Vector2 position}) : super(position: position) {
    size = Vector2.all(GameConstants.playerSize);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    // 玩家是蓝色方块
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF2196F3),
      anchor: Anchor.center,
    ));
    // 枪口(小尾巴)
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

    _fireTimer -= dt;
    if (_fireTimer <= 0) {
      _fireTimer = GameConstants.fireRate;
      _shoot();
    }

    position.x = position.x.clamp(0, GameConstants.gameWidth);
    position.y = position.y.clamp(0, GameConstants.gameHeight);
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

  /// 强制射击（用于触摸触发，不自动搜寻敌人）
  void forceFire() {
    // 默认朝上射击
    final dir = Vector2(0, -1)..normalize();
    game.addBullet(position.clone(), dir);
  }

  void move(Vector2 delta) {
    position += delta;
  }

  void takeDamage(int amount) {
    hp -= amount;
    game.onPlayerDamaged();
  }

  void reset() {
    hp = GameConstants.playerMaxHp;
    position = Vector2(GameConstants.gameWidth / 2, GameConstants.gameHeight / 2);
  }
}

class Enemy extends PositionComponent with HasGameReference<SoulKnightGame> {
  final Player target;
  final double _speed = GameConstants.enemySpeed;
  int hp = 3;

  Enemy({required Vector2 position, required this.target}) : super(position: position) {
    size = Vector2.all(GameConstants.enemySize);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    // 敌人是红色方块
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFFE53935),
      anchor: Anchor.center,
    ));
    // 眼睛(两个小白方块)
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
    position += dir * _speed * dt;

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
    // 子弹是黄色小方块
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