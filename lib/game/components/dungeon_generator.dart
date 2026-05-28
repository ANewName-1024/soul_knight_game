import 'dart:math' show Random;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import '../game.dart';

enum RoomDirection { top, right, bottom, left }

class Room extends PositionComponent with HasGameReference<SoulKnightGame> {
  final int id;
  final Set<RoomDirection> doors;
  final bool isStart;
  final bool isBoss;
  bool isCleared = false;
  final Random _rand = Random();

  Room({
    required Vector2 position,
    required this.id,
    required this.doors,
    this.isStart = false,
    this.isBoss = false,
  }) : super(position: position) {
    size = Vector2(GameConstants.roomWidth, GameConstants.roomHeight);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = isBoss ? const Color(0xFF1A1A2E) : const Color(0xFF2D2D44),
      anchor: Anchor.center,
    ));
    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = isBoss ? const Color(0xFFFF5722) : (isStart ? const Color(0xFF4CAF50) : const Color(0xFF444466))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
      anchor: Anchor.center,
    ));
    for (final door in doors) _addDoor(door);
    if (isStart) {
      add(RectangleComponent(size: Vector2(10, 10), paint: Paint()..color = const Color(0xFF4CAF50), anchor: Anchor.center));
    }
    if (isBoss) {
      add(RectangleComponent(size: Vector2(20, 20), paint: Paint()..color = const Color(0xFFFF5722), anchor: Anchor.center));
    }
  }

  void _addDoor(RoomDirection dir) {
    final doorSize = Vector2(40, 8);
    Vector2 pos;
    switch (dir) {
      case RoomDirection.top: pos = Vector2(size.x / 2, 4); break;
      case RoomDirection.right: pos = Vector2(size.x - 4, size.y / 2); break;
      case RoomDirection.bottom: pos = Vector2(size.x / 2, size.y - 4); break;
      case RoomDirection.left: pos = Vector2(4, size.y / 2); break;
    }
    add(RectangleComponent(size: doorSize, position: pos, paint: Paint()..color = const Color(0xFF8B4513), anchor: Anchor.center));
  }

  void onEnter() {
    if (isCleared) return;
    isCleared = true;
    _clearRoom();
    _spawnEnemiesForRoom();
  }

  void _clearRoom() {
    final toRemove = <Component>[];
    for (final c in game.children) {
      if (c is Enemy || c is Coin || c is WeaponPickup) toRemove.add(c);
    }
    for (final c in toRemove) c.removeFromParent();
  }

  void _spawnEnemiesForRoom() {
    if (isBoss) { _spawnBoss(); return; }
    final count = 3 + _rand.nextInt(4) + (id ~/ 3);
    for (int i = 0; i < count; i++) _spawnRandomEnemy();
  }

  void _spawnRandomEnemy() {
    final x = _rand.nextDouble() * (GameConstants.roomWidth - 60) + 30;
    final y = _rand.nextDouble() * (GameConstants.roomHeight - 60) + 30;
    final pos = Vector2(x, y) + position - Vector2(size.x / 2, size.y / 2);
    final isElite = _rand.nextDouble() < 0.2;
    if (_rand.nextDouble() < 0.25) {
      game.add(ShooterEnemy(position: pos, target: game.player, isElite: isElite, hp: 3, maxHp: 3));
    } else {
      game.add(ChaserEnemy(position: pos, target: game.player, isElite: isElite, hp: 2, maxHp: 2));
    }
  }

  void _spawnBoss() {
    game.add(BossEnemy(position: position.clone(), target: game.player, hp: 30 + game.waveNumber * 5, maxHp: 30 + game.waveNumber * 5));
  }

  Vector2 getDoorPosition(RoomDirection dir) {
    switch (dir) {
      case RoomDirection.top: return Vector2(position.x, position.y - size.y / 2);
      case RoomDirection.right: return Vector2(position.x + size.x / 2, position.y);
      case RoomDirection.bottom: return Vector2(position.x, position.y + size.y / 2);
      case RoomDirection.left: return Vector2(position.x - size.x / 2, position.y);
    }
  }
}

class DungeonGenerator {
  final int roomCount;
  final Random _rand = Random();
  final List<Room> rooms = [];
  final SoulKnightGame game;
  Room? startRoom;
  Room? bossRoom;
  Room? currentRoom;

  DungeonGenerator({required this.game, this.roomCount = 8});

  List<Room> generate() {
    rooms.clear();
    _generateRooms();
    return rooms;
  }

  void _generateRooms() {
    startRoom = Room(
      position: Vector2(GameConstants.gameWidth / 2, GameConstants.gameHeight * 0.7),
      id: 0,
      doors: {RoomDirection.top, RoomDirection.right},
      isStart: true,
    );
    rooms.add(startRoom!);

    final placed = <Room>[startRoom!];
    var id = 1;
    while (placed.length < roomCount) {
      final base = placed[_rand.nextInt(placed.length)];
      final dir = _randomDirection();
      final newPos = _offsetFrom(base, dir);
      if (_isValidPosition(newPos, placed)) {
        final newDoors = _makeDoors(base, dir);
        final isBoss = id == roomCount - 1;
        final room = Room(position: newPos, id: id, doors: newDoors, isBoss: isBoss);
        rooms.add(room);
        placed.add(room);
        id++;
      }
    }

    currentRoom = startRoom;
    bossRoom = rooms.isNotEmpty ? rooms.lastWhere((r) => r.isBoss, orElse: () => rooms.last) : null;
  }

  bool _isValidPosition(Vector2 pos, List<Room> existing) {
    if (pos.x < 0 || pos.x > GameConstants.gameWidth || pos.y < 0 || pos.y > GameConstants.gameHeight) return false;
    for (final r in existing) {
      if ((r.position - pos).length < GameConstants.roomWidth * 0.8) return false;
    }
    return true;
  }

  Vector2 _offsetFrom(Room from, RoomDirection dir) {
    const gap = 50.0;
    switch (dir) {
      case RoomDirection.top: return Vector2(from.position.x, from.position.y - GameConstants.roomHeight - gap);
      case RoomDirection.right: return Vector2(from.position.x + GameConstants.roomWidth + gap, from.position.y);
      case RoomDirection.bottom: return Vector2(from.position.x, from.position.y + GameConstants.roomHeight + gap);
      case RoomDirection.left: return Vector2(from.position.x - GameConstants.roomWidth - gap, from.position.y);
    }
  }

  Set<RoomDirection> _makeDoors(Room from, RoomDirection newDir) {
    final opposite = _opposite(newDir);
    from.doors.add(newDir);
    final doors = <RoomDirection>{opposite};
    final extraDir = _randomDirectionExcluding(opposite);
    if (extraDir != null) doors.add(extraDir);
    return doors;
  }

  RoomDirection _randomDirection() => RoomDirection.values[_rand.nextInt(4)];

  RoomDirection _opposite(RoomDirection dir) {
    switch (dir) {
      case RoomDirection.top: return RoomDirection.bottom;
      case RoomDirection.bottom: return RoomDirection.top;
      case RoomDirection.right: return RoomDirection.left;
      case RoomDirection.left: return RoomDirection.right;
    }
  }

  RoomDirection? _randomDirectionExcluding(RoomDirection exclude) {
    final others = RoomDirection.values.where((d) => d != exclude).toList();
    return others.isEmpty ? null : others[_rand.nextInt(others.length)];
  }

  void enterRoom(RoomDirection dir) {
    final from = currentRoom;
    if (from == null) return;
    final checkPos = _offsetFrom(from, dir);
    Room? nextRoom;
    for (final r in rooms) {
      if ((r.position - checkPos).length < 20) { nextRoom = r; break; }
    }
    if (nextRoom != null) {
      currentRoom = nextRoom;
      game.player.position = nextRoom.getDoorPosition(_opposite(dir));
      nextRoom.onEnter();
    }
  }

  bool get hasBossRoom => bossRoom != null && currentRoom == bossRoom;
  bool get isCleared => currentRoom?.isCleared ?? false;
}