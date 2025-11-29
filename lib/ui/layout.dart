import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';

class Layout {
  const Layout._();

  static const gap = _Gap();
  static const padding = _Inset();
  static const margin = _Inset();
  static const radius = _Radius();
}

class _Gap {
  const _Gap();

  Gap get zero => const Gap(0);
  Gap get xSmall => const Gap(4);
  Gap get small => const Gap(8);
  Gap get medium => const Gap(12);
  Gap get large => const Gap(16);
  Gap get xLarge => const Gap(24);
  Gap get xxLarge => const Gap(32);
}

class _Inset {
  const _Inset();

  EdgeInsets get zero => EdgeInsets.zero;
  EdgeInsets get xSmall => const EdgeInsets.all(4);
  EdgeInsets get small => const EdgeInsets.all(8);
  EdgeInsets get medium => const EdgeInsets.all(12);
  EdgeInsets get large => const EdgeInsets.all(16);
  EdgeInsets get xLarge => const EdgeInsets.all(24);
  EdgeInsets get xxLarge => const EdgeInsets.all(32);
}

extension EdgeInsetsEx on EdgeInsets {
  EdgeInsets copyLeft() => copyWith(top: 0, right: 0, bottom: 0);
  EdgeInsets copyTop() => copyWith(left: 0, right: 0, bottom: 0);
  EdgeInsets copyRight() => copyWith(left: 0, top: 0, bottom: 0);
  EdgeInsets copyBottom() => copyWith(left: 0, top: 0, right: 0);
  EdgeInsets copyHorizontal() => copyWith(top: 0, bottom: 0);
  EdgeInsets copyVertical() => copyWith(left: 0, right: 0);
}

class _Radius {
  const _Radius();

  BorderRadius get small => const BorderRadius.all(Radius.circular(8));
  BorderRadius get medium => const BorderRadius.all(Radius.circular(12));
  BorderRadius get large => const BorderRadius.all(Radius.circular(16));

  BorderRadius circular(double value) =>
      BorderRadius.all(Radius.circular(value));
}
