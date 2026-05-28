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