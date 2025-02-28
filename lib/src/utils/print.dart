/// Print the debug log.
void debugPrinter(Object? Function() log, {bool debug = false}) {
  assert(
    () {
      // ignore: avoid_print
      if (debug) print('[Isolate Manager]: ${log()}');

      return true;
    }(),
    'Only print debug log in debug mode.',
  );
}
