/// notes /////////////////
// IEnvGen - could be used for remappig freq response of theremin
// hold and grab make a button press to save freq then wait until
// had freq reaches it to unloick it from that freq

//// init below first (code) /////////////
(
~thereminEffectsGrp = Group.after(~thereminInGrp);
~thereminDistortion = Synth(\thereminDistortion,[\in, ~thereminBus, \out, 0/*,\prv, 2*/], ~thereminEffectsGrp);
~thereminDistortion.set(\tempo, 125);
)
~thereminDistortion.free;
~thereminDistortion.set(\tempo, 119.73);
//////// synth - distort ////////////////
(
~state = (
	clip: (level:1, sat:0)
);
~makeDistortionTable = {
	var level = ~state[\clip][\level], sat = ~state[\clip][\sat];
	~tf = Env(levels:[-1*level,0,level], times:[1,1], curve:[sat,-1*sat]);
	~tfTable = ~tf.asSignal(1024).asWavetableNoWrap; // use with Shaper
	(~tfBuf != nil).if { ~tfBuf.free; };
	// todo ping-pong buffer allocation to stop clicking
	~tfBuf = Buffer.loadCollection(s, ~tfTable)
};
~makeDistortionTable.value();

SynthDef(\thereminDistortion, {
	arg in=0, out=0, gain=1, /*prv=0, previewGain=1, */tempo=120, bpfSweepRatio=0.1, bpfRecipQ=0.5, transMix = -1, transRatio=1, transWidth=1, bpfFreqMul=2, rvbMix=0, rvbRoom=0, rvbDamp = 0;
	var sig, delay, clipamp, test, trans, freq, hasFreq, bpfFreq;
	sig = SoundIn.ar(in);
	sig = HPF.ar(HPF.ar(sig, 100), 20);
	# freq, hasFreq = Pitch.kr(sig, ampThreshold: 0.02, median: 7);
	freq = freq.clip(20, 10000); // RemoveBadValues // Gate.kr(freq, hasFreq)
	(freq/1000).scope(\freq);
    clipamp = Amplitude.kr(sig, 0.05, 0.05);
	// distort
	// sig = sig.clip2(~state[\clip][\level]);
	sig = Shaper.ar(~tfBuf, sig);
	// todo offset freq
	bpfFreq = SinOsc.kr(tempo / 60, mul: freq * bpfSweepRatio, add: freq*bpfFreqMul);
	sig = BPF.ar(sig ,bpfFreq, bpfRecipQ);
	trans = EnvGen.ar(Env.asr(0.01, 0.5, 0.01, curve: 'sin'), LFPulse.kr(tempo / 60 * transRatio, width: transWidth));
	sig = sig !2;
	sig = XFade2.ar(sig, sig * trans, transMix);
	// apply reverb
	sig = FreeVerb2.ar(sig[0], sig[1], rvbMix, rvbRoom, rvbDamp);
	test = sig; test.scope(\distort);
	Out.ar(out, sig * gain);
	// Out.ar(prv, sig * previewGain);
}).add;
)

/////// midi ////////////////////////////////
(
(~apc != nil).if {~apc.reset();};
~apc = AkaiAPC40();
~apc.addCtlIn(\master, {~thereminDistortion.set(\gain, ~val.linexp(0, 127, 0.001, 50))});
~apc.addCtlIn(\cue, {~thereminDistortion.set(\previewGain, ~val.linexp(0, 127, 0.001, 50))});
~apc.addCtlIn(\k1, {
	~state[\clip][\level] = ~val.linlin(0, 127, 0, 1);
	~makeDistortionTable.value();
});
~apc.addCtlIn(\sk1, {~thereminDistortion.set(\transWidth, ~val.linexp(0, 127, 0.05, 1))});
~apc.addCtlIn(\sk2, { ~thereminDistortion.set(\transMix, ~val.linlin(0, 127, -1, 1))});
~apc.addCtlIn(\sk3, { ~thereminDistortion.set(\bpfSweepRatio, ~val.linexp(0, 127, 0.01, 1))});
~apc.addCtlIn(\sk4, { ~thereminDistortion.set(\bpfRecipQ, ~val.linexp(0, 127, 0.05, 1))});
~apc.addCtlIn(\sk5, {
	~state[\clip][\sat] = ~val.linexp(0, 127, 0.1, 700);
	~makeDistortionTable.value();
});
~apc.addCtlIn(\sk6, { ~thereminDistortion.set(\rvbMix, ~val.linlin(0, 127, 0, 1))});
~apc.addCtlIn(\sk7, { ~thereminDistortion.set(\rvbRoom, ~val.linlin(0, 127, 0, 1))});
~apc.addCtlIn(\sk8, { ~thereminDistortion.set(\rvbDamp, ~val.linlin(0, 127, 0, 1))});

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
