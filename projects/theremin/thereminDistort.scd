//// init below first (code) /////////////
(
~thereminEffectsGrp = Group.after(~thereminInGrp);
~thereminDistortion = Synth(\thereminDistortion,[\in, ~thereminBus, \out, 0], ~thereminEffectsGrp);
~thereminDistortion.set(\tempo, 125);
)
~thereminDistortion.free;
//////// synth - distort ////////////////
(
SynthDef(\thereminDistortion, {
	arg in=0, out=0, gain=1, tempo=120, clip=1, bpfOscFreq=1, bpfSweepRatio=0.1, bpfRecipQ=1, transMix = -1, transRatio=1, transWidth=1;
	var sig, delay, clipamp, test, trans, freq, hasFreq;
	sig = SoundIn.ar([in, in+1]);
	// sig = HPF.ar(HPF.ar(sig, 100), 20);
	//# freq, hasFreq = Pitch.kr(sig, ampThreshold: 0.02, median: 7);
    clipamp = Amplitude.kr(sig, 0.05, 0.05);
	sig = sig.clip2(clip) ;//* clipamp / clip;
	//sig = BPF.ar(sig, SinOsc.kr(tempo / 60, mul: freq * bpfSweepRatio, add: freq), bpfRecipQ);
	trans = EnvGen.ar(Env.asr(0.01, 0.5, 0.01, curve: 'sin'), LFPulse.kr(tempo / 60 * transRatio, width: transWidth));
	sig = XFade2.ar(sig, sig * trans, transMix);
	sig = Pan2.ar(sig, 0.5) * gain;
	test = sig; test.scope;
	Out.ar(out, sig);
}).add;
)

/////// midi ////////////////////////////////
(
~apc = AkaiAPC40();
~apc.addCtlIn(\s1,{~thereminDistortion.set(\gain, ~val.linexp(0, 127, 0.001, 50))});
~apc.addCtlIn(\k1,{~thereminDistortion.set(\clip, ~val.linexp(0, 127, 0.01, 1))});
~apc.addCtlIn(\sk1,{~thereminDistortion.set(\transWidth, ~val.linexp(0, 127, 0.05, 1))});
~apc.addCtlIn(\sk2, { ~thereminDistortion.set(\transMix, ~val.linlin(0, 127, -1, 1))});
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
~thereminDistortion.set(\bpfRecipQ, 200);
~thereminDistortion.get(\bpfOscFreq,{|a|postln(a);});
~thereminDistortion.free;