import 'package:cubes/cubes.dart';
import 'package:dcn_game/model/repository/event_animation_repository.dart';

import 'package:dcn_game/model/repository/party_repository.dart';
import 'package:dcn_game/client/ui/widget/my_widget.dart';
import 'package:flutter/material.dart';

import '../../model/board/board.dart';
import '../../model/board/mystery_card.dart';
import '../../model/board/party.dart';
import '../../model/event_animation.dart';

/// The board page
/// The screen is divided in 2 parts:
/// - the left is the map of the board (2/3 of the screen)
/// - the right is the list of the players, information and possible actions (1/3 of the screen)
class BoardPage extends CubeWidget<BoardPageCube> {
  const BoardPage({super.key});

  @override
  Widget buildView(BuildContext context, BoardPageCube cube) {
    return Cubes.get<PartyRepository>().party.build<Party?>(
          (party) => Scaffold(
            appBar: AppBar(
              title: const Text('Board'),
            ),
            body: MysteryCardDialogWidget(
              child: Row(
                children: [
                  // map
                  Expanded(
                      flex: 2,
                      child: Card(
                        child: Stack(
                          children: [
                            // the background board image
                            Image.asset(
                              'image/board/board_A.jpg',
                              fit: BoxFit.none,
                              alignment: Alignment.topLeft,
                              width: double.infinity,
                              height: double.infinity,
                            ),

                            ...party?.board.tiles.map(
                                    (tile) => _tile(context, tile, cube)) ??
                                [],
                          ],
                        ),
                      )),

                  // players list
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Container(
                        color: Colors.red.withAlpha(50),
                        child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child:
                                Column(children: _listWidget(context, cube))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }

  List<Widget> _listWidget(BuildContext context, BoardPageCube cube) {
    return [
      const ListPlayerWidget(),

      const SizedBox(height: 20),

      // States (load, goalPOI, autonomy, maxload)
      ListTile(
        title: Text(
            'Target :${cube.getCurrentPlayer()?.goalPOI?.poiName ?? 'N/A'}'),
      ),
      ListTile(
        title:
            Text('Vehicle :${cube.getCurrentPlayer()?.vehicle?.name ?? 'N/A'}'),
      ),
      ListTile(
        title: Text('Autonomy :${cube.getCurrentPlayer()?.autonomy} / '
            '${cube.getCurrentPlayer()?.vehicle?.autonomy ?? 'N/A'}'),
      ),
      ListTile(
        title: Text('Load left :${cube.getCurrentPlayer()?.load}}'),
      ),
      ListTile(
        title: Text(
            'Max load :${cube.getCurrentPlayer()?.vehicle?.maxLoad ?? 'N/A'}'),
      ),

      const SizedBox(height: 20),

      // button to show a dialog with the list of owned vehicles
      ElevatedButton(
        onPressed: () => cube.showVehiclesDialog(context),
        child: const Text('Show vehicles'),
      ),
    ];
  }

  Widget _tile(BuildContext context, BTile tile, BoardPageCube cube) {
    const double size = 50;
    const double sizeRect = 30;

    return Positioned(
      left: tile.getCoord().x.toDouble() - 25,
      top: tile.getCoord().y.toDouble() - 25,
      child: InkWell(
          onTap: () => cube.onTileClicked(tile),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                // center
                Positioned(
                  left: size / 2 - sizeRect / 2,
                  top: size / 2 - sizeRect / 2,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black26,
                          width: 1,
                        ),
                        color: cube.getPossibleMoves().contains(tile)
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                      ),
                      child: Text(
                        // "${cube.partyRepository.party.value!.players.where((player) => player.currentTile?.id == tile.id).map((player) => player.name).join('\n')}"
                        "\n${tile.getPOIs().map((poi) => poi.poiName).join('\n')}",
                        maxLines: 5,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: PlayerPositionWidget(
                    tile: tile,
                    players: cube.partyRepository.party.value!.players
                        .where((player) => player.currentTile?.id == tile.id)
                        .toList(),
                    size: size,
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

class BoardPageCube extends Cube {
  void onTileClicked(BTile tile) {
    if (getPossibleMoves().contains(tile)) {
      partyRepository.chooseBranch(tile.id);
    }
  }

  PartyRepository get partyRepository => Cubes.get<PartyRepository>();

  Player? getCurrentPlayer() {
    return partyRepository.party.value?.players
        .firstWhere((player) => player.id == partyRepository.thisPlayerId);
  }

  bool isMyTurn() {
    return partyRepository.party.value?.currentPlayer?.id ==
        partyRepository.thisPlayerId;
  }

  List<BTile> getPossibleMoves() {
    Party party = partyRepository.party.value!;
    if (partyRepository.thisPlayerId != party.currentPlayer?.id) {
      return [];
    }
    return partyRepository.thisPlayer!.currentTile!
        .possibleNexts(partyRepository.thisPlayer!);
  }

  showVehiclesDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('My vehicles'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: context.widthScreen < 500
                    ? context.widthScreen
                    : context.widthScreen / 2,
                child: ListView(
                  shrinkWrap: true,
                  children: Cubes.get<PartyRepository>()
                      .party
                      .value!
                      .players
                      .firstWhere(
                          (player) => player.id == partyRepository.thisPlayerId)
                      .vehicles
                      .map((vehicle) => VehicleCardWidget(vehicle: vehicle))
                      .toList(),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
}

/// dialog box that show the picked mystery card
/// when received event from server
class MysteryCardDialogWidget extends CubeWidget<MysteryCardDialogWidgetCube> {
  final Widget? child;

  const MysteryCardDialogWidget({Key? key, this.child}) : super(key: key);

  @override
  Widget buildView(BuildContext context, MysteryCardDialogWidgetCube cube) {
    return StreamBuilder<MysteryCardPickedEventAnimation?>(
        stream: cube.mysteryCardStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return AlertDialog(
              title: const Text('Mystery card'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: context.widthScreen < 500
                      ? context.widthScreen
                      : context.widthScreen / 2,
                  child: MysteryCardWidget(
                      mysteryCard: snapshot.data!.mysteryCard,
                      playerId: snapshot.data!.playerId),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          } else {
            return const SizedBox.shrink();
          }
        });
  }
}

class MysteryCardDialogWidgetCube extends Cube {
  final EventAnimationRepository eventRepository;

  MysteryCardDialogWidgetCube(this.eventRepository);

  Stream<MysteryCardPickedEventAnimation?> get mysteryCardStream =>
      eventRepository.subStream<MysteryCardPickedEventAnimation>();
}

class MysteryCardWidget extends CubeWidget<MysteryCardWidgetCube> {
  final MysteryCard mysteryCard;
  final String playerId;

  const MysteryCardWidget(
      {Key? key, required this.mysteryCard, required this.playerId})
      : super(key: key);

  @override
  Widget buildView(BuildContext context, MysteryCardWidgetCube cube) {
    return Column(
      children: [
        ListTile(
          title: Text('Player : ${cube.getPlayerName(playerId)}'),
        ),
        ListTile(
          title: Text('Mystery card : ${mysteryCard.name}'),
        ),
        ListTile(
          title: Text('Description : ${mysteryCard.description}'),
        ),
      ],
    );
  }
}

class MysteryCardWidgetCube extends Cube {
  final PartyRepository partyRepository;

  MysteryCardWidgetCube(this.partyRepository);

  String getPlayerName(String playerId) {
    return partyRepository.party.value!.players
        .firstWhere((player) => player.id == playerId)
        .name;
  }
}
