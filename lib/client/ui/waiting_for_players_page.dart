import 'package:cubes/cubes.dart';
import 'package:dcn_game/client/ui/widget/glass_custom.dart';
import 'package:dcn_game/client/ui/widget/my_widget.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism_widgets/glassmorphism_widgets.dart';

import '../../model/repository/party_repository.dart';

class WaitingForPlayersPage extends CubeWidget<WaitingForPlayersPageCube> {
  const WaitingForPlayersPage({super.key});

  @override
  Widget buildView(BuildContext context, WaitingForPlayersPageCube cube) {
    return Center(
      child: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: ShadowGlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                child: Column(
                  children: [
                    CustomGlassText(
                        'Waiting for other players.',
                        style: context.textTheme.headline5),

                    // list of players
                    const ListPlayerWidget(),

                    // button I am ready
                    const ReadyButton()
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WaitingForPlayersPageCube extends Cube {
  final PartyRepository partyRepository;

  WaitingForPlayersPageCube(this.partyRepository);
}
