
import 'package:cubes/cubes.dart';
import 'package:flutter/material.dart';

import '../party_repository.dart';

class AdminPage extends CubeWidget<AdminPageCube> {
  const AdminPage({super.key});

  @override
  Widget buildView(BuildContext context, AdminPageCube cube) {
    return Center(
      child: SingleChildScrollView(
        child: Form(
          child: Column(
            children: [
              Text('Admin page', style: context.textTheme.headline5),
              const SizedBox(height: 20),

              // restart game button
              OutlinedButton(
                onPressed: cube.restartGame,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
                ),
                child: const Text('Restart game'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminPageCube extends Cube {
  void restartGame() {
    Cubes.get<PartyRepository>().restartGame();
  }
}