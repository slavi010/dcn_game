import 'dart:math';

import 'package:cubes/cubes.dart';
import 'package:dcn_game/client/ui/widget/glass_custom.dart';
import 'package:dcn_game/client/ui/widget/my_widget.dart';
import 'package:dcn_game/model/repository/event_animation_repository.dart';
import 'package:dcn_game/model/repository/party_repository.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism_widgets/glassmorphism_widgets.dart';
import 'package:simple_animations/animation_builder/loop_animation_builder.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:zoom_widget/zoom_widget.dart';

import '../../model/board/board.dart';
import '../../model/board/mystery_card.dart';
import '../../model/board/party.dart';
import '../../model/event_animation.dart';

/// The board page
/// The screen is divided in 2 parts:
/// - the left is the map of the board (2/3 of the screen)
/// - the right is the list of the players, information and possible actions (1/3 of the screen)
class BoardPage extends CubeWidget<BoardPageCube> {
  final imageWidth = 982.0;
  final imageHeight = 721.0;

  const BoardPage({super.key});

  @override
  Widget buildView(BuildContext context, BoardPageCube cube) {
    return Cubes.get<PartyRepository>().party.build<Party?>(
          (party) => MysteryCardDialogWidget(
            child: UIBoardPage(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: imageWidth,
                    height: imageHeight,
                    child: Stack(
                      children: [
                        // the background board image
                        // center the image on the stack
                        Positioned.fill(
                          child: Image.asset(
                            cube.partyRepository.party.value?.board
                                    .pathToBoardImage ??
                                '',
                            fit: BoxFit.none,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),

                        // all the tiles
                        ...party?.board.tiles
                                .map((tile) => _tile(context, tile, cube)) ??
                            [],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
  }

  /// @deprecated since switching to glassmorphism ui
  /// (and honestly, it was not really good :p)
  List<Widget> _listWidget(BuildContext context, BoardPageCube cube) {
    return [
      const ListPlayerWidget(),

      const SizedBox(height: 20),

      // States (load, goalPOI, autonomy, maxload)
      ListTile(
        title: Text(
            'Target : ${cube.getCurrentPlayer()?.goalPOI?.poiName ?? 'N/A'}'),
      ),
      ListTile(
        title: Text(
            'Vehicle : ${cube.getCurrentPlayer()?.vehicle?.name ?? 'N/A'}'),
      ),
      ListTile(
        title: Text('Autonomy : ${cube.getCurrentPlayer()?.autonomy} / '
            '${cube.getCurrentPlayer()?.vehicle?.autonomy ?? 'N/A'}'),
      ),

      const SizedBox(height: 20),

      // Show the current points of the player
      PointCardWidget(points: cube.getCurrentPlayer()?.points),

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

    final bool isReachable =
        cube.partyRepository.party.value?.reachableTiles.contains(tile) ??
            false;
    final bool isPlayerHere = cube.partyRepository.party.value?.players
            .where((player) => player.currentTile == tile)
            .isNotEmpty ??
        false;
    final bool isPossibleMove = cube.getPossibleMoves().contains(tile);

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
                child: BackgroundBoardTileWidget(
                  size: sizeRect,
                  tile: tile,
                  isReachable: isReachable,
                  isPlayerHere: isPlayerHere,
                  isPossibleMove: isPossibleMove,
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
        ),
      ),
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
    return partyRepository.party.value?.players.isNotEmpty ?? false
        ? partyRepository.party.value?.players
            .firstWhere((player) => player.id == partyRepository.thisPlayerId)
        : null;
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

/// Background tile
/// Invisible and uninteractable if nothing
/// GlassContainer if reachable
/// Animation with waves if possible move

class BackgroundBoardTileWidget extends StatelessWidget {
  final BTile tile;
  final bool isReachable;
  final bool isPlayerHere;
  final bool isPossibleMove;
  final double size;

  const BackgroundBoardTileWidget({
    Key? key,
    required this.tile,
    required this.isReachable,
    required this.isPlayerHere,
    required this.isPossibleMove,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isReachable || isPossibleMove
        ? MirrorAnimationBuilder(
            tween: Tween<double>(begin: .3, end: 0.5),
            duration: const Duration(seconds: 1),
            builder: (context, valueAnimation, child) {
              return ShadowGlassContainer(
                blur: 1,
                radius: 1,
                borderRadius: BorderRadius.circular(12),
                width: size,
                height: size,
                borderGradient: (isPossibleMove)
                    ? LinearGradient(
                        colors: [
                          Colors.yellow.withOpacity(valueAnimation),
                          Colors.yellow.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.3),
                          Colors.green.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: 3,
              );
            },
          )
        : const SizedBox.shrink();
  }
}

/// dialog box that show the picked mystery card
/// when received event from server
class MysteryCardDialogWidget extends CubeWidget<MysteryCardDialogWidgetCube> {
  final Widget? child;

  const MysteryCardDialogWidget({Key? key, this.child}) : super(key: key);

  @override
  Widget buildView(BuildContext context, MysteryCardDialogWidgetCube cube) {
    // listen to the global event animation
    return cube.eventRepository.lastEventAnimation
        .build<EventAnimation?>((event) {
      if (event is MysteryCardPickedEventAnimation &&
          event.id != cube.lastMysteryCardEventAnimationId) {
        // update the observable value
        cube.lastMysteryCardEventAnimationId = event.id;
        cube.mysteryCardObs.update(event);
      }

      // listen to the mystery card event observable
      return cube.mysteryCardObs.build<MysteryCardPickedEventAnimation?>(
        (mysteryCardEvent) => Stack(
          children: [
            child ?? const SizedBox(),

            // show the dialog box
            mysteryCardEvent != null
                ? AlertDialog(
                    title: ShadowGlassContainer(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: CustomGlassText(
                              mysteryCardEvent.mysteryCard.name),
                        ),
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    content: ShadowGlassContainer(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: MysteryCardWidget(
                              mysteryCard: mysteryCardEvent.mysteryCard,
                              playerId: mysteryCardEvent.playerId),
                        ),
                      ),
                    ),
                    actions: <Widget>[
                      GlassButton(
                        child: const Text('Close'),
                        onPressed: () {
                          // close the dialog box
                          cube.mysteryCardObs.update(null);
                        },
                      ),
                    ],
                  )
                : const SizedBox(),
          ],
        ),
      );
    });
  }
}

class MysteryCardDialogWidgetCube extends Cube {
  final EventAnimationRepository eventRepository;

  final mysteryCardObs =
      ObservableValue<MysteryCardPickedEventAnimation?>(value: null);

  String lastMysteryCardEventAnimationId = '';

  MysteryCardDialogWidgetCube(this.eventRepository);
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${cube.getPlayerName(playerId)} has picked a card !'),
        const SizedBox(
          height: 20,
        ),
        Text(mysteryCard.description),
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

class UIBoardPage extends CubeWidget<UIBoardPageCube> {
  final Widget child;

  const UIBoardPage({Key? key, required this.child}) : super(key: key);

  @override
  Widget buildView(BuildContext context, UIBoardPageCube cube) {
    return Stack(children: [
      child,
      _uiLeft(context, cube),
    ]);
  }

  Widget _uiLeft(BuildContext context, UIBoardPageCube cube) {
    return Positioned(
      left: 0,
      top: 0,
      child: SizedBox(
        width: min(context.widthScreen, 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _currentPlayerPlayingText(context, cube),

            // the points of the this player
            _points(context, cube),

            // target
            _target(context, cube),
          ],
        ),
      ),
    );
  }

  // Show the current player playing text on the top left corner
  Widget _currentPlayerPlayingText(BuildContext context, UIBoardPageCube cube) {
    return ShadowGlassContainer(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        height: 60,
        width: min(context.widthScreen, 300),
        child: ListTile(
          title: CustomGlassText(
            cube.isThisPlayerTurn()
                ? 'Your turn'
                : 'Waiting for ${cube.getCurrentPlayerName()}',
            style: context.textTheme.headline6,
          ),
          subtitle: CustomGlassText(
            'Moves left : ${cube.getCurrentPlayerMovesLeft()}',
            style: context.textTheme.subtitle1,
          ),
        ),
      ),
    );
  }

  // points of this player
  Widget _points(BuildContext context, UIBoardPageCube cube) {
    return ShadowGlassContainer(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: min(context.widthScreen, 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // current player points
            ListTile(
              title: CustomGlassText(
                'Current points',
                style: context.textTheme.headline6,
              ),
              subtitle: cube.partyRepository.party
                  .build<Party?>((party) => PointCardWidget(
                        points: cube.partyRepository.thisPlayer?.points,
                      )),
            ),
            const SizedBox(width: 8),

            ListTile(
              title: Flexible(
                child: CustomGlassText(
                  'You will spend/earn this to use your vehicles for '
                  '${cube.isThisPlayerTurn() ? 'this' : 'the next'} turn',
                  style: context.textTheme.headline6,
                ),
              ),
              subtitle: PointCardWidget(
                points: cube.partyRepository.thisPlayer?.vehicle?.getUseCost(),
                negativeColor: Colors.black,
                positiveColor: Colors.lightGreen,
                reverseValues: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show this player target
  Widget _target(BuildContext context, UIBoardPageCube cube) {
    return ShadowGlassContainer(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: min(context.widthScreen, 300),
        child: ListTile(
          title: CustomGlassText(
            'Target',
            style: context.textTheme.headline6,
          ),
          subtitle: CustomGlassText(
            '-> ${cube.partyRepository.thisPlayer?.goalPOI?.poiName}' ?? '',
            style: context.textTheme.subtitle1,
          ),
        ),
      ),
    );
  }
}

class UIBoardPageCube extends Cube {
  final PartyRepository partyRepository;

  UIBoardPageCube(this.partyRepository);

  String getCurrentPlayerName() {
    return partyRepository.party.value?.currentPlayer?.name ?? '';
  }

  int getCurrentPlayerMovesLeft() {
    return partyRepository.party.value?.currentPlayer?.autonomy.ceil() ?? 0;
  }

  bool isThisPlayerTurn() {
    return partyRepository.party.value?.currentPlayer?.id ==
        partyRepository.thisPlayerId;
  }
}
