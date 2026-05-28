/// 游戏常量
class GameConstants {
  GameConstants._();

  // 画布
  static const double gameWidth = 480;
  static const double gameHeight = 720;

  // 玩家
  static const double playerSpeed = 200;
  static const double playerSize = 32;
  static const int playerMaxHp = 5;

  // 子弹
  static const double bulletSpeed = 400;
  static const double bulletSize = 8;
  static const double bulletDamage = 1;
  static const double fireRate = 0.3; // 秒/发

  // 敌人
  static const double enemySpeed = 80;
  static const double enemySize = 28;
  static const double enemyHp = 3;
  static const double enemyDamage = 1;
  static const double enemySpawnInterval = 2.0; // 秒

  // 武器
  static const double pistolFireRate = 0.3;
  static const double pistolBulletSpeed = 400;
  static const double pistolDamage = 1;
  // 地牢
  static const double roomWidth = 300;
  static const double roomHeight = 400;
}