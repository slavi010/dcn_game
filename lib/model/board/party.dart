import 'package:dcn_game/model/board/party_action.dart';
import 'package:dcn_game/model/board/server_states.dart';
import 'package:uuid/uuid.dart';

import 'board.dart';

/// Contain all the information about the current party
/// - the board
/// - all players
class Party {
  /// the id of the party
  String id;

  /// The board of the party
  final Board board = Board();

  /// The players of the party
  final List<Player> players = [];

  /// history of all the actions of the party
  final List<PartyAction> history = [];

  /// The current player
  Player? currentPlayer;

  /// If the party is in the phase "End of Round'
  /// All the players will only play one more time
  /// (all the user remaining to player are listed in the list eorPlayers)
  /// If there are no more players and eor is true, the round is finished
  bool eor = false;

  /// All player remaining to play during the end of round.
  /// End of Round Players
  List<Player> eorPlayers = [];

  /// The state of the server
  /// Can be null at the beginning
  ServerState? serverState;

  Party(this.id);

  /// True if the party is already started
  /// (after the waiting room)
  bool get started =>
      serverState != null && serverState! is! WaitingForPlayerServerState;

  /// Add a new action to the party
  void addAction(PartyAction action, {bool perform = true}) {
    history.add(action);

    // clear the reachableTiles cache
    _reachableTiles = null;

    if (perform) {
      action.perform(this);
    }
  }

  /// All the available vehicles
  List<Vehicle> get vehicles =>
      Vehicle.allTypes.map((t) => Vehicle.fromType(type: t)).toList();

  /// All the reachable tiles cache
  ///
  /// See get reachableTiles
  List<BTile>? _reachableTiles;

  /// All the reachable tiles for the current player turn
  List<BTile> get reachableTiles {
    if (currentPlayer == null || currentPlayer!.currentTile == null) {
      return [];
    }
    _reachableTiles ??= board.getReachableTiles(currentPlayer!.currentTile!, currentPlayer!);

    return _reachableTiles!;
  }

  /// Config of the party


  /// An example of a map (should be not be used)
  /// init the map
  /// generate an uuid for each tile
  /// The tile have this index (referring to the same uuid)
  /// Following are the links between each tile
  /// 0 - 1 - 2
  /// |       |
  /// 7       3
  /// |       |
  /// 6 - 5 - 4
  ///
  /// - and | mean a bidirectional link
  ///
  /// Following are the information about each tile
  /// 0 : x=0, y = 0, [links: 1, 7], (warehouse)
  /// 1 : x=10, y = 0, [0, 2]
  /// 2 : x=20, y = 0, [1, 3]
  /// 3 : x=20, y = 10, [2, 4] (highway)
  /// 4 : x=20, y = 20 [3, 5]
  /// 5 : x=10, y = 20 [4, 6]
  /// 6 : x=0, y = 20 [5, 7] (poi="Gare de Nantes")
  /// 7 : x=0, y = 10 [6, 0]
  void initDefaultBoard() {
    final List<dynamic> tiles = [
      [
        0,
        0,
        [1, 7],
        "poi",
        {"poiName": "Warehouse"}
      ],
      [
        100,
        0,
        [0, 2],
        null
      ],
      [
        200,
        0,
        [1, 3],
        null
      ],
      [
        200,
        100,
        [2, 4],
        null
      ],
      [
        200,
        200,
        [3, 5],
        null
      ],
      [
        100,
        200,
        [4, 6],
        null
      ],
      [
        0,
        200,
        [5, 7],
        "poi",
        {"poiName": "Gare de Nantes"}
      ],
      [
        0,
        100,
        [6, 0],
        null
      ],
    ];

    initFromJson(tiles);
  }

  /// Init a board from json config
  void initFromJson(List<dynamic> tiles) {
    final uuids = List.generate(tiles.length, (index) => const Uuid().v4());
    // create the tiles
    var index = 0;
    for (var tile in tiles) {
      addAction(AddTileAction(uuids[index], tile[0], tile[1]));
      if (tile.length > 3) {
        // add special actions to the chained cards
        for (var special in tile[3]) {
          addAction(DecorateTileAction(uuids[index], special["type"], special));
        }
      }
      index++;
    }

    // connect the tiles
    index = 0;
    for (var tile in tiles) {
      for (var link in tile[2]) {
        addAction(ConnectTilesAction(uuids[index], uuids[link], true));
      }
      index++;
    }
  }

  /// Return true if all players are ready
  bool isReadyToStart() {
    return players.every((player) => player.ready);
  }
}
