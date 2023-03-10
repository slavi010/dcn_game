export '../model/options_party.dart';
import 'package:quiver/core.dart';

// THIS FILE IS AUTO GENERATED.
// Generated by `flutter pub run json_to_model`
// See https://pub.dev/packages/json_to_model

T? checkOptional<T>(Optional<T?>? optional, T? Function()? def) {
  // No value given, just take default value
  if (optional == null) return def?.call();

  // We have an input value
  if (optional.isPresent) return optional.value;

  // We have a null inside the optional
  return null;
}
