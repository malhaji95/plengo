// Start-up helpers kept out of index.html so the Content-Security-Policy needs no inline scripts.

// The HTML loading screen goes away once Flutter has drawn its first frame.
window.addEventListener('flutter-first-frame', () => {
  const boot = document.getElementById('boot');
  if (!boot) return;
  boot.style.opacity = '0';
  setTimeout(() => boot.remove(), 250);
});

// Offline-fallback service worker (spec §24). Install prompts stay off: the manifest uses display
// "browser" until Plan B.
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('sw.js').catch(() => {});
  });
}
