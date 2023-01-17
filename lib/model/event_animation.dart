import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import 'board/mystery_card.dart';

part 'event_animation.g.dart';

/// Represent an event animation action to be performed by the client
abstract class EventAnimation {
  /// The id of the event animation
  late String id;

  /// The type of the event animation
  String get type;

  /// The json constructor
  EventAnimation({this.id = ''}) {
    if (id.isEmpty) {
      id = const Uuid().v4();
    }
  }

  /// The json factory
  factory EventAnimation.fromJson(Map<String, dynamic> json) {
    switch (json["type"]) {
      case "mystery_card_picked":
        return MysteryCardPickedEventAnimation.fromJson(json);
      default:
        throw Exception("Unknown event animation type ${json["type"]}, "
            "did you forget to add it to the factory?");
    }
  }

  /// The json to map method
  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
      };

  /// Draw a mystery card
  factory EventAnimation.mysteryCardPicked(MysteryCard mysteryCard,
      String playerId) =>
      MysteryCardPickedEventAnimation(
          mysteryCard: mysteryCard, playerId: playerId);
}

/// Show the mystery card when drown
@JsonSerializable()
class MysteryCardPickedEventAnimation extends EventAnimation {
  @override
  String get type => "mystery_card_picked";

  /// The mystery card
  final MysteryCard mysteryCard;

  /// The player id who picked the card
  final String playerId;

  /// The json constructor
  MysteryCardPickedEventAnimation(
      {required this.mysteryCard, required this.playerId,})
      : super();

  factory MysteryCardPickedEventAnimation.fromJson(Map<String, dynamic> json) =>
      _$MysteryCardPickedEventAnimationFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      super.toJson()..addAll(_$MysteryCardPickedEventAnimationToJson(this));
}