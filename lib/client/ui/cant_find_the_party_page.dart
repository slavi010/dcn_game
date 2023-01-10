
import 'package:cubes/cubes.dart';
import 'package:flutter/material.dart';

import '../party_repository.dart';

class CantFindThePartyPage extends CubeWidget<CantFindThePartyPageCube> {
  const CantFindThePartyPage({super.key});

  @override
  Widget buildView(BuildContext context, CantFindThePartyPageCube cube) {
    return Center(
      child: SingleChildScrollView(
        child: Form(
          child: Column(
            children: [
              Text('Sorry but we are not able to join the party...', style: context.textTheme.headline5),

              // refresh button
              OutlinedButton(
                onPressed: cube.refresh,
                child: const Text('Refresh'),
              ),
            ],
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