import 'package:cubes/cubes.dart';
import 'package:dcn_game/model/repository/party_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';

class JoinPartyPage extends CubeWidget<JoinPartyPageCube> {
  @override
  Widget buildView(BuildContext context, JoinPartyPageCube cube) {
    return Center(
      child: SingleChildScrollView(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              child: Column(
                children: [
                  Text('Join the party !', style: context.textTheme.headline5),

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
                  ElevatedButton(
                    onPressed: cube.validateForm,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 28),
                    ),
                    child: const Text('Validate'),
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
