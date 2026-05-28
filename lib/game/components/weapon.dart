import 'dart:math' show atan2, cos, sin, sqrt;
import 'package:flame/components.dart';
import 'package:vector_math/vector_math.dart';
import '../game.dart';

/// 武器类型枚举
enum WeaponType {
  pistol, shotgun, rifle, sniper, magic, missile,
}

/// 武器数据类
class WeaponData {
  final String id;
  final String name;
  final WeaponType type;
  final int damage;
  final double fireRate;
  final int maxAmmo;
  final int penetrate;
  final String description;
  final int price;

  const WeaponData({
    required this.id, required this.name, required this.type,
    required this.damage, required this.fireRate, this.maxAmmo = -1,
    this.penetrate = 0, required this.description, this.price = 0,
  });
}

/// 武器基类
abstract class Weapon {
  WeaponData get data;
  String? prefix;
  int damageBonus = 0;
  double fireRateBonus = 0;
  late int currentAmmo = data.maxAmmo;
  double cooldownTimer = 0;

  Weapon() { currentAmmo = data.maxAmmo; }

  bool get canFire => cooldownTimer <= 0 && (currentAmmo != 0 || data.maxAmmo == -1);
  int get finalDamage => data.damage + damageBonus;
  double get finalFireRate => (data.fireRate * (1 - fireRateBonus)).clamp(0.05, 10.0);

  void fire(Vector2 origin, Vector2 direction, SoulKnightGame game) {
    if (!canFire) return;
    cooldownTimer = finalFireRate;
    if (currentAmmo > 0) currentAmmo--;
    _onFire(origin, direction, game);
  }

  void _onFire(Vector2 origin, Vector2 direction, SoulKnightGame game);
  void update(double dt) { if (cooldownTimer > 0) cooldownTimer -= dt; }
  String get displayName => prefix != null ? '$prefix ${data.name}' : data.name;
  int get colorValue;
}

/// 手枪
class Pistol extends Weapon {
  @override WeaponData get data => const WeaponData(
    id: 'pistol', name: '手枪', type: WeaponType.pistol,
    damage: 1, fireRate: 0.25, description: '单发直射，稳定性好', price: 0,
  );
  @override void _onFire(Vector2 origin, Vector2 direction, SoulKnightGame game) {
    game.addBullet(origin.clone(), direction, finalDamage, data.penetrate);
  }
  @override int get colorValue => 0xFF2196F3;
}

/// 霰弹枪
class Shotgun extends Weapon {
  @override WeaponData get data => const WeaponData(
    id: 'shotgun', name: '霰弹枪', type: WeaponType.shotgun,
    damage: 1, fireRate: 0.8, description: '扇形发射5发弹药', price: 200,
  );
  @override void _onFire(Vector2 origin, Vector2 direction, SoulKnightGame game) {
    final baseAngle = atan2(direction.y, direction.x);
    const pellets = 5;
    const spread = 0.4;
    final startAngle = baseAngle - spread / 2;
    final step = spread / (pellets - 1);
    for (int i = 0; i < pellets; i++) {
      final angle = startAngle + step * i;
      final dir = Vector2(cos(angle), sin(angle));
      game.addBullet(origin.clone(), dir, finalDamage, data.penetrate);
    }
    if (currentAmmo > 0) currentAmmo -= pellets - 1;
  }
  @override int get colorValue => 0xFFFF9800;
}

/// 步枪
class Rifle extends Weapon {
  @override WeaponData get data => const WeaponData(
    id: 'rifle', name: '突击步枪', type: WeaponType.rifle,
    damage: 1, fireRate: 0.5, description: '快速3连发', price: 300,
  );
  @override void _onFire(Vector2 origin, Vector2 direction, SoulKnightGame game) {
    final baseAngle = atan2(direction.y, direction.x);
    for (int i = 0; i < 3; i++) {
      final angle = baseAngle + (i - 1) * 0.05;
      final dir = Vector2(cos(angle), sin(angle));
      game.addBullet(origin.clone(), dir, finalDamage, data.penetrate);
    }
    if (currentAmmo > 0) currentAmmo -= 2;
  }
  @override int get colorValue => 0xFF4CAF50;
}

/// 狙击枪
class Sniper extends Weapon {
  @override WeaponData get data => const WeaponData(
    id: 'sniper', name: '狙击枪', type: WeaponType.sniper,
    damage: 5, fireRate: 1.5, description: '超高伤害，慢射速', price: 500,
  );
  @override void _onFire(Vector2 origin, Vector2 direction, SoulKnightGame game) {
    game.addBullet(origin.clone(), direction, finalDamage, data.penetrate, 1.5);
  }
  @override int get colorValue => 0xFF9C27B0;
}

/// 魔法球
class MagicBall extends Weapon {
  @override WeaponData get data => const WeaponData(
    id: 'magic', name: '魔法火球', type: WeaponType.magic,
    damage: 2, fireRate: 0.6, description: '飞行后爆炸，范围伤害', price: 400,
  );
  @override void _onFire(Vector2 origin, Vector2 direction, SoulKnightGame game) {
    game.addMagicBullet(origin.clone(), direction, finalDamage);
  }
  @override int get colorValue => 0xFFE91E63;
}

/// 导弹
class Missile extends Weapon {
  @override WeaponData get data => const WeaponData(
    id: 'missile', name: '追踪导弹', type: WeaponType.missile,
    damage: 3, fireRate: 1.0, description: '自动追踪最近敌人', price: 600,
  );
  @override void _onFire(Vector2 origin, Vector2 direction, SoulKnightGame game) {
    game.addMissileBullet(origin.clone(), direction, finalDamage);
  }
  @override int get colorValue => 0xFFF44336;
}

/// 武器注册表
class WeaponRegistry {
  static final Map<String, Weapon Function()> _weapons = {
    'pistol': () => Pistol(),
    'shotgun': () => Shotgun(),
    'rifle': () => Rifle(),
    'sniper': () => Sniper(),
    'magic': () => MagicBall(),
    'missile': () => Missile(),
  };

  static final List<String> allIds = _weapons.keys.toList();

  static Weapon create(String id) => _weapons[id]?.call() ?? Pistol();
}