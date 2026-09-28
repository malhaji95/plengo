{{flutter_js}}
{{flutter_build_config}}

// No serviceWorkerSettings: Flutter's own worker is deprecated and unregisters itself, which would
// replace the offline-fallback worker registered by boot.js (spec §24).
_flutter.loader.load();
