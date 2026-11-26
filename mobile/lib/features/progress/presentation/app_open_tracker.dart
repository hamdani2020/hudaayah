import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_repository.dart';

/// Records "opened the app today" for Day-1/2/7 return rates. Wraps the signed-in
/// shell, so it only runs for signed-in learners. Fires on start and whenever the
/// app comes back to the foreground, at most every 30 minutes. The server keeps one
/// record per day, so extra calls are harmless. Failures are ignored.
class AppOpenTracker extends ConsumerStatefulWidget {
  const AppOpenTracker({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppOpenTracker> createState() => _AppOpenTrackerState();
}

class _AppOpenTrackerState extends ConsumerState<AppOpenTracker>
    with WidgetsBindingObserver {
  static const _minInterval = Duration(minutes: 30);
  DateTime? _lastSent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _record();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _record();
  }

  Future<void> _record() async {
    final now = DateTime.now();
    final last = _lastSent;
    if (last != null && now.difference(last) < _minInterval) return;
    _lastSent = now;
    try {
      await ref.read(progressRepositoryProvider).recordAppOpen();
    } catch (_) {
      _lastSent = last; // try again next time the app is opened
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
