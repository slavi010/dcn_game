// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_animation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MysteryCardPickedEventAnimation _$MysteryCardPickedEventAnimationFromJson(
        Map<String, dynamic> json) =>
    MysteryCardPickedEventAnimation(
      mysteryCard:
          MysteryCard.fromJson(json['mysteryCard'] as Map<String, dynamic>),
      playerId: json['playerId'] as String,
    )..id = json['id'] as String;

Map<String, dynamic> _$MysteryCardPickedEventAnimationToJson(
        MysteryCardPickedEventAnimation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mysteryCard': instance.mysteryCard,
      'playerId': instance.playerId,
    };
