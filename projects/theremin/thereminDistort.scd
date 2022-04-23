/// notes /////////////////
// IEnvGen - could be used for remappig freq response of theremin

//// init below first (code) /////////////
(
~thereminEffectsGrp = Group.after(~thereminInGrp);
~thereminDistortion = Synth(\thereminDistortion,[\in, ~thereminBus, \out, 0], ~thereminEffectsGrp);
~thereminDistortion.set(\tempo, 125);
)
~thereminDistortion.free;
//////// synth - distort ////////////////
(
~state = (
	clip: (level:1, sat:0)
);
~makeDistortionTable = {
	var level = ~state[\clip][\level], sat = ~state[\clip][\sat];
	~tf = Env(levels:[-1*level,0,level],times:[1,1], curve:[sat,-1*sat]);
	~tfTable = ~tf.asSignal(1024).asWavetableNoWrap; // use with Shaper
	(~tfBuf != nil).if { ~tfBuf.free; };
	// todo ping-pong buffer allocation to stop clicking
	~tfBuf = Buffer.loadCollection(s, ~tfTable)
};
~makeDistortionTable.value();

SynthDef(\thereminDistortion, {
	arg in=0, out=0, gain=1, tempo=120, clip=1, bpfSweepRatio=0.1, bpfRecipQ=0.5, transMix = -1, transRatio=1, transWidth=1;
	var sig, delay, clipamp, test, trans, freq, hasFreq;
	// sig = SoundIn.ar([in, in+1]);
	sig = SoundIn.ar(in);
	sig = HPF.ar(HPF.ar(sig, 100), 20);
	# freq, hasFreq = Pitch.kr(sig, ampThreshold: 0.02, median: 7);
	(freq/1000).scope(\freq);
    clipamp = Amplitude.kr(sig, 0.05, 0.05);
	// distort
	sig = Shaper.ar(~tfBuf, sig);
	// not working .. why?
	freq = freq.clip(20, 10000); // RemoveBadValues // Gate.kr(freq, hasFreq)
	sig = BPF.ar(sig, SinOsc.kr(tempo / 60, mul: freq * bpfSweepRatio, add: freq), bpfRecipQ);
	trans = EnvGen.ar(Env.asr(0.01, 0.5, 0.01, curve: 'sin'), LFPulse.kr(tempo / 60 * transRatio, width: transWidth));
	sig = XFade2.ar(sig, sig * trans, transMix);
	sig = (sig * gain)!2;
	test = sig; test.scope(\distort);
	Out.ar(out, sig);
}).add;
)

/////// midi ////////////////////////////////
(
~apc = AkaiAPC40();
~apc.addCtlIn(\s1, {~thereminDistortion.set(\gain, ~val.linexp(0, 127, 0.001, 50))});
// ~apc.addCtlIn(\k1, {~thereminDistortion.set(\clip, ~val.linexp(0, 127, 0.01, 1))});
~apc.addCtlIn(\k1, {
	~state[\clip][\level] = ~val.linlin(0, 127, 0, 1);
	~makeDistortionTable.value();
});
~apc.addCtlIn(\sk1, {~thereminDistortion.set(\transWidth, ~val.linexp(0, 127, 0.05, 1))});
~apc.addCtlIn(\sk2, { ~thereminDistortion.set(\transMix, ~val.linlin(0, 127, -1, 1))});
~apc.addCtlIn(\sk3, { ~thereminDistortion.set(\bpfSweepRatio, ~val.linexp(0, 127, 0.01, 1).postln)});
~apc.addCtlIn(\sk4, { ~thereminDistortion.set(\bpfRecipQ, ~val.linexp(0, 127, 0.01, 1).postln)});
~apc.addCtlIn(\sk5, {
	~state[\clip][\sat] = ~val.linexp(0, 127, 0.1, 700);
	~makeDistortionTable.value();
});
~apc.addNoteIn(\grid11, {~thereminDistortion.set(\transRatio, 1);~apc.update;});
// ~apc.addNoteOut(\grid11, { if (~thereminDistortion.get(\transRatio).value==1) {\yellow}{\off}});
~apc.addNoteIn(\grid12, {~thereminDistortion.set(\transRatio, 2);~apc.update;});
// ~apc.addNoteOut(\grid12, { if (~thereminDistortion.get(\transRatio).value==2) {\yellow}{\off}});
~apc.addNoteIn(\grid13, {~thereminDistortion.set(\transRatio, 4);~apc.update;});
// ~apc.addNoteOut(\grid13, { if (~thereminDistortion.get(\transRatio).value==4) {\yellow}{\off}});
~apc.addNoteIn(\grid14, {~thereminDistortion.set(\transRatio, 8);~apc.update;});
// ~apc.addNoteOut(\grid14, { if (~thereminDistortion.get(\transRatio).value==8) {\yellow}{\off}});
~apc.addNoteIn(\grid15, {~thereminDistortion.set(\transRatio, 16);~apc.update;});
// ~apc.addNoteOut(\grid15, { if (~thereminDistortion.get(\transRatio).value==16) {\yellow}{\off}});
)

///// testing /////////////////////////////
// q1: how to get the valiue in a function
~testVal = {|v| var s=1; ~thereminDistortion.get(\clip, {|a| s = a;});s;}
~testVal.value;
(1==1).if(2,3)
~thereminDistortion.set(\gain, 10);
~thereminDistortion.set(\clip, 0.04);
~thereminDistortion.set(\transRatio, 4);
~thereminDistortion.set(\transWidth, 0.5);
~thereminDistortion.set(\bpfSweepRatio, 2000);
~thereminDistortion.set(\bpfOscFreq, 1000);
~thereminDistortion.set(\bpfRecipQ, 20);
~thereminDistortion.get(\bpfOscFreq,{|a|postln(a);});
~thereminDistortion.free;

// eli waveshaping tut 1
(
~level = 0.8;
~curve = 0;
~tf = Env(levels:[-1*~level,0,~level],times:[1,1],curve:[~curve,-1*~curve]);
~tf.plot;
~tfTable = ~tf.asSignal(1024).asWavetableNoWrap; // use with Shaper
~tfBuf = Buffer.loadCollection(s, ~tfTable)
)
{Shaper.ar(~tfBuf, SinOsc.ar(400))*0.2!2}.play;
