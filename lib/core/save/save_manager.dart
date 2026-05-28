import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 存档数据
class SaveData {
  final int currentLevel;
  final int highScore;
  final int totalKills;
  final List<String> unlockedWeapons;
  final Map<String, int> weaponUsage;
  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrationEnabled;

  SaveData({
    this.currentLevel = 1,
    this.highScore = 0,
    this.totalKills = 0,
    this.unlockedWeapons = const ['pistol'],
    this.weaponUsage = const {},
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
  });

  factory SaveData.fromJson(Map<String, dynamic> map) {
    return SaveData(
      currentLevel: map['currentLevel'] ?? 1,
      highScore: map['highScore'] ?? 0,
      totalKills: map['totalKills'] ?? 0,
      unlockedWeapons: List<String>.from(map['unlockedWeapons'] ?? ['pistol']),
      weaponUsage: Map<String, int>.from(map['weaponUsage'] ?? {}),
      soundEnabled: map['soundEnabled'] ?? true,
      musicEnabled: map['musicEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'currentLevel': currentLevel,
    'highScore': highScore,
    'totalKills': totalKills,
    'unlockedWeapons': unlockedWeapons,
    'weaponUsage': weaponUsage,
    'soundEnabled': soundEnabled,
    'musicEnabled': musicEnabled,
    'vibrationEnabled': vibrationEnabled,
  };
}

/// 存档管理
class SaveManager {
  static const String _keySaveData = 'soul_knight_save';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SaveData _empty() => SaveData();

  /// 读取存档
  static SaveData load() {
    if (_prefs == null) return _empty();
    final str = _prefs!.getString(_keySaveData);
    if (str == null) return _empty();
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return SaveData.fromJson(map);
    } catch (_) {
      return _empty();
    }
  }

  /// 保存存档
  static Future<void> save(SaveData data) async {
    if (_prefs == null) return;
    final str = jsonEncode(data.toJson());
    await _prefs!.setString(_keySaveData, str);
  }

  /// 保存游戏进度
  static Future<void> saveGameProgress({
    required int currentLevel,
    required int killCount,
    required List<String> unlockedWeapons,
    required Map<String, int> weaponUsage,
  }) async {
    final data = load();
    final newTotalKills = data.totalKills + killCount;
    final newHighScore = killCount > data.highScore ? killCount : data.highScore;
    await save(SaveData(
      currentLevel: currentLevel,
      highScore: newHighScore,
      totalKills: newTotalKills,
      unlockedWeapons: unlockedWeapons,
      weaponUsage: weaponUsage,
      soundEnabled: data.soundEnabled,
      musicEnabled: data.musicEnabled,
      vibrationEnabled: data.vibrationEnabled,
    ));
  }

  /// 解锁武器
  static Future<void> unlockWeapon(String weaponId) async {
    final data = load();
    if (!data.unlockedWeapons.contains(weaponId)) {
      final list = List<String>.from(data.unlockedWeapons)..add(weaponId);
      await save(SaveData(
        currentLevel: data.currentLevel,
        highScore: data.highScore,
        totalKills: data.totalKills,
        unlockedWeapons: list,
        weaponUsage: data.weaponUsage,
        soundEnabled: data.soundEnabled,
        musicEnabled: data.musicEnabled,
        vibrationEnabled: data.vibrationEnabled,
      ));
    }
  }

  /// 记录武器使用
  static Future<void> recordWeaponUse(String weaponId) async {
    final data = load();
    final usage = Map<String, int>.from(data.weaponUsage);
    usage[weaponId] = (usage[weaponId] ?? 0) + 1;
    await save(SaveData(
      currentLevel: data.currentLevel,
      highScore: data.highScore,
      totalKills: data.totalKills,
      unlockedWeapons: data.unlockedWeapons,
      weaponUsage: usage,
      soundEnabled: data.soundEnabled,
      musicEnabled: data.musicEnabled,
      vibrationEnabled: data.vibrationEnabled,
    ));
  }

  /// 保存设置
  static Future<void> saveSettings({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrationEnabled,
  }) async {
    final data = load();
    await save(SaveData(
      currentLevel: data.currentLevel,
      highScore: data.highScore,
      totalKills: data.totalKills,
      unlockedWeapons: data.unlockedWeapons,
      weaponUsage: data.weaponUsage,
      soundEnabled: soundEnabled ?? data.soundEnabled,
      musicEnabled: musicEnabled ?? data.musicEnabled,
      vibrationEnabled: vibrationEnabled ?? data.vibrationEnabled,
    ));
  }

  /// 重置存档
  static Future<void> reset() async {
    if (_prefs == null) return;
    await _prefs!.remove(_keySaveData);
  }
}