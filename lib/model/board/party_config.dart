//
//
// // Example of a party config
// // {
// //   "party": {
// //     "nb_player_min": 1,
// //     "nb_player_max": 4,
// //     "board": "default"
// //   },
// //   "rounds": [
// //     {
// //       "init_points": {
// //         "money": 10,
// //         "energy": 10,
// //         "environment": 10,
// //         "performance": 10
// //       },
// //       "init_position": "warehouse",
// //       "init_vehicle": ["b"],
// //       "start_shop_available": false,
// //       "aims": {
// //         "type": "defined",
// //         "targets": ["garage", "warehouse"]
// //       },
// //       "calculating_points": ["money"]
// //     },
// //     {
// //       "init_points": "SAB",
// //       "init_position": "warehouse",
// //       "init_vehicle": "SAB",
// //       "start_shop_available": true,
// //       "aims": {
// //         "type": "defined",
// //         "targets": ["garage", "warehouse"]
// //       },
// //       "calculating_points": ["money", "energy"]
// //     }
// //   ]
// // }
// //
// // SAB = Same As Before
//
// // Implementation of the party config
//
// import 'board.dart';
//
// class PartyConfig {
//   /// Min number of player
//   final int nbPlayerMin;
//
//   /// Max number of player
//   final int nbPlayerMax;
//
//   /// The board config
//   final BoardConfig board;
//
//   /// The rounds config
//   final List<RoundConfig> rounds;
//
//   /// The party config
//   PartyConfig({
//     required this.nbPlayerMin,
//     required this.nbPlayerMax,
//     required this.board,
//     required this.rounds,
//   });
//
//   /// Create a party config from a json
//   ///
//   /// Raise error if the json is not valid
//   factory PartyConfig.fromJson(Map<String, dynamic> json) {
//     final party = json['party'];
//     final rounds = json['rounds'];
//
//     if (party == null) {
//       throw Exception('Party config must have a party section');
//     }
//
//     if (rounds == null) {
//       throw Exception('Party config must have a rounds section');
//     }
//
//     if (party['nb_player_min'] == null) {
//       throw Exception('Party config must have a nb_player_min section');
//     }
//
//     if (party['nb_player_max'] == null) {
//       throw Exception('Party config must have a nb_player_max section');
//     }
//
//     if (party['board'] == null) {
//       throw Exception('Party config must have a board section');
//     }
//
//     // TODO : check if the first round is a valid first round
//
//     return PartyConfig(
//       nbPlayerMin: party['nb_player_min'],
//       nbPlayerMax: party['nb_player_max'],
//       board: BoardConfig.fromJson(party['board']),
//       rounds: List<RoundConfig>.from(rounds.map((r) => RoundConfig.fromJson(r))),
//     );
//   }
// }
//
// /// The board config
// /// Can be a predefined board if a string is given (default, ...)
// /// Or a custom board if a List<dynamic> is given
// class BoardConfig {
//   /// The board config
//   final dynamic board;
//
//   /// The board config
//   BoardConfig(this.board);
//
//   /// Create a board config from a json
//   ///
//   /// Raise error if the json is not valid
//   ///
//   /// Valid json are :
//   /// - a string like "default"
//   /// - a list of dynamic
//   factory BoardConfig.fromJson(dynamic json) {
//     if (json is String) {
//       switch (json) {
//         case 'default':
//           return BoardConfig(Board.defaultBoard);
//         default:
//           throw Exception('Board config $json is not valid');
//       }
//       return BoardConfig(json);
//     } else if (json is List<dynamic>) {
//       // TODO : check if the board is valid
//       return BoardConfig(json);
//     } else {
//       throw Exception('Board config must be a string or a list');
//     }
//   }
// }
//
// /// The round config
// class RoundConfig {
//   /// The initial points
//   final dynamic initPoints;
//
//   /// The initial position
//   final String initPosition;
//
//   /// The initial vehicle
//   final dynamic initVehicle;
//
//   /// If the start shop is available
//   final bool startShopAvailable;
//
//   /// The aims
//   final Aims aims;
//
//   /// The calculating points
//   final List<String> calculatingPoints;
//
//   /// The round config
//   RoundConfig({
//     required this.initPoints,
//     required this.initPosition,
//     required this.initVehicle,
//     required this.startShopAvailable,
//     required this.aims,
//     required this.calculatingPoints,
//   });
//
//   /// Create a round config from a json
//   ///
//   /// Raise error if the json is not valid
//   factory RoundConfig.fromJson(Map<String, dynamic> json) {
//     if (json['init_points'] == null) {
//       throw Exception('Round config must have a init_points section');
//     }
//
//     if (json['init_position'] == null) {
//       throw Exception('Round config must have a init_position section');
//     }
//
//     if (json['init_vehicle'] == null) {
//       throw Exception('Round config must have a init_vehicle section');
//     }
//
//     if (json['start_shop_available'] == null) {
//       throw Exception('Round config must have a start_shop_available section');
//     }
//
//     if (json['aims'] == null) {
//       throw Exception('Round config must have a aims section');
//     }
//
//     if (json['calculating_points'] == null) {
//       throw Exception('Round config must have a calculating_points section');
//     }
//
//     return RoundConfig(
//       initPoints: json['init_points'],
//       initPosition: json['init_position'],
//       initVehicle: json['init_vehicle'],
//       startShopAvailable: json['start_shop_available'],
//       aims: Aims.fromJson(json['aims']),
//       calculatingPoints: List<String>.from(json['calculating_points']),
//     );
//   }
// }