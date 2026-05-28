import 'dart:math' show Random;
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game.dart';
import 'player.dart';

/// 粒子效果组件
class Particle extends PositionComponent with HasGameReference<SoulKnightGame> {
  Vector2 velocity;
  double lifeTime;
  double _elapsed = 0;
  final Color color;
  double particleSize;
  final double friction;

  Particle({
    required Vector2 position,
    required this.velocity,
    this.lifeTime = 0.5,
    this.color = const Color(0xFFFFEB3B),
    this.particleSize = 6,
    this.friction = 0.95,
  }) : super(position: position) {
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleComponent(
      size: Vector2.all(particleSize),
      paint: Paint()..color = color,
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    velocity = velocity * friction;
    position += velocity * dt;
    if (_elapsed >= lifeTime) removeFromParent();
  }
}

class ParticleEmitter extends PositionComponent with HasGameReference<SoulKnightGame> {
  final int count;
  final double spread;
  final double speed;
  final Color color;
  final double particleLife;
  final double particleSize;
  final Random _rand = Random();

  ParticleEmitter({
    required Vector2 position,
    required this.count,
    this.spread = 6.28318,
    this.speed = 200,
    this.color = const Color(0xFFFFEB3B),
    this.particleLife = 0.5,
    this.particleSize = 6,
  }) : super(position: position) {
    anchor = Anchor.center;
  }

  void emit() {
    for (int i = 0; i < count; i++) {
      final angle = _rand.nextDouble() * spread - spread / 2;
      final spd = speed * (0.5 + _rand.nextDouble() * 0.5);
      final vel = Vector2(math.cos(angle), math.sin(angle)) * spd;
      game.add(Particle(
        position: position.clone(),
        velocity: vel,
        color: color,
        lifeTime: particleLife * (0.5 + _rand.nextDouble() * 0.5),
        particleSize: particleSize * (0.5 + _rand.nextDouble() * 0.5),
        friction: 0.9,
      ));
    }
  }

  void emitTowards(Vector2 direction, {double angleSpread = 0.5}) {
    final baseAngle = math.atan2(direction.y, direction.x);
    for (int i = 0; i < count; i++) {
      final angle = baseAngle + (_rand.nextDouble() * angleSpread - angleSpread / 2);
      final spd = speed * (0.5 + _rand.nextDouble() * 0.5);
      final vel = Vector2(math.cos(angle), math.sin(angle)) * spd;
      game.add(Particle(
        position: position.clone(),
        velocity: vel,
        color: color,
        lifeTime: particleLife * (0.5 + _rand.nextDouble() * 0.5),
        particleSize: particleSize * (0.5 + _rand.nextDouble() * 0.5),
      ));
    }
  }
}

/// 命中效果
void spawnHitEffect(SoulKnightGame gameRef, Vector2 position, {bool isEnemy = true}) {
  final c = isEnemy ? const Color(0xFFFF5722) : const Color(0xFF2196F3);
  final emitter = ParticleEmitter(
    position: position, count: 6, spread: 1.5, speed: 150,
    color: c, particleLife: 0.3, particleSize: 5,
  );
  gameRef.add(emitter);
  emitter.emit();
}

/// 死亡爆炸
void spawnDeathEffect(SoulKnightGame gameRef, Vector2 position, {bool isBoss = false}) {
  final cnt = isBoss ? 30 : 12;
  final spd = isBoss ? 300.0 : 200.0;
  final emitter = ParticleEmitter(
    position: position, count: cnt, spread: 6.28318, speed: spd,
    color: const Color(0xFFFF5722), particleLife: 0.6, particleSize: 8,
  );
  gameRef.add(emitter);
  emitter.emit();
}

/// 魔法爆炸
void spawnMagicExplosionEffect(SoulKnightGame gameRef, Vector2 position) {
  for (int i = 0; i < 20; i++) {
    final angle = (i / 20) * 6.28318;
    final vel = Vector2(math.cos(angle), math.sin(angle)) * 250;
    gameRef.add(Particle(
      position: position.clone(), velocity: vel,
      color: const Color(0xFFE91E63), lifeTime: 0.4, particleSize: 7, friction: 0.92,
    ));
  }
}

/// 冲击波视觉
class BlastWaveVisual extends PositionComponent with HasGameReference<SoulKnightGame> {
  double _radius = 0;
  final double maxRadius;
  final double _speed;
  final Color color;
  double _elapsed = 0;

  BlastWaveVisual({
    required Vector2 position,
    double maxRadius = 150,
    double speed = 400,
    Color color = const Color(0xFFFF5722),
  }) : maxRadius = maxRadius,
       _speed = speed,
       color = color,
       super(position: position) {
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleComponent(
      size: Vector2.zero(),
      paint: Paint()
        ..color = color.withAlpha(150)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _radius += _speed * dt;
    final rc = children.query<RectangleComponent>().firstOrNull;
    if (rc != null) rc.size = Vector2.all(_radius * 2);
    if (_elapsed >= maxRadius / _speed + 0.1) removeFromParent();
  }
}

/// 护盾视觉
class ShieldVisual extends PositionComponent with HasGameReference<SoulKnightGame> {
  final Player target;
  final double _radius;

  ShieldVisual({required this.target, double radius = 30})
      : _radius = radius, super(position: target.position.clone()) {
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleComponent(
      size: Vector2.all(_radius * 2),
      paint: Paint()
        ..color = const Color(0xFF2196F3).withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position = target.position.clone();
  }
}

/// 受伤闪烁
class DamageFlash extends PositionComponent with HasGameReference<SoulKnightGame> {
  final Player target;
  double _elapsed = 0;
  final double duration;

  DamageFlash({required this.target, this.duration = 0.5})
      : super(position: target.position.clone()) {
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleComponent(
      size: target.size + Vector2.all(4),
      paint: Paint()..color = Colors.white.withAlpha(180),
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    position = target.position.clone();
    final rc = children.query<RectangleComponent>().firstOrNull;
    if (rc != null) {
      final alpha = (_elapsed * 20).floor() % 2 == 0 ? 180 : 50;
      rc.paint = Paint()..color = Colors.white.withAlpha(alpha);
    }
    if (_elapsed >= duration) removeFromParent();
  }
}