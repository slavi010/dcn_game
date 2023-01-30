import 'dart:async';

import 'package:cubes/cubes.dart';
import 'package:dcn_game/model/board/party_action.dart';
import 'package:dcn_game/model/index.dart';
import 'package:dcn_game/model/repository/event_animation_repository.dart';
import 'package:hive/hive.dart';

import '../../server/api.dart';
import '../board/board.dart';
import '../board/party.dart';

/// The current repository of the party
class PartyRepository {
  /// The current party
  final party = ObservableValue<Party?>(value: null);

  /// the rest client
  final RestClient restClient;

  /// this player id
  String? thisPlayerId;

  static const String hiveBoxName = "party";

  /// this player
  Player? get thisPlayer {
    if (party.value == null) {
      return null;
    }
    for (Player player in party.value!.players) {
      if (player.id == thisPlayerId) {
        return player;
      }
    }
    return null;
  }

  PartyRepository(this.restClient) {
    load();

    // update the party every X seconds
    Timer.periodic(const Duration(seconds: 2), (_) => updateParty());
  }

  /// Save the party id and this player id in Hive
  void save() {
    var box = Hive.box(hiveBoxName);
    box.put("party_id", party.value!.id);
    box.put("player_id", thisPlayerId);
  }

  /// Load the party id and this player id from Hive
  void load() {
    var box = Hive.box(hiveBoxName);
    var partyId = box.get("party_id");
    thisPlayerId = box.get("player_id");
    if (partyId != null) {
      party.value = Party(partyId);
    }
  }

  /// fetch the current party
  Future<void> updateParty() async {
    List<PartyAction> history;
    try {
      // fetch the party id
      var res = await restClient.getPartyId();
      final id = res.id;
      if (party.value == null || party.value!.id != id) {
        // fetch all the history of the current party
        // TODO : maybe edit this for supporting multiple parties
        history = await restClient.getPartyHistory(id);
        thisPlayerId = null;
        party.update(Party(id));
      } else {
        // fetch the party history
        history = await restClient.getPartyHistorySince(
            id, party.value!.history.length);
      }
    } catch (e) {
      print(e);
      return;
    }


    // apply the history
    for (final action in history) {
      // check if the action is not already in the local history
      if (party.value!.history
              .indexWhere((a) => a.idAction == action.idAction) ==
          -1) {
        party.value!.addAction(
          action,
          perform: true,
        );
      }

      if (action is EventAnimationAction) {
        Cubes.get<EventAnimationRepository>()
            .addEventAnimation(action.eventAnimation);
      }
    }

    save();

    party.notifyListeners();
  }

  /// Join the party as a new player
  Future<void> joinParty(String name) async {
    // join the party
    final res = await restClient.addPlayer(party.value?.id ?? "", name);
    thisPlayerId = res.id;
    // update the party
    await updateParty();
  }

  /// restart the game
  Future<void> restartGame() async {
    // restart the game
    await restClient.newGame();
    // update the party
    await updateParty();
  }

  /// choose a branch
  Future<void> chooseBranch(String idTile) async {
    if (thisPlayerId == null) {
      return;
    }
    // choose a branch
    await restClient.chooseBranch(party.value?.id ?? "", thisPlayerId!, idTile);
    // update the party
    await updateParty();
  }

  /// Update player readiness
  Future<void> updatePlayerReadiness(bool isReady) async {
    if (thisPlayerId == null) {
      return;
    }

    await restClient.updatePlayerReadiness(
        party.value?.id ?? "", thisPlayerId!, isReady ? 1 : 0);
    // update the party
    await updateParty();
  }

  /// Buy vehicle player
  Future<void> buyVehiclePlayer(String type) async {
    if (thisPlayerId == null) {
      return;
    }

    await restClient.buyVehiclePlayer(
        party.value?.id ?? "", thisPlayerId!, type);
    // update the party
    await updateParty();
  }

  /// Sell vehicle player
  Future<void> sellVehiclePlayer(String type) async {
    if (thisPlayerId == null) {
      return;
    }

    await restClient.sellVehiclePlayer(
        party.value?.id ?? "", thisPlayerId!, type);
    // update the party
    await updateParty();
  }
}
