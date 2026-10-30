const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

test('wheel sound unlocks on gesture, caches the sample, and plays per click', async () => {
  let fetches = 0, starts = 0, resumes = 0;
  class AudioContext {
    constructor() { this.state = 'suspended'; this.destination = {}; }
    resume() { resumes++; this.state = 'running'; return Promise.resolve(); }
    decodeAudioData() { return Promise.resolve({decoded: true}); }
    createBufferSource() { return {connect() {}, start() { starts++; }}; }
  }
  const window = {AudioContext};
  const source = readFileSync(path.join(__dirname, '../../web/wheel_audio.js'), 'utf8');
  const sandbox = {window, document: {baseURI: 'https://example.test/Classipod/'}, URL,
    fetch: async () => { fetches++; return {ok: true, arrayBuffer: async () => new ArrayBuffer(1)}; }};
  vm.runInNewContext(source, sandbox);
  window.classipodWheelAudio.prime();
  await new Promise(resolve => setImmediate(resolve));
  window.classipodWheelAudio.play();
  window.classipodWheelAudio.prime();
  window.classipodWheelAudio.play();
  assert.equal(resumes, 1);
  assert.equal(fetches, 1);
  assert.equal(starts, 2);
});

test('unsupported browser degrades without throwing', () => {
  const source = readFileSync(path.join(__dirname, '../../web/wheel_audio.js'), 'utf8');
  const window = {};
  vm.runInNewContext(source, {window});
  assert.doesNotThrow(() => {window.classipodWheelAudio.prime(); window.classipodWheelAudio.play();});
});
