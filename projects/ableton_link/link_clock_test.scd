(
s.waitForBoot({
	SynthDef(\click, { |freq=400, amp=0.2|
        var sig = SinOsc.ar(freq, 0.5pi) *
            Env.perc(0.001,0.06).ar(Done.freeSelf, levelScale: amp);
        OffsetOut.ar(0, sig.dup)
    }).add;

	SynthDef(\kick, {
		arg  out = 0, amp = 0.5, dura = 0.25, freq = 50, metal = 1.1, makeup_gain=1;
		var amp_env, freq_env, phase_env, phase, sig, mid_sig, sub_env, sub_sig, hit_env, hit_sig;

		amp_env   = EnvGen.ar(Env.perc(1e-6, dura), doneAction:2) * amp;
		freq_env  = EnvGen.ar(Env.new([1, 0.5, 0.5],[0.5, 1]*dura), doneAction:2) * freq;
		phase_env = EnvGen.ar(Env.perc(1e-6, 0.125));
		phase = SinOsc.ar(20, 0, pi) * phase_env;
		mid_sig = SinOsc.ar([freq_env, metal*freq_env], phase) * amp_env;

		sub_env = EnvGen.ar(Env.new([0, 1, 1, 0]*amp, [0.4, 0.2] * dura, curve:\sine), doneAction:0);
		sub_sig = SinOsc.ar(freq) * sub_env;

		hit_env = EnvGen.ar(Env.new([0, 1, 0.5, 0]*2*amp,[1e-4, 0.01, 0.03]*dura, curve:-1), doneAction:0);
		hit_sig = (SinOsc.ar(freq*2)+BPF.ar(WhiteNoise.ar(10), freq: freq, rq: 0.5)) * hit_env;

		sig = sub_sig + mid_sig + hit_sig;

		sig = Compander.ar(sig, sig, thresh:0.8, slopeBelow:2, slopeAbove:0.6, clampTime:0.035, relaxTime:0.3) * makeup_gain;

		Out.ar(out, sig);
	}).add;
})
)
// create a synchronized clock
~linkClock = LinkClock(1).latency_(Server.default.latency)
/////////////////// Link window ////////////////////
(
// link clock window - from LinkClock docs
// possibly might be a need to use a simplecontroller to get link start/stop messages and start/stop patterns accordingly.
// see LinkClock docs for example.
// maybe add more functionality to this window.
var win = Window("LinkClock", Rect(200, 200, 500, 100)).front,
peersBox, tempoBox, barsBox, beatsBox,
font = Font.default.copy.size_(32),
boldFont = font.boldVariant,
controller, task;

win.layout = HLayout(
    StaticText().font_(font).string_("Peers:"),
    peersBox = NumberBox().font_(boldFont).align_(\center).fixedWidth_(80),
    StaticText().font_(font).string_("Tempo:"),
    tempoBox = NumberBox().font_(boldFont).align_(\center).fixedWidth_(120),
    StaticText().font_(font).string_("Now:"),
    barsBox = NumberBox().font_(boldFont).align_(\center).fixedWidth_(80),
    beatsBox = NumberBox().font_(boldFont).align_(\center).fixedWidth_(80)
);

[peersBox, barsBox, beatsBox].do { |view| view.enabled_(false) };

tempoBox.action = { |view| ~linkClock.tempo = view.value / 60 };
tempoBox.value = ~linkClock.tempo * 60;
peersBox.value = ~linkClock.numPeers;

task = Routine {
    var bars, beats;
    loop {
        bars = ~linkClock.bar;
        beats = ~linkClock.beatInBar;
        {
            barsBox.value = bars;
            beatsBox.value = beats;
        }.defer(~linkClock.latency);
        1.0.wait;
    }
}.play(~linkClock, quant: 1);

controller = SimpleController(l)
.put(\tempo, {
    defer { tempoBox.value = ~linkClock.tempo * 60 }
})
.put(\numPeers, {
    defer { peersBox.value = ~linkClock.numPeers }
})
.put(\stop, { defer { win.close } });

win.onClose = { task.stop; controller.remove };
)
////////// patterns //////////////////////////////////////////
(
Pdef(\kick, Pbind(
	\instrument, \kick,
	\amp, 2,
	\dur, 1,
	\midinote, 8,
	\dura, 0.5,
	\metal, 5,
	\makeup_gain, 1.3
));//.quant_(~linkClock.beatsPerBar) // doesnt work

Pdef(\metro, Pbind(
	\instrument, \click, \freq, Pseq([900, Pn(1200, 3)], inf)
))
)
// strange things here bpm is totally wrong - possibly have to wait for sync value? not sure
Pdef(\kick).play(~linkClock, quant:~linkClock.beatsPerBar);
Pdef(\kick).stop;
Pdef(\metro).play(~linkClock, quant:~linkClock.beatsPerBar);
Pdef(\metro).stop;

~linkClock.tempo = 125/60;
//////////////// test ////////////////////////////
~kick = Synth.new(\kick, [\amp: 1, \freq: 40, \metal: 2]);

p = Pbind(\instrument, \click, \freq, Pseq([900, Pn(400,3)], inf)).play(~linkClock, quant:4);
p.stop;
