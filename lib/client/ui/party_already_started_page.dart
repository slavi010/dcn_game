

import 'package:cubes/cubes.dart';
import 'package:flutter/material.dart';

import '../party_repository.dart';

class PartyAlreadyStartedPage extends CubeWidget<PartyAlreadyStartedPageCube> {
  const PartyAlreadyStartedPage({super.key});

  @override
  Widget buildView(BuildContext context, PartyAlreadyStartedPageCube cube) {
    return Center(
      child: SingleChildScrollView(
        child: Form(
          child: Column(
            children: [
              Text('Party already started, sorry !', style: context.textTheme.headline5),

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

class PartyAlreadyStartedPageCube extends Cube {
  void refresh() {
    Cubes.get<PartyRepository>().updateParty();
  }
}