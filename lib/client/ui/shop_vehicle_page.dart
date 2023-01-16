import 'package:card_swiper/card_swiper.dart';
import 'package:cubes/cubes.dart';
import 'package:flutter/material.dart';

import '../../model/board/board.dart';
import '../../model/board/party.dart';
import '../../model/repository/party_repository.dart';
import 'widget/my_widget.dart';

/// Page that allow user to buy and sell vehicles
/// All the vehicles are displayed with a Swiper
/// The user can swipe to see the other vehicles
/// The user can buy a vehicle by clicking on the "buy" button if it does not already own it
/// The user can sell a vehicle by clicking on the "sell" button if it already owns it
/// The page also shown the current points of the player and the price of the vehicle (use the PointCardWidget)
///
/// When the user have finished buying or selling vehicles,
/// the player can click on the "Ready" button to continue
class ShopVehiclePage extends CubeWidget<ShopVehiclePageCube> {
  const ShopVehiclePage({Key? key}) : super(key: key);

  @override
  Widget buildView(BuildContext context, ShopVehiclePageCube cube) {
    return cube.partyRepository.party.build<Party?>(
      (party) => Center(
        child: SingleChildScrollView(
          child: Card(
            child: Form(
              child: Column(
                children: [
                  Text('Buy and sell vehicles',
                      style: context.textTheme.headline5),

                  // list of vehicles
                  SizedBox(
                    // width: 300,
                    height: 300,
                    child: _swiper(context, cube),
                  ),

                  // button to buy or sell
                  cube.swiperIndex.build(
                    (swiperIndex) => ButtonBar(
                      children: [
                        if (cube.canBuy)
                          ElevatedButton(
                            onPressed: cube.onBuyClicked,
                            child: const Text('Buy'),
                          ),
                        if (cube.canSell)
                          ElevatedButton(
                            onPressed: cube.onSellClicked,
                            child: const Text('Sell'),
                          ),
                      ],
                    ),
                  ),

                  // current points
                  Text('Current points:', style: context.textTheme.bodyText1),
                  PointCardWidget(
                    points: cube.partyRepository.thisPlayer!.points,
                  ),

                  // button ready
                  ReadyButton(
                    style: ButtonStyle(
                        backgroundColor: cube.canUserReadyButton
                            ? null
                            : const MaterialStatePropertyAll(Colors.grey)),
                    disabled: !cube.canUserReadyButton,
                    onTapButDisabled: () => context.showSnackBar(
                      const SnackBar(
                          content: Text('You must have at least one vehicle')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _swiper(BuildContext context, ShopVehiclePageCube cube) {
    final party = cube.party;
    return Swiper(
      allowImplicitScrolling: true,
      indicatorLayout: PageIndicatorLayout.COLOR,
      control: const SwiperControl(),
      viewportFraction: 0.8,
      itemCount: party?.vehicles.length ?? 0,
      onIndexChanged: cube.swiperIndex.update,
      itemBuilder: (context, index) => VehicleCardWidget(
        vehicle: party!.vehicles[index],
      ),
    );
  }
}

class ShopVehiclePageCube extends Cube {
  final PartyRepository partyRepository;

  /// Observable swiper index
  final swiperIndex = 0.obs;

  ShopVehiclePageCube(this.partyRepository);

  /// return the party
  Party? get party => partyRepository.party.value;

  /// return the current displayed vehicle
  Vehicle? get currentVehicle => party?.vehicles[swiperIndex.value];

  /// The player can buy the displayed vehicle ?
  bool get canBuy =>
      partyRepository.thisPlayer?.ready == false &&
      partyRepository.thisPlayer?.vehicles
              .map((v) => v.type)
              .contains(currentVehicle?.type) ==
          false &&
      currentVehicle!.getBuyCost() <= partyRepository.thisPlayer!.points;

  /// The player can sell the displayed vehicle ?
  bool get canSell =>
      partyRepository.thisPlayer?.ready == false &&
      partyRepository.thisPlayer?.vehicles
              .map((v) => v.type)
              .contains(currentVehicle?.type) ==
          true;

  void onBuyClicked() {
    partyRepository.buyVehiclePlayer(currentVehicle!.type);
  }

  void onSellClicked() {
    partyRepository.sellVehiclePlayer(currentVehicle!.type);
  }

  /// State ready button
  bool get canUserReadyButton =>
      partyRepository.thisPlayer?.vehicles.isNotEmpty ?? false;
}
