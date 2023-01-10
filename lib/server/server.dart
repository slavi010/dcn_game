import 'package:alfred/alfred.dart';
import 'package:dcn_game/server/api.dart';
import '../model/board/server_states.dart';

// server side
Future<void> main() async {
  var app = Alfred();



  var etat = ServerEtat();
  // server side
  setUpServerRoutes(app, etat);

  app.listen(80);
}