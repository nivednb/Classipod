// Web Audio is unlocked by the user's wheel gesture. No music files leave the device.
(() => {
  let context, buffer, loading;
  function prime() {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;
    try {
      context ||= new AudioContext();
      if (context.state !== 'running') context.resume().catch(() => {});
      loading ||= fetch(new URL('assets/assets/sounds/ipod_click.wav', document.baseURI))
        .then(response => { if (!response.ok) throw new Error('Click unavailable'); return response.arrayBuffer(); })
        .then(bytes => context.decodeAudioData(bytes))
        .then(value => { buffer = value; })
        .catch(() => { loading = null; });
    } catch (_) { /* Sound is optional when unavailable. */ }
  }
  function play() {
    if (!context || !buffer || context.state !== 'running') return;
    try {
      const source = context.createBufferSource();
      source.buffer = buffer;
      source.connect(context.destination);
      source.start();
    } catch (_) { /* Sound is optional when unavailable. */ }
  }
  window.classipodWheelAudio = Object.freeze({prime, play});
})();
