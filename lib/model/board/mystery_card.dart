// ignore: depend_on_referenced_packages
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'mystery_card.g.dart';

/// A mystery card
abstract class MysteryCard {
  /// The id of the card
  final String id;

  /// The type of the mystery card
  String get type;

  /// The name of the card
  final String name;

  /// The content of the mystery card
  final String description;

  /// Id of the image to display
  final int imageId;

  MysteryCard({
    required this.id,
    required this.name,
    required this.description,
    required this.imageId,
  });

  /// From json
  factory MysteryCard.fromJson(Map<String, dynamic> json) {
    switch (json["type"]) {
      case "snow_slow_1_all":
        return SnowSlow1AllMysteryCard.fromJson(json);
      case "snow_slow_1":
        return SnowSlow1MysteryCard.fromJson(json);
      case "snow_slow_2":
        return SnowSlow2MysteryCard.fromJson(json);
      default:
        throw Exception("Unknown mystery card type ${json["type"]}, "
            "did you forget to add it to the factory?");
    }
  }

  /// To json
  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
      };

  /// TODO : Don't forget to add the new card to the factory here and above
  static final factories = {
    "snow_slow_1_all": () => SnowSlow1AllMysteryCard(),
    "snow_slow_1": () => SnowSlow1MysteryCard(),
    "snow_slow_2": () => SnowSlow2MysteryCard(),
  };

  /// Stop the player turn when the card is picked ?
  bool get stopPlayerTurnWhenPicked => false;

  /// Speed modification factor
  /// 1.0 = no modification
  /// 0.5 = half speed
  /// 2.0 = double speed
  double get speedFactor => 1.0;

  /// Stuck the player when possessed ?
  bool get stuckPlayerWhenPossessed => false;
}

/// Interface that indicates that the card is for all players
abstract class AllPlayersMysteryCard {}

/// A mystery card that have a countdown of X turns
abstract class RoundTimedMysteryCard extends MysteryCard {
  /// The duration of the effect
  int duration;

  RoundTimedMysteryCard({
    required String id,
    required String name,
    required String description,
    required this.duration,
    required int imageId,
  }) : super(
          id: id,
          name: name,
          description: description,
          imageId: imageId,
        );

  /// Count down the duration
  /// Return true if the duration is over
  bool countDown() {
    duration--;
    return duration < 0;
  }
}

/// Snow card
/// All players move 2x time slower for the next round
@JsonSerializable()
class SnowSlow1AllMysteryCard extends RoundTimedMysteryCard
    implements AllPlayersMysteryCard {
  @override
  String get type => "snow_slow_1_all";

  /// The json constructor
  SnowSlow1AllMysteryCard()
      : super(
          id: const Uuid().v4(),
          name: "Snow",
          description: "All players move 2x time slower for the next round",
          duration: 1,
          imageId: 3,
        );

  factory SnowSlow1AllMysteryCard.fromJson(Map<String, dynamic> json) =>
      _$SnowSlow1AllMysteryCardFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      super.toJson()..addAll(_$SnowSlow1AllMysteryCardToJson(this));

  @override
  bool get stopPlayerTurnWhenPicked => true;

  @override
  double get speedFactor => 0.5;

  @override
  bool get stuckPlayerWhenPossessed => false;
}

/// Snow card
/// The player move 2x time slower for the next round
@JsonSerializable()
class SnowSlow1MysteryCard extends RoundTimedMysteryCard {
  @override
  String get type => "snow_slow_1";

  /// The json constructor
  SnowSlow1MysteryCard()
      : super(
          id: const Uuid().v4(),
          name: "Snow",
          description: "The player move 2x time slower for the next round",
          duration: 1,
          imageId: 4,
        );

  factory SnowSlow1MysteryCard.fromJson(Map<String, dynamic> json) =>
      _$SnowSlow1MysteryCardFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      super.toJson()..addAll(_$SnowSlow1MysteryCardToJson(this));

  @override
  bool get stopPlayerTurnWhenPicked => true;

  @override
  double get speedFactor => 0.5;

  @override
  bool get stuckPlayerWhenPossessed => false;
}

/// Snow card
/// The player move 2x time slower for the next 2 rounds
@JsonSerializable()
class SnowSlow2MysteryCard extends RoundTimedMysteryCard {
  @override
  String get type => "snow_slow_2";

  /// The json constructor
  SnowSlow2MysteryCard()
      : super(
          id: const Uuid().v4(),
          name: "Snow",
          description: "The player move 2x time slower for the next 2 rounds",
          duration: 2,
          imageId: 5,
        );

  factory SnowSlow2MysteryCard.fromJson(Map<String, dynamic> json) =>
      _$SnowSlow2MysteryCardFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      super.toJson()..addAll(_$SnowSlow2MysteryCardToJson(this));

  @override
  bool get stopPlayerTurnWhenPicked => true;

  @override
  double get speedFactor => 0.5;

  @override
  bool get stuckPlayerWhenPossessed => false;
}

// Same but for raining

/// Rain card
/// All players move 2x time slower for the next round
@JsonSerializable()
class RainSlow1AllMysteryCard extends RoundTimedMysteryCard
    implements AllPlayersMysteryCard {
  @override
  String get type => "rain_slow_1_all";

  /// The json constructor
  RainSlow1AllMysteryCard()
      : super(
          id: const Uuid().v4(),
          name: "Rain",
          description: "All players move 2x time slower for the next round",
          duration: 1,
          imageId: 6,
        );

  factory RainSlow1AllMysteryCard.fromJson(Map<String, dynamic> json) =>
      _$RainSlow1AllMysteryCardFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      super.toJson()..addAll(_$RainSlow1AllMysteryCardToJson(this));

  @override
  bool get stopPlayerTurnWhenPicked => true;

  @override
  double get speedFactor => 0.5;

  @override
  bool get stuckPlayerWhenPossessed => false;
}

/// Rain card
/// The player move 2x time slower for the next round
@JsonSerializable()
class RainSlow1MysteryCard extends RoundTimedMysteryCard {
  @override
  String get type => "rain_slow_1";

  /// The json constructor
  RainSlow1MysteryCard()
      : super(
          id: const Uuid().v4(),
          name: "Rain",
          description: "The player move 2x time slower for the next round",
          duration: 1,
          imageId: 7,
        );

  factory RainSlow1MysteryCard.fromJson(Map<String, dynamic> json) =>
      _$RainSlow1MysteryCardFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      super.toJson()..addAll(_$RainSlow1MysteryCardToJson(this));

  @override
  bool get stopPlayerTurnWhenPicked => true;

  @override
  double get speedFactor => 0.5;

  @override
  bool get stuckPlayerWhenPossessed => false;
}

/// Rain card
/// The player move 2x time slower for the next 2 rounds
@JsonSerializable()
class RainSlow2MysteryCard extends RoundTimedMysteryCard {
  @override
  String get type => "rain_slow_2";

  /// The json constructor
  RainSlow2MysteryCard()
      : super(
          id: const Uuid().v4(),
          name: "Rain",
          description: "The player move 2x time slower for the next 2 rounds",
          duration: 2,
          imageId: 8,
        );

  factory RainSlow2MysteryCard.fromJson(Map<String, dynamic> json) =>
      _$RainSlow2MysteryCardFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      super.toJson()..addAll(_$RainSlow2MysteryCardToJson(this));

  @override
  bool get stopPlayerTurnWhenPicked => true;

  @override
  double get speedFactor => 0.5;

  @override
  bool get stuckPlayerWhenPossessed => false;
}