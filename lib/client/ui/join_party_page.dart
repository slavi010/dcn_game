import 'package:cubes/cubes.dart';
import 'package:dcn_game/model/repository/party_repository.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism_widgets/glassmorphism_widgets.dart';

import 'widget/glass_custom.dart';

class JoinPartyPage extends CubeWidget<JoinPartyPageCube> {
  @override
  Widget buildView(BuildContext context, JoinPartyPageCube cube) {
    return Center(
      child: SingleChildScrollView(
        child: ShadowGlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              child: Column(
                children: [
                  CustomGlassText('Join the party !', style: context.textTheme.headline5),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: 200,
                    child: CTextFormField(
                      observable: cube.nameTxtControl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // validate button
                  CustomGlassButton (
                    onPressed: cube.validateForm,
                    // style: OutlinedButton.styleFrom(
                    //   padding: const EdgeInsets.symmetric(
                    //       horizontal: 40, vertical: 28),
                    // ),
                    child: const CustomGlassText('Validate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class JoinPartyPageCube extends Cube {
  final nameTxtControl = CTextFormFieldControl(text: '').obs;

  void validateForm() {
    runDebounce(
      'join-party', // identify
      () => {
        if (nameTxtControl.value.text.isNotEmpty)
          Cubes.get<PartyRepository>().joinParty(nameTxtControl.value.text)
      },
      duration: const Duration(seconds: 1),
    );
  }
}
