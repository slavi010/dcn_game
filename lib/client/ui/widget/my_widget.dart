import 'package:cubes/cubes.dart';
import 'package:dcn_game/client/ui/widget/glass_custom.dart';
import 'package:dcn_game/model/board/board.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism_widgets/glassmorphism_widgets.dart';

import '../../../model/board/party.dart';
import '../../../model/repository/party_repository.dart';

class ListPlayerWidget extends CubeWidget<ListPlayerWidgetCube> {
  const ListPlayerWidget({Key? key}) : super(key: key);

  @override
  Widget buildView(BuildContext context, ListPlayerWidgetCube cube) {
    return cube.partyRepository.party.build<Party?>(
      (party) => ListView.builder(
        shrinkWrap: true,
        itemCount: party?.players.length,
        itemBuilder: (context, index) => ListTile(
          leading: party?.players[index].ready == true
              ? const Icon(Icons.check)
              : const Icon(Icons.close),
          title: Text(
            (party?.players[index].name ?? "") +
                (party?.players[index].id ==
                        Cubes.get<PartyRepository>().thisPlayerId
                    ? ' (you)'
                    : '') +
                (party?.players[index].id == party?.currentPlayer?.id
                    ? ' [ playing, ${(party?.currentPlayer?.autonomy ?? -1) <= 0 ? 'ERROR' : 'can move ${party!.currentPlayer?.autonomy} tiles'} ]'
                    : ''),
          ),
        ),
      ),
    );
  }
}

class ListPlayerWidgetCube extends Cube {
  final PartyRepository partyRepository;

  ListPlayerWidgetCube(this.partyRepository);
}

/// Button to set ready/unready
/// "I'm ready" button is displayed if the player is not ready
/// "I'm no more ready" button is displayed if the player is ready
class ReadyButton extends CubeWidget<ReadyButtonCube> {
  /// Disable the interaction with the button
  final bool disabled;

  /// Function called if the button is disabled and the user try to use it
  final void Function()? onTapButDisabled;

  const ReadyButton({
    this.disabled = false,
    this.onTapButDisabled,
    Key? key,
  }) : super(key: key);

  @override
  Widget buildView(BuildContext context, ReadyButtonCube cube) {
    return cube.partyRepository.party.build<Party?>(
      (party) => CustomGlassButton(
        borderGradient: disabled
            ? const LinearGradient(
                colors: [
                  Colors.grey,
                  Colors.grey,
                ],
              )
            : null,
        onPressed: () => !disabled
            ? cube.onReadyClicked()
            : onTapButDisabled != null
                ? onTapButDisabled!()
                : null,
        child: Text(cube.partyRepository.thisPlayer?.ready ?? false
            ? 'I\'m no more ready'
            : 'I\'m ready'),
      ),
    );
  }
}

/// The cube for the button to set ready/unready
class ReadyButtonCube extends Cube {
  final PartyRepository partyRepository;

  ReadyButtonCube(this.partyRepository);

  void onReadyClicked() {
    runDebounce('onReadyClicked', () {
      if (partyRepository.thisPlayer == null) {
        return;
      }
      partyRepository.updatePlayerReadiness(!partyRepository.thisPlayer!.ready);
    });
  }
}

/// Widget that show the points (class PointCard) in a little card.
/// A little icon is shown for each type of points.
///
/// - Money
/// - Energy
/// - Environment
/// - Performance
class PointCardWidget extends StatelessWidget {
  final PointCard? points;

  /// The direction of the list of points
  final Axis direction;

  final Color? positiveColor;
  final Color? negativeColor;

  /// Reverse positive and negative values
  final bool reverseValues;

  const PointCardWidget(
      {Key? key,
      required this.points,
      this.direction = Axis.horizontal,
      this.positiveColor,
      this.negativeColor,
      this.reverseValues = false})
      : super(key: key);

  Widget buildItem(String label, IconData icon, int value) {
    final int modifiedValue = reverseValues ? -value : value;

    return Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          Text(
            modifiedValue.toString(),
            style: TextStyle(
                color: modifiedValue > 0 ? positiveColor : negativeColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (points == null) {
      return const GlassText(
        'ERROR: points is null',
      );
    }

    return direction == Axis.horizontal
        ? Wrap(
            children: [
              buildItem('Money', Icons.attach_money, points!.money),
              buildItem('Energy', Icons.flash_on, points!.energy),
              buildItem('Environment', Icons.nature, points!.environment),
              buildItem('Performance', Icons.trending_up, points!.performance),
            ],
          )
        : Column(
            children: [
              buildItem('Money', Icons.attach_money, points!.money),
              buildItem('Energy', Icons.flash_on, points!.energy),
              buildItem('Environment', Icons.nature, points!.environment),
              buildItem('Performance', Icons.trending_up, points!.performance),
            ],
          );
  }
}

/// Vehicle card widget
/// show:
/// - Price to buy & to use
/// - show autonomy
/// - if can:
///  - pass express
///  - pass on bike road
///  - pass in ZFE
///  - is affected by jam

class VehicleCardWidget extends CubeWidget<VehicleCardWidgetCube> {
  final Vehicle vehicle;

  const VehicleCardWidget({Key? key, required this.vehicle}) : super(key: key);

  @override
  Widget buildView(BuildContext context, VehicleCardWidgetCube cube) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListTile(
          title: Text(vehicle.name),
          // show the price to buy and to use
          tileColor: Colors.yellow.shade50,
          subtitle: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vehicle.name),
              Text('Autonomy: ${vehicle.autonomy}'),
              Text('Can pass express: ${vehicle.canPassExpressway()}'),
              Text('Can pass on bike road: ${vehicle.canPassBikeRoad()}'),
              Text('Can pass in ZFE: ${vehicle.canPassZFE()}'),
              Text('Is affected by jam: ${vehicle.isAffectedByJam()}'),
              const SizedBox(height: 20),
              Text('Price to buy:', style: context.textTheme.bodyText1),
              const SizedBox(height: 10),
              PointCardWidget(points: vehicle.getBuyCost()),
              const SizedBox(height: 10),
              Text('Price to use:', style: context.textTheme.bodyText1),
              PointCardWidget(points: vehicle.getUseCost()),
            ],
          ),
        ),
      ),
    );
  }
}

class VehicleCardWidgetCube extends Cube {
  final PartyRepository partyRepository;

  VehicleCardWidgetCube(this.partyRepository);
}

/// Widget that show pellets that represent the player's position on a tile
/// Get a tile and list of players
/// If 0 player, show nothing
/// If 1 player, show a centered pellet
/// If 2 players, show 2 pellets on the left and right
/// If 3 players, show 3 pellets on the bottom left, top center and bottom right
/// If 4 players, show 4 pellets on the bottom left, top left, top right and bottom right
class PlayerPositionWidget extends StatelessWidget {
  final BTile tile;
  final List<Player> players;
  final double size;

  static const colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
  ];

  const PlayerPositionWidget(
      {Key? key, required this.tile, required this.players, required this.size})
      : super(key: key);

  /// 0 left/top, 1 right/bottom
  CoordDouble _getPlayerPelletPosition(int index) {
    switch (players.length) {
      case 1:
        return CoordDouble(0.5, 0.5);
      case 2:
        return CoordDouble(index == 0 ? 0.25 : 0.75, 0.5);
      case 3:
        return CoordDouble(
            index == 0
                ? 0.25
                : index == 1
                    ? 0.5
                    : 0.75,
            index == 1 ? 0.25 : 0.75);
      case 4:
        return CoordDouble(
            index == 0
                ? 0.25
                : index == 1
                    ? 0.75
                    : index == 2
                        ? 0.25
                        : 0.75,
            index == 0 || index == 1 ? 0.75 : 0.25);
      default:
        return CoordDouble(0.5, 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double pelletSizeFactor = 0.3;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // show the players
          for (int i = 0; i < players.length; i++)
            Positioned(
              left:
                  _getPlayerPelletPosition(i).x * size * (1 - pelletSizeFactor),
              top:
                  _getPlayerPelletPosition(i).y * size * (1 - pelletSizeFactor),
              child: Hero(
                tag: 'player-${players[i].id}',
                child: Tooltip(
                  message: '${players[i].name} - ${players[i].vehicle?.name}',
                  child: Container(
                    width: size * pelletSizeFactor,
                    height: size * pelletSizeFactor,
                    decoration: BoxDecoration(
                      // get the player color
                      color: colors[players[i]
                          .indexPlayer(Cubes.get<PartyRepository>().party.value!)],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
