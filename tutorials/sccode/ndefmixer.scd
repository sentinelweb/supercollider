n = NdefMixer(s);
n.parent.alwaysOnTop_(true); // show mixer in front of IDE

s.boot;
// if you have JITLibExtensions installed, try ProxyMeter to see the proxy levels:
if (\ProxyMeter.asClass.notNil) { ProxyMeter.addMixer(n); };

(
Ndef(\aaaaaa, { |freq=250, intv=19, timescale=1, curve=0, loopnode=0|
    var env = EnvGen.kr(
        Env({ 1.0.rand2 }!11, {1.0.rand}!10, curve, releaseNode: 9, loopNode: loopnode),
        timeScale: timescale);
    var pitch = (env * [1, 0.33, -1] * intv).midiratio * freq;
    Splay.ar(Formant.ar(pitch, pitch.scramble * 2, pitch.scramble)) * 0.1;
}).play(vol: 0.25);
)

n.switchSize(2);
n.switchSize(1);
n.switchSize(0);

n.switchSize(2);
n.editGui.object_(Ndef(\aaaaaa));

NdefMixer(Server.internal, 24);

