import 'dart:math';

import 'package:alfred/alfred.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:uuid/uuid.dart';

import '../model/board/party_action.dart';
import '../model/board/server_states.dart';

part 'api.g.dart';

/// Client side API (callings to the server side)
// @RestApi(baseUrl: "https://slavi.dev/dcn_web/api/")
@RestApi(baseUrl: "http://localhost/")
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  /// return the id of the current party
  /// if the party does not exist, create it
  @GET("/party/id")
  Future<IdResponse> getPartyId();

  /// get all the history of the party
  @GET("/party/{id}/history")
  Future<List<PartyAction>> getPartyHistory(@Path("id") String id);

  /// get all the new actions since the last action (included)
  @GET("/party/{id}/history/{lastActionId}")
  Future<List<PartyAction>> getPartyHistorySince(
      @Path("id") String id, @Path("lastActionId") int lastActionId);

  /// new user
  /// return the id of the new user
  @POST("/party/{id}/player/new/{name}")
  Future<IdResponse> addPlayer(
      @Path("id") String idParty, @Path("name") String name);

  /// choose a branch
  @POST("/party/{id}/player/{idPlayer}/branch/{idTile}")
  Future<void> chooseBranch(@Path("id") String idParty,
      @Path("idPlayer") String idPlayer, @Path("idTile") String idTile);

  // // update player readiness
  //   app.post("/party/:id:uuid/player/:idPlayer:uuid/readiness/:isReady:bool",
  //       (req, res) async {
  //     final isReady = req.params["isReady"];
  //     etat.state.playerReady(req.params['idPlayer'], isReady);
  //     res.send(null);
  //   });
  /// update the readiness of the player
  ///
  /// isReady : 0=false else=true
  @POST("/party/{id}/player/{idPlayer}/readiness/{isReady}")
  Future<void> updatePlayerReadiness(@Path("id") String idParty,
      @Path("idPlayer") String idPlayer, @Path("isReady") int isReady);

  /// Buy a vehicle for the player
  @POST("/party/{id}/player/{idPlayer}/vehicle/buy/{type}")
  Future<void> buyVehiclePlayer(@Path("id") String idParty,
      @Path("idPlayer") String idPlayer, @Path("type") String type);

  /// Sell a vehicle for the player
  @POST("/party/{id}/player/{idPlayer}/vehicle/sell/{type}")
  Future<void> sellVehiclePlayer(@Path("id") String idParty,
      @Path("idPlayer") String idPlayer, @Path("type") String type);

  /// create a new game
  @POST("/party/new")
  Future<IdResponse> newGame();
}

class IdResponse {
  final String id;

  IdResponse(this.id);

  factory IdResponse.fromJson(Map<String, dynamic> json) {
    return IdResponse(json['id']);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
      };
}

/// Server side https API handling the requests above
void setUpServerRoutes(Alfred app, ServerEtat etat) {
  app.all("*", cors());

  // check if the party exist
  app.all("/party/:id:uuid/*", (req, res) {
    if (req.params["id"] != etat.party.id) {
      throw AlfredException(404, {'message': 'Party not found'});
    }
  });

  // check if the player id exist in the party
  app.all("/party/:id:uuid/player/:idPlayer:uuid/*", (req, res) {
    if (!etat.party.players.map((p) => p.id).contains(req.params["idPlayer"])) {
      throw AlfredException(404, {'message': 'Player not found'});
    }
  });

  // get the current party id
  app.get("/party/id", (req, res) async {
    res.json(IdResponse(etat.party.id));
  });

  // get history
  app.get("/party/:id:uuid/history", (req, res) async {
    res.json(etat.party.history);
  });

  // get history since
  app.get("/party/:id:uuid/history/:lastActionId:int", (req, res) async {
    final lastActionId = req.params["lastActionId"];
    final history = etat.party.history.sublist(
        min(lastActionId, etat.party.history.length),
        etat.party.history.length);
    res.json(history);
  });

  // new player
  app.post("/party/:id:uuid/player/new/:name", (req, res) async {
    try {
      var name = req.params["name"];
      final id = const Uuid().v4();
      etat.newPlayer(id, name);
      res.json(IdResponse(id));
    } catch (e) {
      throw AlfredException(400, {'message': 'Bad request'});
    }
  });

  // choose a branch
  app.post("/party/:id:uuid/player/:idPlayer:uuid/branch/:idTile:uuid",
      (req, res) async {
    final idTile = req.params["idTile"];
    etat.state.playerChooseBranch(idTile);
    res.send(null);
  });

  // update player readiness
  app.post("/party/:id:uuid/player/:idPlayer:uuid/readiness/:isReady:int",
      (req, res) async {
    final isReady = req.params["isReady"] != 0;
    etat.state.playerReady(req.params['idPlayer'], isReady);
    res.send(null);
  });

  // buy vehicle player
  app.post("/party/:id:uuid/player/:idPlayer:uuid/vehicle/buy/:type",
      (req, res) async {
    // check if type is a valid non empty string
    if (req.params["type"] == null ||
        req.params["type"] is! String ||
        req.params["type"].isEmpty) {
      throw AlfredException(400, {'message': 'Bad request'});

    }

    final type = req.params ["type"];
    etat.state.buyVehicle(req.params['idPlayer'], type);
    res.send(null);
  });

  // sell vehicle player
  app.post("/party/:id:uuid/player/:idPlayer:uuid/vehicle/sell/:type",
      (req, res) async {
    // check if type is a valid non empty string
    if (req.params["type"] == null ||
        req.params["type"] is! String ||
        req.params["type"].isEmpty) {
      throw AlfredException(400, {'message': 'Bad request'});
    }

    final type = req.params["type"];
    etat.state.sellVehicle(req.params['idPlayer'], type);
    res.send(null);
  });

  app.post("/party/new", (req, res) async {
    etat.state.newGame();
    res.json(IdResponse(etat.party.id));
  });
}
