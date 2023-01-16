import 'dart:async';

import '../event_animation.dart';

/// Handle the event animation send by the server
/// And update the corresponding ui
class EventAnimationRepository {

  /// The stream of event animation
  final _eventAnimationStream = StreamController<EventAnimation>.broadcast();

  /// All the event animation
  Stream<EventAnimation> get eventAnimation => _eventAnimationStream.stream;

  /// Only sub-stream that match the type
  Stream<T> subStream<T>() {
    return eventAnimation
        .where((
        eventAnimation) => eventAnimation is MysteryCardPickedEventAnimation)
        .cast<T>();
  }

  EventAnimationRepository();

  /// Add an event animation to the stream
  void addEventAnimation(EventAnimation eventAnimation) {
    _eventAnimationStream.add(eventAnimation);
  }
}
