import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism_widgets/glassmorphism_widgets.dart';

class ShadowGlassContainer extends StatelessWidget {
  const ShadowGlassContainer({
    Key? key,
    this.alignment,
    this.padding,
    this.linearGradient,
    this.borderGradient,
    this.blur,
    this.width,
    this.height,
    this.constraints,
    this.margin,
    this.transform,
    this.transformAlignment,
    this.radius,
    this.border,
    this.borderRadius,
    this.child,
    this.boxShadow = const [
      BoxShadow(
        color: Color(0x17000000),
        blurRadius: 40,
        offset: Offset(20, 20),
      ),
    ],
  }) : super(key: key);

  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final AlignmentGeometry? transformAlignment;

  final EdgeInsetsGeometry? margin;
  final Matrix4? transform;

  final Widget? child;
  final double? radius;
  final double? border;
  final double? blur;
  final LinearGradient? linearGradient;
  final LinearGradient? borderGradient;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: GlassContainer(
        padding: padding,
        alignment: alignment,
        transformAlignment: transformAlignment,
        margin: margin,
        transform: transform,
        radius: radius,
        border: border,
        blur: blur,
        linearGradient: linearGradient,
        borderGradient: borderGradient,
        borderRadius: borderRadius,
        width: width,
        height: height,
        constraints: constraints,
        child: child,
      ),
    );
  }
}

class CustomGlassButton extends StatelessWidget {
  final double? radius;
  final double? border;
  final double? blur;
  final LinearGradient? linearGradient;
  final LinearGradient? borderGradient;
  final BorderRadius? borderRadius;

  const CustomGlassButton({
    Key? key,
    this.radius,
    this.border,
    this.blur = 30,
    this.linearGradient,
    this.borderGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x15FFFFFF),
        Color(0x15FFFFFF),
      ],
    ),
    this.borderRadius,
    this.child,
    required this.onPressed,
    this.onLongPressed,
  }) : super(key: key);

  final Widget? child;
  final void Function() onPressed;
  final void Function()? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      radius: radius,
      border: border,
      blur: blur,
      linearGradient: linearGradient,
      borderGradient: borderGradient,
      borderRadius: borderRadius,
      onPressed: onPressed,
      onLongPressed: onLongPressed,
      child: child,
    );
  }
}


class CustomGlassText extends StatelessWidget {
  const CustomGlassText(this.data, {
    this.style,
    this.color = Colors.white,
    this.opacity = 0.8,
    this.fontSize,
    this.fontWeight = FontWeight.bold,
    Key? key,
  }) : super(key: key);

  final String data;
  final TextStyle? style;
  final double opacity;
  final double? fontSize;
  final FontWeight fontWeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassText(
      data,
      style: style,
      color: color,
      opacity: opacity,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

}