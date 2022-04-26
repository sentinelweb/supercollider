//// init below first (code) /////////////
(
~thereminVoiceGrp = Group.after(~thereminInGrp);
~thereminVoice = Synth(\thereminVoice, [\in, ~thereminBus, \out, 0/*,\prv, 2*/], ~thereminVoiceGrp);
~thereminVoice.set(\tempo, 125);
)
~thereminVoice.free;
~thereminVoice.set(\tempo, 119.73);

(
SynthDef(\thereminVoice, {
	arg in=0, out=0, gain=0.2, tempo = 120, width = 0.5, freqScale=1;
	var insig, outsig, test, freq, hasFreq;
	insig = SoundIn.ar(in);
	insig = HPF.ar(HPF.ar(insig, 100), 20);
	# freq, hasFreq = Pitch.kr(insig, ampThreshold: 0.02, median: 7);
	freq = freq.clip(20, 10000);
	freq = freq * freqScale;
	(freq/1000).scope(\freq);
	outsig = LFPulse.ar(freq, width: width) + LFPulse.ar(freq*2, width: width) + LFPulse.ar(freq/2, width: width);
	//outsig = SinOsc.ar(freq) + SinOsc.ar(freq * 2) + SinOsc.ar(freq * 4) + SinOsc.ar(freq / 2)+ SinOsc.ar(freq / 4);
	outsig.scope(\voice);
	Out.ar(out, outsig * gain);
	// Out.ar(prv, sig * previewGain);
}).add;
)

(
(~apc != nil).if {~apc.reset();};
~apc = AkaiAPC40();
~apc.addCtlIn(\master, {~thereminVoice.set(\gain, ~val.linexp(0, 127, 0.001, 50))});
~apc.addCtlIn(\k1, {~thereminVoice.set(\width, ~val.linlin(0, 127, 0.001, 0.999))});
~apc.addCtlIn(\sk1, {~thereminVoice.set(\freqScale, ~val.linexp(0, 127, 0.01, 100))});
)