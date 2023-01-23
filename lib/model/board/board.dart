import 'dart:math';

import 'package:dcn_game/model/board/party.dart';

import 'mystery_card.dart';
import 'party_action.dart';

// part 'board.g.dart';

// To start a build : `flutter packages pub run build_runner build`

/// The board of the game
/// Contains:
/// - all tiles
/// - all POIs (Points of Interest)
class Board {
  /// Default board id
  static const String defaultBoard = 'default';

  /// list of all tiles
  List<BTile> tiles = [];

  /// list of all POIs
  List<POIBTile> pois = [];

  /// add a new tile to the board
  void addTile(String id, int x, int y) {
    tiles += [TopDecoratorBTile(SimpleBTile(id: id, coord: TileCoord(x, y)))];
  }

  /// connect two tiles
  /// if oneWayOnly is true, the connection is only one way
  void connectTiles(String idFrom, String idTo, bool oneWayOnly) {
    var tileFrom = tiles.firstWhere((element) => element.id == idFrom);
    var tileTo = tiles.firstWhere((element) => element.id == idTo);
    tileFrom.addConnection(tileTo);
    if (!oneWayOnly) {
      tileTo.addConnection(tileFrom);
    }
  }

  /// decorate a tile
  void decorateTile(String id, String type, Map<String, dynamic> args) {
    BTile tile;
    try {
      tile = tiles.firstWhere((element) => element.id == id);
      var decorator = DecoratorBTile.fromType(type: type, args: args);
      tile.addDecorator(decorator);

      if (decorator is POIBTile) {
        pois += [decorator];
      }
    } catch (e) {
      print("Error while decorating tile $id");
    }
  }

  /// Get all tiles that are reachable from a tile (with a given number of moves)
  ///
  /// Use dijkstra algorithm
  ///
  /// player: used to know if he can go through a tile
  ///
  List<BTile> getReachableTiles(BTile tile, Player player) {
    var moves = player.autonomy;
    var speedFactorMoves = player.cardSpeedModifier();

    var toVisit = <BTile>[tile];
    var visited = <BTile, double>{tile: moves};

    while (toVisit.isNotEmpty) {
      var current = toVisit.removeAt(0);
      var currentMoves = visited[current]!;

      toVisit.remove(current);

      if (currentMoves > 0) {
        for (BTile next in current.possibleNexts(
          player,
          moves: currentMoves,
          speedFactorModifier: speedFactorMoves,
        )) {
          // the autonomy after the move
          var nextMoves = currentMoves - next.cost(speedFactorMoves);

          // if the tile is not visited or if the autonomy is better
          if (!visited.containsKey(next) || visited[next]! < nextMoves) {
            visited[next] = nextMoves;
            toVisit += [next];
          }
        }
      }
    }

    return visited.keys.toList();
  }

  /// Get the tile from the id
  ///
  /// Raise an exception if the tile is not found
  BTile getTile(String idTile) {
    return tiles.firstWhere((element) => element.id == idTile);
  }
}

abstract class BTile {
  /// Get the next possible tiles to move to
  List<BTile> get nexts;

  /// Actions when the vehicle stop on this tile
  List<BoardAction> onStop();

  /// Actions when the vehicle pass the tile
  List<BoardAction> onPass();

  /// Return the speed factor
  /// 1.0 is the normal speed
  /// 0.5 mean need 2x more time to pass
  /// 2.0 mean need 2x less time to pass
  double getSpeed();

  /// If the vehicle can move on this tile
  bool canPass(Vehicle vehicle);

  /// All nexts where the vehicle can move
  /// - canPass is true
  /// - have enough autonomy
  ///
  /// moves: if is not null, use it to calculate the autonomy,
  /// otherwise use the player's autonomy.
  ///
  /// speedFactorModifier: if is not null, use it to calculate the
  /// speed factor of the player, otherwise use the player's speed factor.
  List<BTile> possibleNexts(
    Player player, {
    double? moves,
    double? speedFactorModifier,
  }) {
    if (player.vehicle == null) {
      return [];
    }
    return nexts
        .where((tile) =>
            tile.canPass(player.vehicle!) &&
            tile.cost(speedFactorModifier ?? player.cardSpeedModifier()) <=
                (moves ?? player.autonomy))
        .toList();
  }

  /// The coord (pixel) of the tile
  TileCoord getCoord();

  /// Return the id of the tile
  String get id;

  /// Return all the POIs of the tile
  List<POIBTile> getPOIs();

  /// Add a new DecoratorBTile to the tile
  void addDecorator(DecoratorBTile decorator);

  /// check the type is in the chain
  bool contains(String type);

  /// check the type is in the chain
  bool containsWarehouse();

  /// add a new connection to a tile (one way)
  void addConnection(BTile tile) {
    nexts.add(tile);
  }

  /// Cost to move on this tile
  ///
  /// speedFactorModifier: 0.5 mean need 2x more time to pass
  double cost(double speedFactorModifier) {
    return 1 / getSpeed() / speedFactorModifier;
  }
}

/// The end of the decoration chain
/// The base tile
class SimpleBTile extends BTile {
  /// tile id
  @override
  final String id;

  /// tile coord
  final TileCoord coord;

  @override
  List<BTile> nexts = [];

  SimpleBTile({
    required this.id,
    required this.coord,
  });

  @override
  List<BoardAction> onStop() {
    return [];
  }

  @override
  List<BoardAction> onPass() {
    return [];
  }

  @override
  double getSpeed() {
    return 1.0;
  }

  @override
  bool canPass(Vehicle vehicle) {
    return true;
  }

  @override
  TileCoord getCoord() {
    return coord;
  }

  @override
  List<POIBTile> getPOIs() {
    return [];
  }

  @override
  void addDecorator(DecoratorBTile decorator) {
    throw Exception("Can't add a decorator directly to a SimpleBTile. "
        "Must be use on a DecoratorBTile");
  }

  @override
  bool contains(String type) {
    return false;
  }

  @override
  bool containsWarehouse() {
    return false;
  }
}

/// The Decorator pattern
abstract class DecoratorBTile extends BTile {
  BTile? tile;

  /// The type of the decorator
  String get type;

  DecoratorBTile(this.tile);

  factory DecoratorBTile.fromType(
      {required String type, Map<String, dynamic>? args}) {
    // TODO: add decorator here if new decorator is added
    switch (type) {
      case TopDecoratorBTile.sType:
        return TopDecoratorBTile(null);
      case ExpresswayBTile.sType:
        return ExpresswayBTile(null);
      case BikeRoadBTile.sType:
        return BikeRoadBTile(null);
      case ZFEBTile.sType:
        return ZFEBTile(null);
      case LowSpeedBTile.sType:
        return LowSpeedBTile(null);
      case POIBTile.sType:
        if (args == null || !args.containsKey("poiName")) {
          throw Exception("Missing poiName in args");
        }
        if (POIBTile.isNameWarehouse(args["poiName"])) {
          return WarehouseBTile(null);
        }
        return POIBTile(null, poiName: args["poiName"]);
      case MysteryCardBTile.sType:
        return MysteryCardBTile(null);
      default:
        throw Exception("Unknown type of DecoratorBTile: $type");
    }
  }

  @override
  List<BTile> get nexts => tile?.nexts ?? [];

  @override
  List<BoardAction> onStop() => tile?.onStop() ?? [];

  @override
  List<BoardAction> onPass() => tile?.onPass() ?? [];

  @override
  double getSpeed() => tile?.getSpeed() ?? 1.0;

  @override
  bool canPass(Vehicle vehicle) => tile?.canPass(vehicle) ?? false;

  @override
  TileCoord getCoord() => tile?.getCoord() ?? TileCoord(0, 0);

  @override
  String get id => tile?.id ?? "ERROR: tile = null";

  @override
  List<POIBTile> getPOIs() {
    var pois = tile?.getPOIs() ?? [];
    if (tile is POIBTile) {
      pois.add(tile as POIBTile);
    }
    return pois;
  }

  @override
  void addDecorator(DecoratorBTile decorator) {
    var old = tile;
    tile = decorator;
    decorator.tile = old;
  }

  @override
  bool contains(String type) {
    return type == this.type || (tile?.contains(type) ?? false);
  }

  @override
  bool containsWarehouse() {
    return (tile?.containsWarehouse() ?? false) || this is WarehouseBTile;
  }
}

/// TopDecoratorBTile
/// The top of the decorator chain
/// Example of chain:
/// TopDecoratorBTile -> SomeDecoratorBTile -> SomeDecoratorBTile -> SimpleBTile
class TopDecoratorBTile extends DecoratorBTile {
  TopDecoratorBTile(BTile? tile) : super(tile);

  static const String sType = "top";

  @override
  String get type => sType;
}

/// Expressway Tile
class ExpresswayBTile extends DecoratorBTile {
  ExpresswayBTile(BTile? tile) : super(tile);

  static const String sType = "highway";

  @override
  String get type => sType;

  @override
  bool canPass(Vehicle vehicle) {
    return vehicle.canPassExpressway() && (tile?.canPass(vehicle) ?? true);
  }
}

/// BikeRoad Tile
class BikeRoadBTile extends DecoratorBTile {
  BikeRoadBTile(BTile? tile) : super(tile);

  static const String sType = "bike";

  @override
  String get type => sType;

  @override
  bool canPass(Vehicle vehicle) {
    return vehicle.canPassBikeRoad() && (tile?.canPass(vehicle) ?? true);
  }
}

/// ZFE Tile
class ZFEBTile extends DecoratorBTile {
  ZFEBTile(BTile? tile) : super(tile);

  static const String sType = "zfe";

  @override
  String get type => sType;

  @override
  bool canPass(Vehicle vehicle) {
    return vehicle.canPassZFE() && (tile?.canPass(vehicle) ?? true);
  }
}

/// Low speed tile
class LowSpeedBTile extends DecoratorBTile {
  LowSpeedBTile(BTile? tile) : super(tile);

  static const String sType = "low";

  @override
  String get type => sType;

  @override
  double getSpeed() {
    return 0.5;
  }
}

/// POI (Point of Interest) tile
class POIBTile extends DecoratorBTile {
  static const String sType = "poi";

  @override
  String get type => sType;

  final String poiName;

  POIBTile(BTile? tile, {required this.poiName}) : super(tile);

  bool get isWarehouse => false;

  static bool isNameWarehouse(String name) {
    return name == WarehouseBTile.label;
  }
}

/// The warehouse, start of the game
class WarehouseBTile extends POIBTile {
  WarehouseBTile(BTile? tile) : super(tile, poiName: WarehouseBTile.label);

  static const String label = "Warehouse";

  @override
  bool get isWarehouse => true;
}

/// Mystery tile
/// Pick a random mystery card
class MysteryCardBTile extends DecoratorBTile {
  MysteryCardBTile(BTile? tile) : super(tile);

  static const String sType = "mystery_card";

  @override
  String get type => sType;

  @override
  List<BoardAction> onStop() {
    return [];
  }

  @override
  List<BoardAction> onPass() {
    return [TakeMysteryCard()];
  }
}

/// store the points cost (buy and use) of a vehicle
/// - Money
/// - Energy
/// - Environment
/// - Performance
class PointCard {
  final int money;
  final int energy;
  final int environment;
  final int performance;

  const PointCard({
    required this.money,
    required this.energy,
    required this.environment,
    required this.performance,
  });

  PointCard operator +(PointCard other) {
    return PointCard(
      money: money + other.money,
      energy: energy + other.energy,
      environment: environment + other.environment,
      performance: performance + other.performance,
    );
  }

  PointCard operator -(PointCard other) {
    return PointCard(
      money: money - other.money,
      energy: energy - other.energy,
      environment: environment - other.environment,
      performance: performance - other.performance,
    );
  }

  /// >= : true if all the points are >=
  bool operator >=(PointCard other) {
    return money >= other.money &&
        energy >= other.energy &&
        environment >= other.environment &&
        performance >= other.performance;
  }

  /// <= : true if all the points are <=
  bool operator <=(PointCard other) {
    return money <= other.money &&
        energy <= other.energy &&
        environment <= other.environment &&
        performance <= other.performance;
  }

  /// > : true if all the points are >
  bool operator >(PointCard other) {
    return money > other.money &&
        energy > other.energy &&
        environment > other.environment &&
        performance > other.performance;
  }

  Map<String, dynamic> toJson() {
    return {
      "money": money,
      "energy": energy,
      "environment": environment,
      "performance": performance,
    };
  }

  factory PointCard.fromJson(Map<String, dynamic> json) {
    return PointCard(
      money: json["money"],
      energy: json["energy"],
      environment: json["environment"],
      performance: json["performance"],
    );
  }
}

/// Vehicle
abstract class Vehicle {
  /// The type of the vehicle
  String get type;

  /// The name of the vehicle
  String get name;

  // final String id;

  // Vehicle(this.id);
  Vehicle();

  /// The speed of the vehicle
  double get speed => 1.0;

  /// The max load of the vehicle
  double get maxLoad => 1;

  /// The autonomy of the vehicle
  int get autonomy => 1;

  /// if the vehicle can move in Expressway
  bool canPassExpressway() => false;

  /// if the vehicle can move in BikeRoad
  bool canPassBikeRoad() => false;

  /// if the vehicle can pass by ZFE
  bool canPassZFE() => false;

  /// if the vehicle is affected by traffic jam
  bool isAffectedByJam() => false;

  PointCard getBuyCost();

  PointCard getUseCost();

  factory Vehicle.fromType({required String type}) {
    switch (type) {
      case "e":
        return ElectricVehicle();
      case "g":
        return GasolineVehicle();
      case "b":
        return Bike();
      default:
        throw Exception("Unknown type of Vehicle: $type");
    }
  }

  /// all vehicles types
  static List<String> get allTypes => ["e", "g", "b"];
}

/// Electric vehicle
class ElectricVehicle extends Vehicle {
  // ElectricVehicle(String id) : super(id);
  ElectricVehicle();

  @override
  String get type => 'e';

  @override
  String get name => 'Electric';

  @override
  double get speed => 1.0;

  @override
  double get maxLoad => 10;

  @override
  int get autonomy => 4;

  @override
  bool canPassExpressway() => true;

  @override
  bool canPassBikeRoad() => false;

  @override
  bool canPassZFE() => true;

  @override
  bool isAffectedByJam() => true;

  @override
  PointCard getBuyCost() => const PointCard(
        money: 5,
        energy: 5,
        environment: 5,
        performance: 0,
      );

  @override
  PointCard getUseCost() => const PointCard(
        money: 3,
        energy: -3,
        environment: 2,
        performance: -5,
      );
}

/// Gasoline vehicle
class GasolineVehicle extends Vehicle {
  // GasolineVehicle(String id) : super(id);
  GasolineVehicle();

  @override
  String get type => 'g';

  @override
  String get name => 'Gasoline';

  @override
  double get speed => 1.0;

  @override
  double get maxLoad => 10;

  @override
  int get autonomy => 4;

  @override
  bool canPassExpressway() => true;

  @override
  bool canPassBikeRoad() => false;

  @override
  bool canPassZFE() => false;

  @override
  bool isAffectedByJam() => true;

  @override
  PointCard getBuyCost() => const PointCard(
        money: 4,
        energy: 4,
        environment: 2,
        performance: 0,
      );

  @override
  PointCard getUseCost() => const PointCard(
        money: 3,
        energy: 4,
        environment: 3,
        performance: -5,
      );
}

/// Bike
class Bike extends Vehicle {
  // Bike(String id) : super(id);
  Bike();

  @override
  String get type => 'b';

  @override
  String get name => 'Bike';

  @override
  double get speed => 0.5;

  @override
  double get maxLoad => 3;

  @override
  int get autonomy => 2;

  @override
  bool canPassExpressway() => false;

  @override
  bool canPassBikeRoad() => true;

  @override
  bool canPassZFE() => true;

  @override
  bool isAffectedByJam() => false;

  @override
  PointCard getBuyCost() => const PointCard(
        money: 2,
        energy: 3,
        environment: 3,
        performance: 0,
      );

  @override
  PointCard getUseCost() => const PointCard(
        money: 1,
        energy: -5,
        environment: 1,
        performance: -2,
      );
}

/// Action to perform
abstract class BoardAction {}

/// Take a mystery card
class TakeMysteryCard extends BoardAction {
  TakeMysteryCard();

  /// Return a random mystery card
  static MysteryCard getMysteryCard() {
    final random = Random();
    final factory = MysteryCard.factories.values
        .toList()[random.nextInt(MysteryCard.factories.length)];
    return factory();
  }
}

/// Skip the next turn
class SkipTurn extends BoardAction {
  SkipTurn();
}

/// Tile coordinates (in pixel)
class TileCoord {
  final int x;
  final int y;

  TileCoord(this.x, this.y);
}

class CoordDouble {
  final double x;
  final double y;

  CoordDouble(this.x, this.y);
}

class Player {
  final String id;

  /// The name of the player
  String name;

  /// The current autonomy of the player
  double autonomy;

  /// The current load of the player
  double load;

  /// The current vehicle of the player
  Vehicle? vehicle;

  /// All the vehicles of the player
  List<Vehicle> vehicles;

  POIBTile? goalPOI;

  /// The current position of the player
  BTile? currentTile;

  /// current points of the player
  PointCard points;

  /// The readiness of the player
  bool ready;

  /// If the player can't play anymore
  bool out;

  /// The mysteries cards that affect the player
  List<MysteryCard> mysteryCards;

  Player(
    this.id, {
    required this.name,
    this.autonomy = 0,
    this.load = 0,
    this.vehicle,
    this.vehicles = const [],
    this.goalPOI,
    this.currentTile,
    this.points = const PointCard(
        money: 10, energy: 10, environment: 10, performance: 10),
    this.ready = false,
    this.out = false,
    this.mysteryCards = const [],
  });

  /// return the index of the player in the participants list of the party
  int indexPlayer(Party party) {
    return party.players.map((p) => p.id).toList().lastIndexOf(id);
  }

  /// Give the modified speed of the player for the next move
  double cardSpeedModifier() {
    return mysteryCards.fold(1.0, (p, m) => p * m.speedFactor);
  }

  /// Give the list of all future modified speed by move
  ///
  /// Example:
  /// [0.5, 0.5, 2]
  /// means that the player will move 2 times with a speed of 0.5 and 1 time with a speed of 2
  ///
  /// If the move is not specified, default is 1
  List<double> cardSpeedModifiers({int maxMove = 30}) {
    final list = <double>[];
    for (var i = 0; i < maxMove; i++) {
      double speed = 1.0;
      for (var card in mysteryCards) {
        if (card is! RoundTimedMysteryCard || card.duration >= i) {
          speed *= card.speedFactor;
        }
      }
      list.add(speed);
    }
    return list;
  }

  /// perform the RoundTimedMysteryCard action (subtract 1 round to the timer)
  /// if the timer of the card is 0, remove it from the player cards
  void updateRoundTimedMysteryCard(Party party) {
    for (final card in mysteryCards) {
      if (card is RoundTimedMysteryCard) {
        if (card.countDown()) {
          party.addAction(PartyAction.updatePlayerMysteryCards(
              id, mysteryCards.where((c) => c.id != card.id).toList()));
        }
      }
    }
  }

  /// Return true if this player has been stuck
  bool isStuck() {
    // perform the StuckMysteryCard action (stuck the player)
    // if the player has a MysteryCard, remove it from the player cards
    for (final card in mysteryCards) {
      if (card.stuckPlayerWhenPossessed) {
        return true;
      }
    }
    return false;
  }
}
