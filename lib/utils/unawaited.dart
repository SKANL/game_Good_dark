// Utility to mark intentionally-unawaited futures.
// Use this instead of relying on external packages.

void unawaited(Future<dynamic> _){
  // Intentionally do nothing; marks the developer intent to discard the future.
}
