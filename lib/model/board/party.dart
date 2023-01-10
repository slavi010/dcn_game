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

  /// add a new action to the party
  void addAction(PartyAction action, {bool perform = true}) {
    history.add(action);
    if (perform) {
      action.perform(this);
    }
  }

  /// All the available vehicles
  List<Vehicle> get vehicles =>
      Vehicle.allTypes.map((t) => Vehicle.fromType(type: t)).toList();

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
    final uuids = List.generate(8, (index) => const Uuid().v4());
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
    var index = 0;
    for (var tile in tiles) {
      addAction(AddTileAction(uuids[index], tile[0], tile[1]));
      if (tile[3] != null) {
        addAction(DecorateTileAction(uuids[index], tile[3], tile[4]));
      }
      index++;
    }

    // connect the tiles
    index = 0;
    for (var tile in tiles) {
      for (var link in tile[2]) {
        addAction(ConnectTilesAction(uuids[index], uuids[link], false));
      }
      index++;
    }
  }

  void initBoardA() {
    final uuids = List.generate(95, (index) => const Uuid().v4());
    final List<dynamic> tiles = [
      [0, 0, [], null],
      [500, 380, [2, 50, 51, 90], [{"type": "poi", "poiName": "Warehouse"}]], // 1
      [605, 352, [1, 3, 93], null],
      [645, 310, [2, 4], null],
      [685, 272, [3, 5, 55, 56], null],
      [705, 230, [4, 6], null], // 5
      [682, 185, [5, 7], null],
      [660, 150, [6, 8], null],
      [670, 120, [7, 9], null],
      [710, 110, [8, 10], null],
      [745, 107, [9, 11], null], // 10
      [783, 118, [10, 12], null],
      [825, 140, [11, 13], null],
      [862, 160, [12, 14], [{"type": "poi", "poiName": "Garage"}]],
      [850, 185, [13, 15], null],
      [800, 185, [14, 16], null], // 15
      [788, 107, [15, 17], null],
      [815, 240, [16, 18], null],
      [823, 281, [17, 19], null],
      [765, 388, [20], [{"type": "highway"}]],
      [703, 534, [21, 65, 66], null], // 20
      [694, 564, [20, 22], null],
      [694, 598, [21, 23], null],
      [692, 635, [22, 24], null],
      [674, 668, [23, 25], [{"type": "low"}]],
      [636, 648, [24, 26], [{"type": "low"}]], // 25
      [604, 627, [25, 27], null],
      [572, 607, [26, 28], [{"type": "poi", "poiName": "Shops"}, {"type": "low"}]],
      [537, 588, [27, 29], [{"type": "low"}]],
      [500, 575, [28, 30], null],
      [470, 561, [29, 31, 70, 71], [{"type": "zfe"}]], // 30
      [442, 538, [30, 32], [{"type": "zfe"}]],
      [418, 509, [31, 33], [{"type": "zfe"}]],
      [397, 472, [32, 34], [{"type": "zfe"}]],
      [378, 433, [33, 35], [{"type": "zfe"}]],
      [357, 399, [34, 36, 89], [{"type": "zfe"}]], // 35
      [325, 366, [35, 37], [{"type": "zfe"}]],
      [287, 336, [36, 38], [{"type": "zfe"}]],
      [235, 313, [37, 39], [{"type": "zfe"}]],
      [182, 321, [38, 40, 85], [{"type": "zfe"}]],
      [141, 286, [39, 41], null], // 40
      [129, 239, [40, 42], null],
      [151, 199, [41, 43], null],
      [190, 182, [42, 44], [{"type": "poi", "poiName": "Factory"}]],
      [226, 184, [43, 45], null],
      [267, 199, [44, 46], null], // 45
      [323, 202, [45, 47, 91], null],
      [365, 224, [46, 48], null],
      [403, 248, [47, 49, 92], null],
      [417, 285, [48, 50], null],
      [420, 325, [1, 49], null], // 50
      [517, 293, [1, 52], null],
      [550, 264, [51, 53], null],
      [580, 239, [52, 54, 92], null],
      [617, 223, [53, 55], [{"type": "poi", "poiName": "School"}]],
      [658, 235, [54, 4], null], // 55
      [717, 300, [4, 57], null],
      [761, 309, [56, 58], null],
      [856, 333, [57, 59], [{"type": "low"}]],
      [889, 370, [58, 60], [{"type": "low"}]],
      [894, 417, [59, 61], null], // 60
      [878, 466, [60, 62], [{"type": "low"}]],
      [858, 512, [61, 63], [{"type": "low"}]],
      [850, 563, [62, 64], [{"type": "poi", "poiName": "Hospital"}]],
      [810, 587, [63, 65, 93], null],
      [752, 565, [64, 20], null], // 65
      [660, 513, [20, 67], null],
      [617, 505, [66, 68], null],
      [577, 504, [67, 69], null],
      [538, 513, [68, 70, 90], null],
      [499, 530, [69, 30], null], // 70
      [448, 600, [30, 72], [{"type": "zfe"}]],
      [428, 641, [71, 73], [{"type": "zfe"}]],
      [395, 665, [72, 74], [{"type": "poi", "poiName": "Restaurants"}, {"type": "zfe"}]],
      [351, 650, [73, 75], [{"type": "zfe"}]],
      [330, 606, [74, 76, 94], [{"type": "zfe"}]], // 75
      [298, 580, [75, 77], [{"type": "zfe"}]],
      [255, 582, [76, 78], [{"type": "zfe"}]],
      [217, 578, [77, 79], [{"type": "zfe"}]],
      [176, 573, [78, 80], [{"type": "zfe"}]],
      [139, 551, [79, 81], [{"type": "zfe"}]], // 80
      [143, 518, [80, 82], [{"type": "zfe"}]],
      [159, 483, [81, 83, 86], [{"type": "zfe"}]],
      [189, 446, [82, 84], [{"type": "zfe"}]],
      [209, 411, [83, 85], [{"type": "zfe"}]],
      [213, 363, [84, 39], [{"type": "zfe"}]], // 85
      [211, 503, [82, 87], [{"type": "zfe"}, {"type": "low"}]],
      [274, 503, [86, 88], [{"type": "zfe"}]],
      [297, 446, [87, 89, 94], [{"type": "poi", "poiName": "Passage"}, {"type": "zfe"}]],
      [322, 416, [88, 35], [{"type": "zfe"}, {"type": "low"}]],
      [530, 469, [1, 69], null], // 90
      [486, 118, [8], [{"type": "highway"}]],
      [481, 224, [48, 53], [{"type": "bike"}]],
      [693, 406, [2, 64], [{"type": "bike"}]],
      [332, 524, [75, 88], [{"type": "bike"}, {"type": "zfe"}]],
    ];

    // create the tiles
    var index = 0;
    for (var tile in tiles) {
      addAction(AddTileAction(uuids[index], tile[0], tile[1]));
      if (tile[3] != null) {
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
    return players.length >= 2 && players.every((player) => player.ready);
  }
}
