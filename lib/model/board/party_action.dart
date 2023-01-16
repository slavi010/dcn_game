import 'package:dcn_game/model/board/mystery_card.dart';
import 'package:dcn_game/model/board/server_states.dart';
import 'package:dcn_game/model/event_animation.dart';
import 'package:dcn_game/model/repository/event_animation_repository.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import 'board.dart';
import 'party.dart';

/// The action of a party
/// We can recreate all the party from the actions
/// The action is a simple class with a type and a payload
abstract class PartyAction {
  /// The id of the action (uuid)
  String idAction;

  /// The type of the action
  @JsonKey(name: 'type')
  String get type;

  /// The payload of the action
  @JsonKey(name: 'payload')
  Map<String, dynamic> get payload;

  PartyAction({this.idAction = ''}) {
    if (idAction.isEmpty) {
      idAction = const Uuid().v4();
    }
  }

  /// Create a PartyAction from a json
  factory PartyAction.fromJson(Map<String, dynamic> json) {
    switch (json["type"] as String) {
      case "add_player":
        return AddPlayerPartyAction.fromJson(json);
      case "set_player":
        return SetPlayerAction.fromJson(json);
      case "add_tile":
        return AddTileAction.fromJson(json);
      case "connect_tiles":
        return ConnectTilesAction.fromJson(json);
      case "decorate_tile":
        return DecorateTileAction.fromJson(json);
      case "update_current_player":
        return UpdateCurrentPlayerAction.fromJson(json);
      case 'update_eor':
        return UpdateEORAction.fromJson(json);
      case "update_server_state":
        return UpdateServerStateAction.fromJson(json);
      case "update_player_cards":
        return UpdatePlayerCardsAction.fromJson(json);
      case "event_animation":
        return EventAnimationAction.fromJson(json);
      default:
        throw Exception("Unknown type of PartyAction: ${json["type"]}, "
            "did you forget to add it in the factory?");
    }
  }

  /// Convert the action to json
  Map<String, dynamic> toJson() {
    return {"id_action": idAction, "type": type, "payload": payload};
  }

  /// the action to perform
  void perform(Party party) => {};

  /// The specific action to perform only on the client side
  void performClientSide(Party party, EventAnimationRepository eventAnimationRepository) => {};

  /// Add a player to the party
  factory PartyAction.newPlayer(String idPlayer, String name) {
    return AddPlayerPartyAction(idPlayer, name);
  }

  /// Set the readiness of a player
  factory PartyAction.playerReady(String idPlayer, bool ready) {
    return SetPlayerAction(id: idPlayer, ready: ready);
  }

  /// Set player to new round
  factory PartyAction.setupPlayerNewRound(
      String idPlayer, String idTarget, String idTile) {
    return SetPlayerAction(
        id: idPlayer, idGoalPOI: idTarget, idCurrentTile: idTile);
  }

  /// Buy a vehicle for a player
  factory PartyAction.buyVehicle(
      Player player, String typeVehicle, bool isCurrent) {
    return SetPlayerAction(
        id: player.id,
        vehicleType: isCurrent ? typeVehicle : null,
        vehicleTypes:
            (player.vehicles.map((v) => v.type).toList()) + [typeVehicle],
        points:
            player.points - Vehicle.fromType(type: typeVehicle).getBuyCost());
  }

  /// Sell a vehicle for a player
  factory PartyAction.sellVehicle(Player player, String typeVehicle) {
    final newVehicles =
        player.vehicles.where((v) => v.type != typeVehicle).toList();
    return SetPlayerAction(
        id: player.id,
        vehicleType: player.vehicle?.type == typeVehicle
            ? (newVehicles.isNotEmpty ? newVehicles.first.type : null)
            : player.vehicle?.type,
        vehicleTypes: newVehicles.map((v) => v.type).toList(),
        points:
            player.points + Vehicle.fromType(type: typeVehicle).getBuyCost());
  }

  /// Set player out of the game
  factory PartyAction.playerOut(String idPlayer) {
    return SetPlayerAction(id: idPlayer, out: true);
  }

  /// Set the player as the new current player
  factory PartyAction.updateCurrentPlayer(String idPlayer) {
    return UpdateCurrentPlayerAction(id: idPlayer);
  }

  /// Move the player by one tile
  factory PartyAction.movePlayer(
      String idPlayer, String idTile, double autonomyLeft) {
    return SetPlayerAction(
        id: idPlayer, idCurrentTile: idTile, autonomy: autonomyLeft);
  }

  /// Set the a new POI goal for the player
  factory PartyAction.updatePlayerGoalPOI(String idPlayer, String idGoalPOI) {
    return SetPlayerAction(id: idPlayer, idGoalPOI: idGoalPOI);
  }

  /// Update "End of Round"
  factory PartyAction.updateEOR(bool isEOR, List<String> idPlayersRemaining) {
    return UpdateEORAction(isEOR, idPlayersRemaining);
  }

  /// updateVehicleAutonomy (player, vehicle,
  factory PartyAction.updateVehicleAutonomy(String idPlayer, double autonomy) {
    return SetPlayerAction(id: idPlayer, autonomy: autonomy);
  }

  /// Update the player's mysteries cards
  factory PartyAction.updatePlayerMysteryCards(
      String idPlayer, List<MysteryCard> cards) {
    return PartyAction.updatePlayerMysteryCards(idPlayer, cards);
  }

  /// Launch an event animation
  factory PartyAction.eventAnimation(EventAnimation eventAnimation) {
    return EventAnimationAction(eventAnimation);
  }
}

/// Add a player to the party
class AddPlayerPartyAction extends PartyAction {
  @override
  String get type => "add_player";

  String id;

  String name;

  AddPlayerPartyAction(this.id, this.name, {String idAction = ''})
      : super(idAction: idAction);

  @override
  Map<String, dynamic> get payload => {"id": id, "name": name};

  factory AddPlayerPartyAction.fromJson(Map<String, dynamic> json) {
    return AddPlayerPartyAction(
      json["payload"]["id"] as String,
      json["payload"]["name"] as String,
      idAction: json["id_action"] as String,
    );
  }

  @override
  void perform(Party party) {
    party.players.add(Player(id, name: name));
  }
}

/// Set player values
class SetPlayerAction extends PartyAction {
  @override
  String get type => "set_player";

  String id;

  String? name;

  double? autonomy;

  double? load;

  String? vehicleType;

  List<String>? vehicleTypes;

  String? idGoalPOI;

  String? idCurrentTile;

  bool? ready;

  bool? out;

  PointCard? points;

  SetPlayerAction(
      {required this.id,
      this.name,
      this.autonomy,
      this.load,
      this.vehicleType,
      this.vehicleTypes,
      this.idGoalPOI,
      this.idCurrentTile,
      this.ready,
      this.out,
      this.points,
      String idAction = ''})
      : super(idAction: idAction);

  @override
  Map<String, dynamic> get payload => {
        "id": id,
        "name": name,
        "autonomy": autonomy,
        "load": load,
        "vehicleType": vehicleType,
        "vehicleTypes": vehicleTypes,
        "idGoalPOI": idGoalPOI,
        "idCurrentTile": idCurrentTile,
        "ready": ready,
        "out": out,
        "points": points,
      };

  factory SetPlayerAction.fromJson(Map<String, dynamic> json) {
    return SetPlayerAction(
        id: json["payload"]["id"] as String,
        name: json["payload"]["name"] as String?,
        autonomy: json["payload"]["autonomy"] as double?,
        load: json["payload"]["load"] as double?,
        vehicleType: json["payload"]["vehicleType"] as String?,
        vehicleTypes: (json["payload"]["vehicleTypes"] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        idGoalPOI: json["payload"]["idGoalPOI"] as String?,
        idCurrentTile: json["payload"]["idCurrentTile"] as String?,
        ready: json["payload"]["ready"] as bool?,
        out: json["payload"]["out"] as bool?,
        idAction: json["id_action"] as String,
        points: json["payload"]["points"] != null
            ? PointCard.fromJson(json["payload"]["points"])
            : null);
  }

  @override
  void perform(Party party) {
    var player = party.players.firstWhere((element) => element.id == id);
    if (name != null) {
      player.name = name!;
    }
    if (autonomy != null) {
      player.autonomy = autonomy!;
    }
    if (load != null) {
      player.load = load!;
    }
    if (vehicleType != null) {
      player.vehicle = Vehicle.fromType(type: vehicleType!);
    }
    if (vehicleTypes != null) {
      player.vehicles =
          vehicleTypes!.map((e) => Vehicle.fromType(type: e)).toList();
    }
    if (idGoalPOI != null) {
      player.goalPOI =
          party.board.pois.firstWhere((element) => element.id == idGoalPOI);
    }
    if (idCurrentTile != null) {
      player.currentTile = party.board.tiles
          .firstWhere((element) => element.id == idCurrentTile);
    }
    if (ready != null) {
      player.ready = ready!;
    }
    if (out != null) {
      player.out = out!;
    }
    if (points != null) {
      player.points = points!;
    }
  }
}

/// Add a tile to the board (id, x, y)
class AddTileAction extends PartyAction {
  @override
  String get type => "add_tile";

  String id;

  int x;

  int y;

  AddTileAction(this.id, this.x, this.y, {String idAction = ''})
      : super(idAction: idAction);

  @override
  Map<String, dynamic> get payload => {"id": id, "x": x, "y": y};

  factory AddTileAction.fromJson(Map<String, dynamic> json) {
    return AddTileAction(json["payload"]["id"] as String,
        json["payload"]["x"] as int, json["payload"]["y"] as int,
        idAction: json["id_action"] as String);
  }

  @override
  void perform(Party party) {
    party.board.addTile(id, x, y);
  }
}

/// connectTiles (idFrom, idTo, oneWayOnly)
class ConnectTilesAction extends PartyAction {
  @override
  String get type => "connect_tiles";

  String idFrom;

  String idTo;

  bool oneWayOnly;

  ConnectTilesAction(this.idFrom, this.idTo, this.oneWayOnly,
      {String idAction = ''})
      : super(idAction: idAction);

  @override
  Map<String, dynamic> get payload =>
      {"idFrom": idFrom, "idTo": idTo, "oneWayOnly": oneWayOnly};

  factory ConnectTilesAction.fromJson(Map<String, dynamic> json) {
    return ConnectTilesAction(
        json["payload"]["idFrom"] as String,
        json["payload"]["idTo"] as String,
        json["payload"]["oneWayOnly"] as bool,
        idAction: json["id_action"] as String);
  }

  @override
  void perform(Party party) {
    party.board.connectTiles(idFrom, idTo, oneWayOnly);
  }
}

/// decorate a tile (id, type_decoration, args)
class DecorateTileAction extends PartyAction {
  @override
  String get type => "decorate_tile";

  String id;

  String typeDecoration;

  Map<String, dynamic> args;

  DecorateTileAction(this.id, this.typeDecoration, this.args,
      {String idAction = ''})
      : super(idAction: idAction);

  @override
  Map<String, dynamic> get payload =>
      {"id": id, "typeDecoration": typeDecoration, "args": args};

  factory DecorateTileAction.fromJson(Map<String, dynamic> json) {
    return DecorateTileAction(
        json["payload"]["id"] as String,
        json["payload"]["typeDecoration"] as String,
        json["payload"]["args"] as Map<String, dynamic>,
        idAction: json["id_action"] as String);
  }

  @override
  void perform(Party party) {
    party.board.decorateTile(id, typeDecoration, args);
  }
}

/// update current player playing (id or number tile left)
class UpdateCurrentPlayerAction extends PartyAction {
  @override
  String get type => "update_current_player";

  String id;

  UpdateCurrentPlayerAction({required this.id, String idAction = ''})
      : super(idAction: idAction);

  @override
  Map<String, dynamic> get payload => {
        "id": id,
      };

  factory UpdateCurrentPlayerAction.fromJson(Map<String, dynamic> json) {
    return UpdateCurrentPlayerAction(
        id: json["payload"]["id"] as String,
        idAction: json["id_action"] as String);
  }

  @override
  void perform(Party party) {
    party.currentPlayer =
        party.players.firstWhere((element) => element.id == id);
  }
}

/// update player points
class UpdatePlayerPointsAction extends PartyAction {
  @override
  String get type => "update_player_points";

  String id;

  PointCard pointCard;

  UpdatePlayerPointsAction(this.id, this.pointCard, {String idAction = ''})
      : super(idAction: idAction);

  @override
  Map<String, dynamic> get payload =>
      {"id": id, "pointCard": pointCard.toJson()};

  factory UpdatePlayerPointsAction.fromJson(Map<String, dynamic> json) {
    return UpdatePlayerPointsAction(
        json["payload"]["id"] as String,
        PointCard.fromJson(
            json["payload"]["pointCard"] as Map<String, dynamic>),
        idAction: json["id_action"] as String);
  }

  @override
  void perform(Party party) {
    var player = party.players.firstWhere((element) => element.id == id);
    player.points += pointCard;
  }
}

/// UpdateEORAction
class UpdateEORAction extends PartyAction {
  @override
  String get type => "update_eor";

  bool eor;

  List<String> idPlayersRemaining;

  UpdateEORAction(this.eor, this.idPlayersRemaining, {String idAction = ''})
      : super(idAction: idAction);

  @override
  Map<String, dynamic> get payload =>
      {"eor": eor, "idPlayersRemaining": idPlayersRemaining};

  factory UpdateEORAction.fromJson(Map<String, dynamic> json) {
    return UpdateEORAction(json["payload"]["eor"] as bool,
        json["payload"]["idPlayersRemaining"].cast<String>(),
        idAction: json["id_action"] as String);
  }

  @override
  void perform(Party party) {
    party.eor = eor;
    party.eorPlayers = idPlayersRemaining
        .map((e) => party.players.firstWhere((element) => element.id == e))
        .toList();
  }
}

/// Server State update
///
class UpdateServerStateAction extends PartyAction {
  @override
  String get type => "update_server_state";

  ServerState serverState;

  UpdateServerStateAction(this.serverState, {String idAction = ''})
      : super(idAction: idAction);

  @override
  Map<String, dynamic> get payload => {"serverState": serverState.toJson()};

  factory UpdateServerStateAction.fromJson(Map<String, dynamic> json) {
    return UpdateServerStateAction(
        ServerState.fromJson(
            json["payload"]["serverState"] as Map<String, dynamic>,
            init: false),
        idAction: json["id_action"] as String);
  }

  @override
  void perform(Party party) {
    party.serverState = serverState;
  }
}

/// Update Player Cards
class UpdatePlayerCardsAction extends PartyAction {
  @override
  String get type => "update_player_cards";

  String id;

  List<MysteryCard> mysteryCards;

  UpdatePlayerCardsAction(this.id, this.mysteryCards, {String idAction = ''})
      : super(idAction: idAction);

  @override
  Map<String, dynamic> get payload =>
      {"id": id, "mystery_cards": mysteryCards.map((e) => e.toJson()).toList()};

  factory UpdatePlayerCardsAction.fromJson(Map<String, dynamic> json) {
    return UpdatePlayerCardsAction(
        json["payload"]["id"] as String,
        (json["payload"]["mystery_cards"] as List<dynamic>)
            .map((e) => MysteryCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        idAction: json["id_action"] as String);
  }

  @override
  void perform(Party party) {
    var player = party.players.firstWhere((element) => element.id == id);
    player.mysteryCards = mysteryCards;
  }
}


/// Event animation
class EventAnimationAction extends PartyAction {
  @override
  String get type => "event_animation";

  final EventAnimation eventAnimation;

  EventAnimationAction(this.eventAnimation, {String idAction = ''})
      : super(idAction: idAction);

  @override
  Map<String, dynamic> get payload => {
        "event_animation": eventAnimation.toJson(),
      };

  factory EventAnimationAction.fromJson(Map<String, dynamic> json) {
    return EventAnimationAction(
        EventAnimation.fromJson(
            json["payload"]["event_animation"] as Map<String, dynamic>),
        idAction: json["id_action"] as String);
  }

  @override
  void performClientSide(Party party, EventAnimationRepository eventAnimationRepository) {
    eventAnimationRepository.addEventAnimation(eventAnimation);
  }
}

