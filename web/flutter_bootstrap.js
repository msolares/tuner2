{{flutter_js}}
{{flutter_build_config}}

// La app necesita que Safari reciba el bundle actual inmediatamente. El
// service worker generado por Flutter puede conservar una versión anterior
// hasta varias recargas, así que se elimina y se usa la caché HTTP normal.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then((registrations) => {
    for (const registration of registrations) {
      registration.unregister();
    }
  });
}

_flutter.loader.load();
