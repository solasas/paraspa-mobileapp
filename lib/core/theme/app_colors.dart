import 'package:flutter/material.dart';

/// Design tokens for the SkillSwap mobile UI. Single light theme: warm paper
/// background, near-black "ink" for dark surfaces and primary actions, and a
/// lime `accent` used sparingly for active states and highlights.
class AppColors {
  AppColors._();

  // Surfaces
  static const ink = Color(0xFF15151A);
  static const inkRaised = Color(0xFF24242C);
  static const inkBorder = Color(0xFF3A3A46);
  static const inkDecorLine = Color(0xFF2C2C36);
  static const paper = Color(0xFFF4F2ED);
  static const surface = Color(0xFFFFFFFF);
  static const fieldBg = Color(0xFFF8F7F3);
  static const trackBg = Color(0xFFE9E6DF);
  static const sunken = Color(0xFFF0EEE8);

  // Borders
  static const cardBorder = Color(0xFFECE9E2);
  static const inputBorder = Color(0xFFE2DFD8);
  static const chipBorder = Color(0xFFDCD9D1);
  static const dashedBorder = Color(0xFFB9B6AE);
  static const barBorder = Color(0xFFE4E1DA);

  // Text
  static const textPrimary = Color(0xFF15151A);
  static const textSecondary = Color(0xFF5F5E66);
  static const textBody = Color(0xFF3B3A42);
  static const onDarkPrimary = Color(0xFFF4F2ED);
  static const onDarkSecondary = Color(0xFFB9B8C2);
  static const onDarkTertiary = Color(0xFFA9A8B3);

  // Brand / pastel fills
  static const accent = Color(0xFFD6F45B);
  static const lilac = Color(0xFFCBBEFF);
  static const peach = Color(0xFFFFC9A8);
  static const mint = Color(0xFF9EE6C8);
  static const sky = Color(0xFFB8E0FF);
  static const butter = Color(0xFFFFE3A3);
  static const violetStrong = Color(0xFF7B61FF);

  /// Avatar fills rotate through these.
  static const avatarFills = [lilac, peach, mint, sky, butter];

  // Skill tags
  static const teachTintBg = Color(0xFFEEF8C9);
  static const teachTintText = Color(0xFF4B5A12);
  static const learnTintBg = Color(0xFFECE7FF);
  static const learnTintText = Color(0xFF4A3F86);

  // Status pills
  static const statusPendingBg = Color(0xFFFFE7A3);
  static const statusPendingText = Color(0xFF5A4300);
  static const statusAcceptedBg = Color(0xFFD6F45B);
  static const statusAcceptedText = Color(0xFF15151A);
  static const statusDeclinedBg = Color(0xFFFFD9D3);
  static const statusDeclinedText = Color(0xFF7A2416);
  static const statusDoneBg = Color(0xFF15151A);
  static const statusDoneText = Color(0xFFF4F2ED);

  // Signals
  static const notify = Color(0xFFFF6B4A);
  static const online = Color(0xFF2BB673);
  static const onlineText = Color(0xFF1E7A4C);
  static const starOnLight = Color(0xFFF2A900);
  static const starOnDark = Color(0xFFFFC94D);
  static const danger = Color(0xFFA3311C);
  static const teachDot = Color(0xFF8DB400);

  // Misc fixed values from the spec
  static const busyCell = Color(0xFFECE9E2);
  static const busyCellText = Color(0xFF66656E);
}
