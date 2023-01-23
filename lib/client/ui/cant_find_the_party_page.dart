
import 'package:cubes/cubes.dart';
import 'package:dcn_game/client/ui/widget/glass_custom.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism_widgets/glassmorphism_widgets.dart';

import '../../model/repository/party_repository.dart';

class CantFindThePartyPage extends CubeWidget<CantFindThePartyPageCube> {
  const CantFindThePartyPage({super.key});

  @override
  Widget buildView(BuildContext context, CantFindThePartyPageCube cube) {
    return Center(
      child: ShadowGlassContainer(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            child: Column(
              children: [
                CustomGlassText('Sorry but we are not able to join the party...', style: context.textTheme.headline5),
                const SizedBox(height: 40),
                CustomGlassText('Please refresh the page and try again.', style: context.textTheme.headline5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CantFindThePartyPageCube extends Cube {
  void refresh() {
    Cubes.get<PartyRepository>().updateParty();
  }
}