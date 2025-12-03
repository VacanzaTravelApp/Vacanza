import 'package:flutter/material.dart';

final class AppTextStyles {
  AppTextStyles._();

  static TextStyle titleLarge(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.w700,
      );

  static TextStyle bodyMedium(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!;

  static TextStyle bodySmall(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!;
}
