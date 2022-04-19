// program 1-04
(
Server.default.options.inDevice_("TR-8S");
Server.default.options.outDevice_("TR-8S");
s.boot;
s.plotTree;
PdefAllGui();
MIDIClient.init();
~indexOfTr8s = MIDIClient.sources.detectIndex({arg ep; ep.name.contains("TR-8S")});
MIDIIn.connect(~indexOfTr8s, MIDIClient.sources[~indexOfTr8s]);
~indexOfTr8sCtl = MIDIClient.sources.detectIndex({arg ep; ep.name.contains("TR-8S CTRL")});
MIDIIn.connect(~indexOfTr8sCtl, MIDIClient.sources[~indexOfTr8sCtl]);
// ServerOptions.inDevices[1];
// ServerOptions.outDevices;
// ServerOptions.inDevices;
~tr8sCtrlUid = MIDIClient.destinations.at(~indexOfTr8sCtl).uid;
~midiOut = MIDIOut.new(~indexOfTr8sCtl,~tr8sCtrlUid);

~tempoClock = TempoClock.default;
~tempoClock.tempo = 125/60;
)
(
//////////////////// state /////////////////////////////////////////////////////
~state = (
	\arp:(
		\dur: 0.25,
		\amp: 0.01,
		\attack: 0.01,
		\sustain: 0.001,
		\release: 0.01,
		\filter_q: 80
	),
	\drone:(
		\amp: 0.01,
		\filter_q:100
	),
	\ping:(
		\dur: 0.25,
		\amp: 0.01,
		\attack: 0.01,
		\sustain: 0.001,
		\release: 0.01,
		\modFreq:10,
		\modAmp:30
	),
);

////////////////// midi /////////////////////////////////
~apc = AkaiAPC40();
~apc.addCtlIn(\s1,{~state[\arp][\amp] = ~val.linexp(0,127,0.001,10)});
~apc.addCtlIn(\k1,{~state[\arp][\filter_q] = ~val.linexp(0,127,1,200)});
~apc.addCtlIn(\sk1,{~state[\arp][\attack] = ~val.linexp(0,127,0.001,0.3)});
~apc.addCtlIn(\sk2,{~state[\arp][\sustain] = ~val.linexp(0,127,0.001,0.3)});
~apc.addCtlIn(\sk3,{~state[\arp][\release] = ~val.linexp(0,127,0.001,0.3)});
~apc.addCtlIn(\s2,{~state[\drone][\amp] = ~val.linexp(0,127,0.01,1.5);~drone.set(\amp, ~state[\drone][\amp])});
~apc.addCtlIn(\k2,{~state[\drone][\filter_q] = ~val.linexp(0,127,1,200)});
~apc.addCtlIn(\s3,{~state[\ping][\amp] = ~val.linexp(0,127,0.001,10)});
~apc.addCtlIn(\sk5,{~state[\ping][\attack] = ~val.linexp(0,127,0.001,0.3)});
// ~apc.addCtlIn(\sk6,{~state[\ping][\sustain] = ~val.linexp(0,127,0.001,0.3)});
~apc.addCtlIn(\sk6,{~state[\ping][\release] = ~val.linexp(0,127,0.001,0.3)});
~apc.addCtlIn(\sk7,{~state[\ping][\modFreq] = ~val.linexp(0,127,0.1,500);});
~apc.addCtlIn(\sk8,{~state[\ping][\modAmp] = ~val.linexp(0,127, 0.1,1000)});
)
Pdef(\mt).play;
s.quit;

//////////////////// arp 1 /////////////////////////////////////////////////////
(
SynthDef(\arp, {
	arg out=0, freq=100, attack=0.1, sustain=0.5, release=0.1, amp=0.5, filter_q=1;
	var sig, env;
	env = EnvGen.ar(Env.new([0,1,0.5,0],[attack,sustain,release], \sine), doneAction:2);
	sig = WhiteNoise.ar(mul:amp)!2 * env;
	sig = BPF.ar(sig, freq, filter_q);
	sig = BPF.ar(sig, freq, filter_q);
	sig = BPF.ar(sig, freq, filter_q);
	sig = BPF.ar(sig, freq, filter_q);
	sig = Compander.ar(sig, sig, thresh: amp, slopeBelow: 1, slopeAbove: 0.1, clampTime:  0.01, relaxTime:  0.01);
	Out.ar(out, sig);
}).add;

Pdef(\arp,Pbind(
	\instrument, \arp,
	\out, 0,
	\dur, Pfunc({~state[\arp][\dur]}),
	\amp, Pfunc({~state[\arp][\amp]}),
	\attack, Pfunc({~state[\arp][\attack]}),
	\sustain, Pfunc({~state[\arp][\sustain]}),
	\release, Pfunc({~state[\arp][\release]}),
	\scale, Scale.minor,
	\degree, Pseq([
		// Pseq([0, 7, 1, 5], 4),
		Pseq([0, 3, 5, Prand([1,3,4,5,7])], 8),
	],inf),
	\octave, 2.0,
	\filter_q, Pfunc({~state[\arp][\filter_q]})
)).quant_(~tempoClock.beatsPerBar);

Pdef(\arp).play;
)
Synth(\arp,[\mul, 0.5, \freq, 500]);

Pdef(\arp).play;
Pdef(\arp).stop;
///////////////////////////// drone ////////////////////////////////////////////
(
SynthDef(\drone, {
	arg out=0, freq=100, amp=0.5, filter_q=1;
	var sig;
	sig = Pulse.ar(freq: freq, mul:amp)!2;
	sig = BPF.ar(sig, freq, filter_q);
	sig = FreeVerb.ar(sig, 0.5, 0.2, 0.1);
	Out.ar(out, sig);
}).add;

(~drone != nil).if {~drone.free};
~drone = Synth(\drone,[\amp, 0.001, \freq, Scale.major.degreeToFreq(2, 20.midicps, 1)]);
Pdef(\drone, Pbind(
	\type, \set,
	\id, ~drone.nodeID,
	\args, #[\freq, \amp, \filter_q],
	\dur, 8,
	\amp, Pfunc({~state[\drone][\amp]}),
	\scale, Scale.major,
	\degree, Pseq([
		Pseq([13, 15, 18, Prand([17, 19])], 4)
	],inf),
	\octave, 0.0,
	\filter_q, Pfunc({~state[\drone][\filter_q]})
)).quant_(~tempoClock.beatsPerBar);
Pdef(\drone).play;
)
Pdef(\drone).play;
Pdef(\drone).stop;

~drone.set(\freq, Scale.major.degreeToFreq(2,17.midicps, 1))
~drone.set(\amp, 0.4)
~drone.set(\filter_q, 0.5)
~drone.play;
~drone.free;

///////////////////////////// ping ////////////////////////////////////////////
(
SynthDef(\ping, {
	arg out=0, freq=100, modFreq=100, modAmp=10, amp = 1,attack=0.1, sustain=0.1, release=0.1;
	var sig, modSig, env;
	env = EnvGen.ar(Env.new([0, 1, 0.5, 0],[attack, sustain, release], \sine), doneAction:2);
	modSig = freq + SinOsc.ar(freq: modFreq, mul:modAmp, add: modAmp);
	sig = SinOsc.ar(freq: modSig, mul:amp)!2;
	Out.ar(out, sig * env);
}).add;

~scale = {|f| Scale.major.degreeToFreq(2, f.midicps, 1)};

Pdef(\ping, Pbind(
	\instrument, \ping,
	\out, 0,
	\dur, Pfunc({~state[\ping][\dur]}),
	\amp, Pfunc({~state[\ping][\amp]}),
	\attack, Pfunc({~state[\ping][\attack]}),
	\sustain, Pfunc({~state[\ping][\sustain]}),
	\release, Pfunc({~state[\ping][\release]}),
	\modFreq, Pfunc({~state[\ping][\modFreq]}),
	\modAmp, Pfunc({~state[\ping][\modAmp]}),
	\scale, Scale.minor,
	\degree, Pseq([
		Pseq([0, 3, 5, Prand([1,3,4,5,7])], 8),
	],inf),
	\octave, 5.0
)).quant_(~tempoClock.beatsPerBar);

Pdef(\ping).play;
)
Pdef(\ping).stop;
Synth(\ping, [\amp, 0.1, \freq, ~scale.(81), \modFreq, ~scale.(50), \modAmp:200]);
~ping.play;
~scale.(1)
~state[\ping][\amp] = 0.2;
~state[\ping][\modFreq]
~state[\ping][\dur] = 0.25;
/////////////////// send notes out //////////////////////
//Pdef(\mt, Pbind(
// 	\type, \midi,
// 	\midicmd, \control,
// 	\midiout, ~midiOut,
// 	\chan, 10,
// 	\ctlNum, 49,
// 	\dur, 4,
// 	\control, Pseq([64,20,59,53,38,47,68,32,64,60,20,32,68,52,20,40],inf)
// 	)
// ).quant_(~tempoClock.beatsPerBar);