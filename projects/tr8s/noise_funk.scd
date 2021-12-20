// program 1-1
(
MIDIClient.init();
~indexOfTr8s = MIDIClient.sources.detectIndex({arg ep; ep.name.contains("TR-8S")});
MIDIIn.connect(~indexOfTr8s, MIDIClient.sources[~indexOfTr8s]);
~indexOfTr8sCtl = MIDIClient.sources.detectIndex({arg ep; ep.name.contains("TR-8S CTRL")});
MIDIIn.connect(~indexOfTr8sCtl, MIDIClient.sources[~indexOfTr8sCtl]);

~tr8sCtrlUid = MIDIClient.destinations.at(~indexOfTr8sCtl).uid;
~midiOut = MIDIOut.new(~indexOfTr8sCtl,~tr8sCtrlUid);
// ~midiOut.control(10 , 49, 100);

~tempoClock = TempoClock.default;
~tempoClock.tempo = 125/60;
Pdef(\mt, Pbind(
    \type, \midi,
    \midicmd, \control,
    \midiout, ~midiOut,
    \chan, 10,
	\ctlNum, 49,
    \dur, 4,
	\control, Pseq([64,20,59,53,38,47,68,32,64,60,20,32,68,52,20,40],inf)
)
).quant_(~tempoClock.beatsPerBar);
Pdef(\mt).play;
PdefAllGui();
)
Pdef(\mt).play;
//////////////////////////////////////////////////////////

(
SynthDef(\arp, {
	arg out=0, freq=100, attack=0.1, sustain=0.5, release=0.1, amp=0.5, wid=0.5, filter_q=1;
	var sig, env;
	env = EnvGen.ar(Env.new([0,1,0.5,0],[attack,sustain,release],\sine), doneAction:2);
	sig = Pulse.ar(freq, wid, mul:amp)!2 * env;
	sig = BPF.ar(sig,freq, 3);
	Out.ar(out, sig);
}).add
)

x = Synth(\arp,[\mul,0.5, \freq,500]);
x.set(\freq, 200);
x.scope;
x.play;
x.free;
(~modes = [
	(\a:0.4,\wid:2, \at:0.01, \rel:0.01),
	(\a:0.2,\wid:0.2, \at:0.01, \rel:0.01),
	(\a:0.15,\wid:0.5, \at:0.01, \rel:0.01),
	(\a:0.07,\wid:0.05, \at:0.2, \rel:0.1),
	(\a:0.03,\wid:0.3, \at:0.3, \rel:0.3),
	(\a:0.3, \wid:0.05, \at:0.01, \rel:0.01),// livecode
];

~mode = ~modes[5];
Pdef(\arp,Pbind(
	\instrument, \arp,
	\out, 0,
	\dur, 0.25,
	\amp, ~mode[\a],
	\attack, ~mode[\at],//Pseq([Pseq([0.1, 0.05, 0.01],16)], inf),
	\sustain, 0.02,
	\release, ~mode[\rel],//Pseq([Pseq([0.01, 0.05, 0.5],8)], inf),
	\scale, Scale.dorian,
	\degree, Pseq([
		Pseq([0,7,1,12],4),
		Pseq([0,7,5, Prand([12,15,19,-2,0, 3, 5, 18])], 2)
	],inf),
	\octave, 6.0,
	\wid, ~mode[\wid]//Pseq([0.5, 0.4, 0.3, 0.2, 0.1, 0.05, 0.2, 0.4, 0.35], inf)//2//
)).quant_(~tempoClock.beatsPerBar);
)
Pdef(\arp).play;
Pdef(\arp).stop;
~mode[\a]
Scale
//////////////////////////////////////

MIDIIn.connectAll;
MIDIdef.noteOn(\tr8sNoteOn, {|v,n,ch,id| ["noteOn",v,n,ch,id].postln;});
MIDIdef.noteOff(\tr8sNoteOff, {|v,n,ch,id| ["noteOff",v,n,ch,id].postln;});
MIDIdef.cc(\tr8sCtl, {|v,n,ch,id| ["control",v,n,ch,id].postln;});

// FreqScope.new(400, 200, 0, server: s);
ServerOptions.inDevices[1];
ServerOptions.outDevices;
Server.default.options.inDevice_("TR-8S");
Server.default.options.outDevice_("TR-8S");
s.quit;
s.boot;
s.plotTree;
Scale.major.at([1,2,3])

Env.new.plot;
Env.new([0,1,0.5,0],[0.2,0.5,1],\sine).plot;