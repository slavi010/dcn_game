import 'package:cubes/cubes.dart';
import 'package:dcn_game/client/ui/board_page.dart';
import 'package:dcn_game/client/ui/cant_find_the_party_page.dart';
import 'package:dcn_game/client/ui/join_party_page.dart';
import 'package:dcn_game/client/ui/party_already_started_page.dart';
import 'package:dcn_game/client/ui/shop_vehicle_page.dart';
import 'package:dcn_game/client/ui/waiting_for_players_page.dart';
import 'package:dcn_game/client/ui/widget/my_widget.dart';
import 'package:dcn_game/model/board/server_states.dart';
import 'package:dcn_game/model/repository/event_animation_repository.dart';
import 'package:dcn_game/model/repository/party_repository.dart';
import 'package:dcn_game/server/api.dart';
// ignore: depend_on_referenced_packages
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'client/ui/admin_page.dart';
import 'model/board/party.dart';

void main() async {
  // load hive box
  Hive.init('hive');
  await Hive.openBox(PartyRepository.hiveBoxName);

  // register repositories
  final dio = Dio();
  // dio.interceptors.add(LogInterceptor(responseBody: true, responseHeader: true, requestBody: true, requestHeader: true));
  // dio.options.contentType = Headers.jsonContentType;
  Cubes.registerSingleton<PartyRepository>(PartyRepository(RestClient(dio)));
  Cubes.registerSingleton<EventAnimationRepository>(
      EventAnimationRepository());

  // register cubes
  Cubes.registerFactory<JoinPartyPageCube>((i) => JoinPartyPageCube());
  Cubes.registerFactory<WaitingForPlayersPageCube>(
      (i) => WaitingForPlayersPageCube(i.get()));
  Cubes.registerFactory<ReadyButtonCube>((i) => ReadyButtonCube(i.get()));
  Cubes.registerFactory<ListPlayerWidgetCube>(
      (i) => ListPlayerWidgetCube(i.get()));
  Cubes.registerFactory<PartyAlreadyStartedPageCube>(
      (i) => PartyAlreadyStartedPageCube());
  Cubes.registerFactory<CantFindThePartyPageCube>(
      (i) => CantFindThePartyPageCube());
  Cubes.registerFactory<AdminPageCube>((i) => AdminPageCube());
  Cubes.registerFactory<BoardPageCube>((i) => BoardPageCube());
  Cubes.registerFactory<ShopVehiclePageCube>(
      (i) => ShopVehiclePageCube(i.get()));
  Cubes.registerFactory<VehicleCardWidgetCube>(
      (i) => VehicleCardWidgetCube(i.get()));
  Cubes.registerFactory<MysteryCardDialogWidgetCube>(
      (i) => MysteryCardDialogWidgetCube(i.get()));
  Cubes.registerFactory<MysteryCardWidgetCube>(
      (i) => MysteryCardWidgetCube(i.get()));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(body: MyHomePage()),
      // path
      routes: {
        '/admin': (context) => const AdminPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key}) {
    Cubes.get<PartyRepository>().updateParty();
  }

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Cubes.get<PartyRepository>().party.build<Party?>((party) {
      final currentPlayerId = Cubes.get<PartyRepository>().thisPlayerId;
      if (party == null) {
        return const CantFindThePartyPage();
      } else if (currentPlayerId == null && party.started) {
        return const PartyAlreadyStartedPage();
      } else if (currentPlayerId == null &&
          party.serverState is WaitingForPlayerServerState) {
        return JoinPartyPage();
      } else if (party.serverState is WaitingForPlayerServerState) {
        return const WaitingForPlayersPage();
      } else if (party.serverState is ChooseVehicleServerState) {
        return const ShopVehiclePage();
      } else {
        return const BoardPage();
      }
      // TODO stats page
      // TODO game over page
    });
  }
}
