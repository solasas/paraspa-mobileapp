import 'package:flutter/material.dart';

import '../utils/enums.dart';
import 'pills.dart';

/// Thin wrapper kept so call sites read `StatusBadge.exchange(status)`;
/// renders the spec's status pill.
class StatusBadge extends StatelessWidget {
  const StatusBadge.exchange(ExchangeStatus this.exchangeStatus, {super.key})
      : sessionStatus = null;

  const StatusBadge.session(SessionStatus this.sessionStatus, {super.key})
      : exchangeStatus = null;

  final ExchangeStatus? exchangeStatus;
  final SessionStatus? sessionStatus;

  @override
  Widget build(BuildContext context) {
    if (exchangeStatus != null) return StatusPill.exchange(exchangeStatus!);
    return StatusPill.session(sessionStatus!);
  }
}
