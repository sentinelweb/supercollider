///////////////////// synth ////////////////////////////////////

(
MIDIClient.init;

MIDIIn.connectAll;
MIDIClient.sources;
(~notes == nil).if {
~notes = Array.newClear(128);
~bend=8192;
~duty = 0.5;
~bpFreq=0;
~bpWid=10;
~vibHz=1;
~vibMul = 0.2;
~atk=0.1;
~dec=0.5;
~sus=0.7;
~rel=2;
~filterNum=0;
};

MIDIdef.noteOn(\noteOnTest,{|vel, nn, chan, s|
	["noteon",vel, nn, chan, s, ~bend, ~duty].postln;
	//Synth(\tone);
	~notes[nn] = Synth(\tone,
		[
			\freq, nn.midicps,
			\vel, vel.linexp(1,127,0.01,0.4),
			\amp, ~amp,
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
			\rel:~rel,
			\filterNum:~filterNum
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
		~bpWid = val.linexp(0,127, 1,100);
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
	{104} {// \~rel bottom 2n right release time
		~rel = val.linexp(0,127, 0.01,5);
		~notes.do{arg synth; synth.set(\rel,~rel)};
		["rel",~rel].postln;
	}
	{105} {// \~sus bottom right gain
		~amp = val.linexp(0,127, 0.01,10);
		~notes.do{arg synth; synth.set(\amp,~amp)};
		["amp",~amp].postln;
	}
	{20} {// reload button (left) cycle filter
		~filterNum = (~filterNum+1).mod(5);
		~notes.do{arg synth; synth.set(\filterNum,~filterNum)};
		["filterNum",~filterNum].postln;
	}

	{"unmapped:"+chan +":"+ ctnum + " -> "+val};
});

SynthDef.new(\tone, {
	arg freq=440, vel=100, amp=1, gate=0, bend = 0, duty = 0.5, bpFreq=0,
	bpWid=1, vibHz=1, vibMul=0.1, atk=0.1, dec=1, sus=0.8, rel=2, filterNum=0 /* not working */;
	var sig, env, mod, scope , filterFreq;
	sig = LFPulse.ar(freq * bend.midiratio,0, width:duty ).distort(0.2)!2;
	env = EnvGen.kr(Env.adsr(atk,dec,sus,rel),gate, doneAction:2);
	"xx".postln;
	scope = FreqScope.new(400, 200, 0, server: s);
	["vibHz", vibHz, vibMul ,filterNum, filterNum.source.value].postln;
	mod = SinOsc.kr(vibHz, mul:vibMul*freq);//.scope();
	filterFreq = freq + (bpFreq* freq/2) + mod;
	//filter = MoogFF;//[MoogFF, RLPF, Resonz, MoogVCF , MoogLadder][filterNum.source];
	sig =  MoogVCF.ar(sig, filterFreq , bpWid); //MoogFF, RLPF, Resonz, MoogVCF (good), MoogLadder
	sig = sig * env * amp * vel;
	Out.ar(0,sig);
}).add
)
~vibHz=4