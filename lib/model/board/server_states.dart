import 'dart:math';

import 'package:dcn_game/model/board/mystery_card.dart';
import 'package:dcn_game/model/event_animation.dart';
import 'package:uuid/uuid.dart';

import 'board.dart';
import 'party.dart';
import 'party_action.dart';

// This file is an implementation of this state diagram:
// ```mermaid
// stateDiagram-v2
//
// %% all states with "" are automatic
// waiting_player: Wating players
// start_game: "Start game"
// note right of start_game
//     Setting up all back things
//     for the game to be launch
// end note
// new_round: "New round"
// note left of new_round: Rolling new target for all players
// choise_vehicle: Choise vehicle
// note left of choise_vehicle
//     Players can buy and sell(?)
//     there vehicles
// end note
// new_player: "New player to move"
// note left of new_player
//     Setting up the next player
//     that will move
// end note
// state "Waiting for the player
// to choise a branche to move" as player_choise_branch
//
// server_move : "Server processing move"
// state server_move {
//     move_next_tile: "Moving to the next tile"
//     process_action_poi: "Porcess actions POI"
//     note right of process_action_poi
//         If the target of the player is the poi,
//         set new target to the warehouse.
//         If the target and the poi are the warehouse,
//         set the round as "finishing"
//         (all other players play one more move)
//     end note
//
//     [*] --> move_next_tile
//     move_next_tile --> process_action_poi: [hiting poi]
//     process_action_poi --> move_next_tile
// }
// game_over: Game over
//
// [*] --> waiting_player : Create a new game
// waiting_player --> waiting_player: player  [not] ready
// waiting_player --> waiting_player: new player
// waiting_player --> start_game: player ready [nb_players >= 2 && all ready]
// start_game --> new_round
// new_round --> game_over: [all round ended]
// new_round --> choise_vehicle
// choise_vehicle --> choise_vehicle: player [not] ready
// choise_vehicle --> new_player: [all players ready & have >=1vehicle]
// new_player --> new_player: player out [can use current vehicle]
// new_player --> game_over: [all player are out]
// new_player --> player_choise_branch
// player_choise_branch --> server_move: player chose path [right idPlayer & idParty & idTile]
// server_move --> player_choise_branch: hiting a branch [move left]
// server_move --> new_player: No move left
// new_player --> new_round: [finishing & no more players remaning]
// ```

/// The etat of the server containing the current state of the server game
class ServerEtat {
  /// The current party
  late Party party;

  /// The current state of the server
  late ServerState _state;

  ServerState get state => _state;

  set state(ServerState newState) {
    party.addAction(UpdateServerStateAction(newState));
    _state = newState;
    if (newState.canInit) {
      newState.init();
    }
  }

  ServerEtat() {
    initParty();
  }

  /// init the party
  void initParty() {
    party = Party(const Uuid().v4());
    party.initBoardA();
    state = WaitingForPlayerServerState(this);
  }

  /// create a new game
  void newGame() => state.newGame();

  /// add a player to the game
  void newPlayer(String id, String name) => state.newPlayer(id, name);

  /// Set a player status ready or not
  void playerReady(String id, bool isReady) => state.playerReady(id, isReady);

  /// During the shop phase, buy a vehicle for a player
  /// must have enough points and not already have it
  void buyVehicle(String idPlayer, String type) =>
      state.buyVehicle(idPlayer, type);

  /// During the shop phase, sell a vehicle for a player
  /// must have at least 2 vehicle and the right vehicle
  void sellVehicle(String idPlayer, String type) =>
      state.sellVehicle(idPlayer, type);

  /// player choose a branch
  void playerChooseBranch(String idTile) => state.playerChooseBranch(idTile);
}

/// The state of the server
abstract class ServerState {
  /// The etat
  late ServerEtat etat;

  /// True if the init field can be called
  /// (once the init is called, this value is set to false)
  late bool canInit;

  /// If the etat is not provided, init must be false, all methods member
  /// must not be called and same for etat.
  ServerState({ServerEtat? etat, bool init = true})
      : assert(etat != null || !init) {
    canInit = init;
    if (etat != null) {
      this.etat = etat;
    }
  }

  /// Init the state (called in the constructor)
  void init() {}

  /// Create a new game
  void newGame() {
    etat.initParty();
  }

  /// Add a player to the game
  void newPlayer(String id, String name) {}

  /// Set a player status ready or not
  void playerReady(String id, bool isReady) {}

  /// During the shop phase, buy a vehicle for a player
  /// must have enough points and not already have it
  void buyVehicle(String idPlayer, String type) {}

  /// During the shop phase, sell a vehicle for a player
  /// must have at least 2 vehicle and the right vehicle
  void sellVehicle(String idPlayer, String type) {}

  /// player choose a branch
  void playerChooseBranch(String idTile) {}

  /// from json factory
  factory ServerState.fromJson(Map<String, dynamic> json,
      {ServerEtat? etat, bool init = true}) {
    switch (json['type']) {
      case 'WaitingForPlayerServerState':
        return WaitingForPlayerServerState.fromJson(json,
            etat: etat, init: init);
      case 'StartGameServerState':
        return StartGameServerState.fromJson(json, etat: etat, init: init);
      case 'NewRoundServerState':
        return NewRoundServerState.fromJson(json, etat: etat, init: init);
      case 'ChooseVehicleServerState':
        return ChooseVehicleServerState.fromJson(json, etat: etat, init: init);
      case 'NewPlayerServerState':
        return NewPlayerServerState.fromJson(json, etat: etat, init: init);
      case 'ChooseBranchServerState':
        return ChooseBranchServerState.fromJson(json, etat: etat, init: init);
      case 'MovePlayerServerState':
        return MovePlayerServerState.fromJson(json, etat: etat, init: init);
      case 'GameOverServerState':
        return GameOverServerState.fromJson(json, etat: etat, init: init);
      default:
        throw Exception('Unknown type of ServerState, '
            'did you forget to add it to the factory?');
    }
  }

  /// to json
  Map<String, dynamic> toJson() {
    return {
      'type': runtimeType.toString(),
    };
  }
}

/// The state of the server when waiting for players
class WaitingForPlayerServerState extends ServerState {
  WaitingForPlayerServerState(ServerEtat? etat, {bool init = true})
      : super(etat: etat, init: init);

  factory WaitingForPlayerServerState.fromJson(Map<String, dynamic> json,
          {ServerEtat? etat, bool init = true}) =>
      WaitingForPlayerServerState(etat, init: init);

  @override
  void newPlayer(String id, String name) {
    etat.party.addAction(PartyAction.newPlayer(id, name));
  }

  @override
  void playerReady(String id, bool isReady) {
    etat.party.addAction(PartyAction.playerReady(id, isReady));
    if (etat.party.isReadyToStart()) {
      // turn all ready player to not ready
      for (final player in etat.party.players) {
        etat.party.addAction(PartyAction.playerReady(player.id, false));
      }
      etat.state = StartGameServerState(etat);
    }
  }
}

class StartGameServerState extends ServerState {
  StartGameServerState(ServerEtat? etat, {bool init = true})
      : super(etat: etat, init: init);

  factory StartGameServerState.fromJson(Map<String, dynamic> json,
          {ServerEtat? etat, bool init = true}) =>
      StartGameServerState(etat, init: init);

  @override
  void init() {
    // TODO: setup the game if needed
    etat.state = NewRoundServerState(etat);
  }
}

class NewRoundServerState extends ServerState {
  NewRoundServerState(ServerEtat? etat, {bool init = true})
      : super(etat: etat, init: init);

  factory NewRoundServerState.fromJson(Map<String, dynamic> json,
          {ServerEtat? etat, bool init = true}) =>
      NewRoundServerState(etat, init: init);

  @override
  void init() {
    // TODO : if already 3 round are passed : game over

    // TODO : show stats

    // new commune target for all players
    final targetId = etat
        .party.board.pois[Random().nextInt(etat.party.board.pois.length)].id;
    final startIdTile = etat.party.board.tiles
        .firstWhere((element) => element.containsWarehouse())
        .id;
    for (final player in etat.party.players) {
      etat.party.addAction(
          PartyAction.setupPlayerNewRound(player.id, targetId, startIdTile));
    }
    // disable End of Round
    etat.party.addAction(PartyAction.updateEOR(false, []));

    etat.state = ChooseVehicleServerState(etat);
  }
}

class ChooseVehicleServerState extends ServerState {
  ChooseVehicleServerState(ServerEtat? etat, {bool init = true})
      : super(etat: etat, init: init);

  factory ChooseVehicleServerState.fromJson(Map<String, dynamic> json,
          {ServerEtat? etat, bool init = true}) =>
      ChooseVehicleServerState(etat, init: init);

  @override
  void init() {
    // reset readiness of all players
    for (final player in etat.party.players) {
      etat.party.addAction(PartyAction.playerReady(player.id, false));
    }
  }

  @override
  void buyVehicle(String idPlayer, String type) {
    final player =
        etat.party.players.firstWhere((element) => element.id == idPlayer);
    final vehicle = Vehicle.fromType(type: type);
    // check if the player can buy the vehicle
    if (vehicle.getBuyCost() <= player.points &&
        !player.vehicles.map((v) => v.type).contains(vehicle.type)) {
      etat.party.addAction(PartyAction.buyVehicle(player, vehicle.type, true));
    }
  }

  @override
  void sellVehicle(String idPlayer, String type) {
    final player =
        etat.party.players.firstWhere((element) => element.id == idPlayer);
    final vehicle = Vehicle.fromType(type: type);
    // check if the player can sell the vehicle
    if (player.vehicles.isNotEmpty &&
        player.vehicles.map((v) => v.type).contains(vehicle.type)) {
      etat.party.addAction(PartyAction.sellVehicle(player, vehicle.type));
    }
  }

  @override
  void playerReady(String id, bool isReady) {
    final player = etat.party.players.firstWhere((element) => element.id == id);
    if (isReady && player.vehicles.isNotEmpty) {
      etat.party.addAction(PartyAction.playerReady(id, isReady));
    }

    if (etat.party.isReadyToStart()) {
      // turn all ready player to not ready
      for (final player in etat.party.players) {
        etat.party.addAction(PartyAction.playerReady(player.id, false));
      }
      etat.state = NewPlayerServerState(etat);
    }
  }
}

class NewPlayerServerState extends ServerState {
  NewPlayerServerState(ServerEtat? etat, {bool init = true})
      : super(etat: etat, init: init);

  factory NewPlayerServerState.fromJson(Map<String, dynamic> json,
          {ServerEtat? etat, bool init = true}) =>
      NewPlayerServerState(etat, init: init);

  @override
  void init() {
    // if all players are out => game over
    if (etat.party.players.every((p) => p.out)) {
      etat.state = GameOverServerState(etat);
    }

    // choose the next player
    if (etat.party.eor) {
      // take the next player remaining
      if (etat.party.eorPlayers.isNotEmpty) {
        final nextPlayer = etat.party.eorPlayers.removeAt(0);
        etat.party.addAction(PartyAction.updateCurrentPlayer(nextPlayer.id));
      } else {
        // The end of the round, no more players remaining
        etat.state = NewRoundServerState(etat);
        return;
      }
    } else {
      // choose the next player normally
      int currentIndex;
      currentIndex = etat.party.players
          .indexWhere((p) => p.id == (etat.party.currentPlayer?.id ?? -1));

      // number of skipped players
      int cpt = 0;
      do {
        // skip the player turn
        if (cpt > 0) {
          // update mystery cards timer
          etat.party.players[currentIndex]
              .updateRoundTimedMysteryCard(etat.party);
        }

        currentIndex++;
        cpt++;

        if (currentIndex >= etat.party.players.length) {
          currentIndex = 0;
        }
      } while (etat.party.players[currentIndex].out ||
          etat.party.players[currentIndex].isStuck());

      etat.party.addAction(
          PartyAction.updateCurrentPlayer(etat.party.players[currentIndex].id));
    }

    // update autonomy to max
    etat.party.addAction(
      PartyAction.updateVehicleAutonomy(etat.party.currentPlayer!.id,
          etat.party.currentPlayer!.vehicle!.autonomy.toDouble()),
    );

    // deduce the point to use the vehicle
    if (etat.party.currentPlayer!.points >=
        etat.party.currentPlayer!.vehicle!.getUseCost()) {
      etat.party.currentPlayer!.points -=
          etat.party.currentPlayer!.vehicle!.getUseCost();
    } else {
      // This player can't move, he is out
      etat.party.addAction(PartyAction.playerOut(etat.party.currentPlayer!.id));
      etat.state = NewPlayerServerState(etat);
      return;
    }

    etat.state = ChooseBranchServerState(etat);
  }
}

class ChooseBranchServerState extends ServerState {
  ChooseBranchServerState(ServerEtat? etat, {bool init = true})
      : super(etat: etat, init: init);

  factory ChooseBranchServerState.fromJson(Map<String, dynamic> json,
          {ServerEtat? etat, bool init = true}) =>
      ChooseBranchServerState(etat, init: init);

  @override
  void playerChooseBranch(String idTile) {
    // check if the tile is a possible branch
    final tile = etat.party.currentPlayer!.currentTile!
        .possibleNexts(etat.party.currentPlayer!)
        .map((t) => t.id)
        .contains(idTile);
    if (tile) {
      etat.state = MovePlayerServerState(etat, idTile);
    }
  }
}

class MovePlayerServerState extends ServerState {
  final String idTile;

  MovePlayerServerState(ServerEtat? etat, this.idTile, {bool init = true})
      : super(etat: etat, init: init);

  factory MovePlayerServerState.fromJson(Map<String, dynamic> json,
          {ServerEtat? etat, bool init = true}) =>
      MovePlayerServerState(etat, json['idTile'], init: init);

  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({'idTile': idTile});

  @override
  void init() {
    final currentPlayer = etat.party.currentPlayer!;
    var endOfTurn = currentPlayer.autonomy <= 0;

    // get the bard action of the tile
    var boardActions = currentPlayer.currentTile!.onPass();
    if (endOfTurn) {
      boardActions += currentPlayer.currentTile!.onStop();
    }

    // perform the board action and if its end of turn, end the turn
    if (performBoardAction(boardActions) || endOfTurn) {
      etat.state = NewPlayerServerState(etat);
      return;
    }

    // save the current position before the move for after when checking
    // if hitting a branch
    final BTile previousTile = currentPlayer.currentTile!;

    // move the player
    etat.party.addAction(PartyAction.movePlayer(
        currentPlayer.id,
        idTile,
        currentPlayer.autonomy -
            1 / previousTile.getSpeed() * currentPlayer.cardSpeedModifier()));

    // check if the player is on the target
    if (currentPlayer.currentTile!.id == currentPlayer.goalPOI!.id) {
      // if the poi is the warehouse ?
      if (currentPlayer.currentTile!.containsWarehouse()) {
        // if the he is the first player to attend to the warehouse,
        // turn true "End of Round"
        if (!etat.party.eor) {
          etat.party.addAction(PartyAction.updateEOR(
              true,
              etat.party.players
                  .map((p) => p.id)
                  .where((pId) => pId != currentPlayer.id)
                  .toList()));
          // set autonomy to 0 to prevent the player to move
          etat.party.addAction(
              PartyAction.updateVehicleAutonomy(currentPlayer.id, 0));
        }
      } else {
        // set the objective to the warehouse
        etat.party.addAction(PartyAction.updatePlayerGoalPOI(
            currentPlayer.id,
            etat.party.board.tiles
                .firstWhere((element) => element.containsWarehouse())
                .id));
      }
    }

    // check if hitting a branch
    // next possible move if removing where the player came from
    // 3 case :
    // - 0 : no possible move (ask the player to move backward)
    // - 1 : A possible way (move automatically)
    // - >1 : Multiple possible way (ask the play)
    final possibleNextMove = currentPlayer.currentTile!.nexts
        .where((t) => t.id != previousTile.id)
        .toList();
    if (possibleNextMove.length != 1 && currentPlayer.autonomy > 0) {
      etat.state = ChooseBranchServerState(etat);
    } else {
      etat.state = MovePlayerServerState(etat, possibleNextMove.first.id);
    }
  }

  /// Perform a list of board actions
  /// True is returned if is the end of the player turn
  bool performBoardAction(List<BoardAction> boardActions) {
    final currentPlayer = etat.party.currentPlayer!;
    var endOfTurn = false;

    for (BoardAction boardAction in boardActions) {
      switch (boardAction.runtimeType) {
        case TakeMysteryCard:
          // pick a card
          final card = TakeMysteryCard.getMysteryCard();

          // launch the pick card animation
          etat.party.addAction(
            PartyAction.eventAnimation(
              MysteryCardPickedEventAnimation(
                mysteryCard: card,
                playerId: currentPlayer.id,
              ),
            ),
          );

          if (card.stopPlayerTurnWhenPicked) {
            endOfTurn = true;
          }

          // is a card that is applied to all players ?
          if (card is AllPlayersMysteryCard) {
            for (Player player in etat.party.players) {
              if (card is RoundTimedMysteryCard) {
                etat.party.addAction(PartyAction.updatePlayerMysteryCards(
                    player.id, player.mysteryCards + [card]));
              } else {
                // TODO : if is oneshot card
              }
            }
          } else {
            if (card is RoundTimedMysteryCard) {
              etat.party.addAction(PartyAction.updatePlayerMysteryCards(
                  currentPlayer.id, currentPlayer.mysteryCards + [card]));
            } else {
              // TODO : if is oneshot card
            }
          }
          break;
        default:
          throw Exception('BoardAction not implemented : $boardAction');
      }
    }

    return endOfTurn;
  }
}

class GameOverServerState extends ServerState {
  GameOverServerState(ServerEtat? etat, {bool init = true})
      : super(etat: etat, init: init);

  factory GameOverServerState.fromJson(Map<String, dynamic> json,
          {ServerEtat? etat, bool init = true}) =>
      GameOverServerState(etat, init: init);

// TODO game over state
}

// /// waiting for player to join
// class WaitingForPlayerServerState extends ServerState {
//   WaitingForPlayerServerState(ServerEtat etat) : super(etat);
//
//   @override
//   void newPlayer(String id, String name) {
//     etat.party.addAction(AddPlayerPartyAction(id, name));
//   }
//
//   @override
//   void startGame() {
//     if (etat.party.players.length < 2) {
//       return;
//     }
//     for (final player in etat.party.players) {
//       etat.party.addAction(SetPlayerAction(
//         id: player.id,
//         load: Random().nextDouble() * 15,
//         vehicleType:
//             Vehicle.allTypes[Random().nextInt(Vehicle.allTypes.length)],
//         idGoalPOI: etat.party.board
//             .pois[Random().nextInt(etat.party.board.pois.length)].id,
//         idCurrentTile: etat.party.board.tiles
//             .firstWhere((element) => element.contains(WarehouseBTile.sType))
//             .id,
//       ));
//       // deduce the point to buy the vehicle
//       player.points -= player.vehicle!.getBuyCost();
//
//       // set the autonomy to max
//       etat.party.addAction(
//           SetPlayerAction(id: player.id, autonomy: player.vehicle?.autonomy));
//     }
//
//     etat.party.addAction(UpdateCurrentPlayerAction(
//         id: etat
//             .party.players[Random().nextInt(etat.party.players.length)].id));
//
//     etat.state = WaitingForPlayerChooseBranchServerState(etat);
//     (etat.state as WaitingForPlayerChooseBranchServerState)
//         .setMaxCurrentPlayerAutonomy();
//   }
// }
//
// /// waiting for player to choose a branch
// /// the player is on a branch
// class WaitingForPlayerChooseBranchServerState extends ServerState {
//   WaitingForPlayerChooseBranchServerState(ServerEtat etat) : super(etat);
//
//   void setMaxCurrentPlayerAutonomy() {
//     etat.party.addAction(SetPlayerAction(
//         id: etat.party.currentPlayer!.id,
//         autonomy: etat.party.currentPlayer!.vehicle?.autonomy ?? 0));
//   }
//
//   @override
//   void playerChooseBranch(String idTile) {
//     if (etat.party.currentPlayer?.currentTile?.nexts
//             .map((t) => t.id)
//             .contains(idTile) ??
//         false) {
//       // update the player position
//       etat.party.addAction(SetPlayerAction(
//           id: etat.party.currentPlayer!.id,
//           idCurrentTile: idTile,
//           autonomy: etat.party.currentPlayer!.autonomy - 1));
//       // check if the player is on his goal
//       if (etat.party.currentPlayer?.goalPOI != null &&
//           etat.party.currentPlayer?.currentTile?.id ==
//               etat.party.currentPlayer?.goalPOI?.id) {
//         // then the deduce the max load of the vehicle from the player load
//         // if all is delivered, then the player win
//         etat.party.addAction(SetPlayerAction(
//             id: etat.party.currentPlayer!.id,
//             load: max(
//                 0,
//                 etat.party.currentPlayer!.load -
//                     etat.party.currentPlayer!.vehicle!.maxLoad)));
//         // if the player have no more load, then he win
//         // if (etat.party.currentPlayer!.load == 0) {
//         //   etat.party
//         //       .addAction(SetPlayerAction(id: etat.party.currentPlayer!.id));
//         //   etat.state = GameOverServerState(etat);
//         //   return;
//         // }
//
//       }
//       // check if the player can move
//       if (etat.party.currentPlayer!.autonomy > 0) {
//         etat.state = WaitingForPlayerChooseBranchServerState(etat);
//       } else {
//         // choose the next player
//         int currentIndex;
//         do {
//           currentIndex = etat.party.players.indexWhere(
//               (element) => element.id == etat.party.currentPlayer!.id);
//           currentIndex++;
//           if (currentIndex >= etat.party.players.length) {
//             currentIndex = 0;
//           }
//         } while (!etat.party.players[currentIndex].canMove());
//
//         // deduce the point to use the vehicle
//         etat.party.currentPlayer!.points -=
//             etat.party.currentPlayer!.vehicle!.getUseCost();
//
//         etat.party.addAction(
//             UpdateCurrentPlayerAction(id: etat.party.players[currentIndex].id));
//         etat.state = WaitingForPlayerChooseBranchServerState(etat);
//         (etat.state as WaitingForPlayerChooseBranchServerState)
//             .setMaxCurrentPlayerAutonomy();
//       }
//     }
//   }
// }
//
// /// game over
// class GameOverServerState extends ServerState {
//   GameOverServerState(ServerEtat etat) : super(etat);
// }
