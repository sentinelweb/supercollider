s.plotTree
s.meter
MIDIClient.init

// conenct all devices
MIDIIn.connectAll;

// to just connect 1 device
MIDIClient.sources;
MIDIIn.connect(1)

MIDIdef(\noteOnTest).disable
MIDIdef(\noteOnTest).enable
MIDIdef(\noteOnTest).free
MIDIdef.freeAll
MIDIdef.cc(\ccTest,{"cc on:".postln})
MIDIdef(\noteOnTest).disable

(
~notes = Array.newClear(128);
~bend=8192;
~duty = 0.5;
~bpFreq=300;
~bpWid=100;
~vibHz=1;
~vibMul = 1;
~atk=0.1;
~dec=0.5;
~sus=0.7;
~rel=2;
MIDIdef.noteOn(\noteOnTest,{|vel, nn, chan, s|
	["noteon",vel, nn, ~bend, ~duty].postln;
	//Synth(\tone);
	~notes[nn] = Synth(\tone,
		[
			\freq, nn.midicps,
			\amp, vel.linexp(1,127,0.01,0.4),
			\gate:1,
			\bend:~bend.linlin(0, 16384, 0.16,-2.2),
			\duty:~duty,
			\bpFreq:~bpFreq,
			\bpWid:~bpWid,
			\vibHz:~vibHz,
			\vibMul:~vibMul,
			\atk:~atk,
			\dec:~dec,
			\sus:~sus,
			\rel:~rel
		]
	);
});

MIDIdef.noteOff(\noteOffTest, {
	|vel,nn|
	["noteoff",vel, nn].postln;
	~notes[nn].set(\gate, 0);
	~notes[nn] = nil
});

MIDIdef.bend(\bendTest, {
	|val, chan, src|
	["bend", val, chan].postln;
	~bend = val.linlin(0,16384, 0.16,-2.2);
	~notes.do{arg synth; synth.set(\bend,~bend)};
}
);

MIDIdef.cc(\ccTest,{|val, ctnum, chan|
	["cc", val, ctnum, chan].postln;
	c = switch (ctnum)
	{1} {
		~duty = val.linlin(0,127, 0.0001,0.9999);
		~notes.do{arg synth; synth.set(\duty,~duty)};
		["duty",~duty].postln;
	}
	{106} {//\bpFreq - topleft - offset from note freq
		~bpFreq = val.linlin(0,127, -1,1);
		~notes.do{arg synth; synth.set(\bpFreq,~bpFreq)};
		["bpFreq",~bpFreq].postln;
	}
	{107} {// \bpWid filter width
		~bpWid = val.linlin(0,127, 1,10);
		~notes.do{arg synth; synth.set(\bpWid,~bpWid)};
		["bpWid",~bpWid].postln;
	}
	{108} {// \~vibHz vibrato Hz
		~vibHz = val.linexp(0,127, 0.25, 20);
		~notes.do{arg synth; synth.set(\vibHz,~vibHz)};
		["~vibHz",~vibHz].postln;
	}
	{109} {// \~vibMul top right - vibratio ratio - of note freq
		~vibMul = val.linlin(0,127, 0,1);
		~notes.do{arg synth; synth.set(\vibMul,~vibMul)};
		["vibMul",~vibMul].postln;
	}
	{102} {// \~atk bottom left attack time
		~atk = val.linlin(0,127, 0,5);
		~notes.do{arg synth; synth.set(\atk,~atk)};
		["atk",~atk].postln;
	}
	{103} {// \~dec bottom 2nd left decay time
		~dec = val.linlin(0,127, 0,1);
		~notes.do{arg synth; synth.set(\dec,~dec)};
		["dec",~dec].postln;
	}
	{104} {// \~sus bottom 2n right sustain level
		~sus = val.linlin(0,127, 0,1);
		~notes.do{arg synth; synth.set(\sus,~sus)};
		["sus",~sus].postln;
	}
	{105} {// \~rel bottom right release time
		~rel = val.linexp(0,127, 0.01,5);
		~notes.do{arg synth; synth.set(\rel,~rel)};
		["rel",~rel].postln;
	}
	{"unmapped:"+chan +":"+ ctnum + " -> "+val};
});
)

(
SynthDef.new(\tone, {
	arg freq=440, amp=0.3, gate=0, bend = 0, duty = 0.5, bpFreq=100,
	bpWid=20, vibHz=1, vibMul=100, atk=0.1, dec=1, sus=0.8, rel=2;
	var sig, env, mod, scope /*, gain*/;
	sig = LFPulse.ar(freq * bend.midiratio,0, width:duty ).distort(0.2)!2;
	env = EnvGen.kr(Env.adsr(atk,dec,sus,rel),gate, doneAction:2);
	"xx".postln;
	scope = FreqScope.new(400, 200, 0, server: s);
	["vibHz", vibHz, vibMul ].postln;
	mod = SinOsc.kr(vibHz, mul:vibMul*freq);//.scope();
	sig =  RLPF.ar(sig, freq +(bpFreq*freq/2) + mod , bpWid); //MoogFF, RLPF, Resonz, MoogVCF (good), MoogLadder
	//sig.scope;
	// gain = (amp/sig.max);
	sig = sig * env * amp;
	Out.ar(0,sig);
}).add
)

// test synth
x = Synth(\tone, [\freq, 61.midicps, \amp, 0.1]);
x.set(\freq, 50);
x.set(\amp, 10);
x.set(\gate, 1);
x.set(\gate, 0);
x.set(\bend, 4);
x.set(\bpFreq,1000);
x.set(\bpWid, 0.01);
x.set(\vibHz, 0.25);
x.set(\vibMul, 500);
x.free