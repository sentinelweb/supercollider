// program 1-04
(
MIDIClient.init();
~indexOfTr8s = MIDIClient.sources.detectIndex({arg ep; ep.name.contains("TR-8S")});
MIDIIn.connect(~indexOfTr8s, MIDIClient.sources[~indexOfTr8s]);
~indexOfTr8sCtl = MIDIClient.sources.detectIndex({arg ep; ep.name.contains("TR-8S CTRL")});
MIDIIn.connect(~indexOfTr8sCtl, MIDIClient.sources[~indexOfTr8sCtl]);
ServerOptions.inDevices[1];
ServerOptions.outDevices;
Server.default.options.inDevice_("TR-8S");
Server.default.options.outDevice_("TR-8S");
s.boot;
s.plotTree;

~tr8sCtrlUid = MIDIClient.destinations.at(~indexOfTr8sCtl).uid;
~midiOut = MIDIOut.new(~indexOfTr8sCtl,~tr8sCtrlUid);
// ~midiOut.control(10 , 49, 100);

~tempoClock = TempoClock.default;
~tempoClock.tempo = 125/60;
// Pdef(\mt, Pbind(
// 	\type, \midi,
// 	\midicmd, \control,
// 	\midiout, ~midiOut,
// 	\chan, 10,
// 	\ctlNum, 49,
// 	\dur, 4,
// 	\control, Pseq([64,20,59,53,38,47,68,32,64,60,20,32,68,52,20,40],inf)
// 	)
// ).quant_(~tempoClock.beatsPerBar);
)
Pdef(\mt).play;
s.quit;

(
SynthDef(\arp, {
	arg out=0, freq=100, attack=0.1, sustain=0.5, release=0.1, amp=0.5, filter_q=1;
	var sig, env;
	env = EnvGen.ar(Env.new([0,1,0.5,0],[attack,sustain,release], \sine), doneAction:2);
	sig = WhiteNoise.ar(mul:amp)!2 * env;
	sig = BPF.ar(sig, freq, filter_q);
	sig = BPF.ar(sig, freq, filter_q);
	sig = BPF.ar(sig, freq, filter_q);
	Out.ar(out, sig);
}).add
)
(
Pdef(\arp,Pbind(
	\instrument, \arp,
	\out, 0,
	\dur, 1,
	\amp, 2.8,
	\attack, 0.01,
	\sustain, 0.01,
	\release, 0.01,
	\scale, Scale.major,
	\degree, Pseq([
		Pseq([0, 7, 1, 5], 4),
		Pseq([0, 3, 5, Prand([1,3,4,5,7])], 8),
	],inf),
	\octave, 2.0,
	\filter_q, 4
)).quant_(~tempoClock.beatsPerBar);
)
Synth(\arp,[\mul, 0.5, \freq, 500]);

Pdef(\arp).play;
Pdef(\arp).stop;

(
SynthDef(\drone, {
	arg out=0, freq=100, amp=0.5, filter_q=1;
	var sig;
	sig = Pulse.ar(freq: freq, mul:amp)!2;
	sig = BPF.ar(sig, freq, filter_q);
	Out.ar(out, sig);
}).add
)
// TODO new stable volume for this and sequence
~drone = Synth(\drone,[\amp, 0.1, \freq, 50]);
~drone.set(\freq, Scale.major.degreeToFreq(2, 15.midicps, 1))
~drone.set(\amp, 0.4)
~drone.set(\filter_q, 0.5)
~drone.play;
~drone.free;