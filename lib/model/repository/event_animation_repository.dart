import 'dart:async';
// ignore: implementation_imports
import 'package:cubes/cubes.dart';

import '../event_animation.dart';

/// Handle the event animation send by the server
/// And update the corresponding ui
class EventAnimationRepository {

  final lastEventAnimation = ObservableValue<EventAnimation?>(value: null);

  EventAnimationRepository();

  /// Add an event animation to the stream
  void addEventAnimation(EventAnimation eventAnimation) {
    lastEventAnimation.update(eventAnimation);
  }
}
