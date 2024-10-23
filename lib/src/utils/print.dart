/// Print the debug log.
void debugPrinter(Object? Function() log, {bool debug = false}) {
  if (debug) {
    // ignore: avoid_print
    print('[Isolate Manager]: ${log()}');
  }
}
