
SynthDef(\thereminFollow, { |in, out, gain|
	var sig, amp, freq, hasFreq, sound;
	// sig = Mix.new(SoundIn.ar([0, 1]));
	sig = In.ar(in,2);
	amp = Amplitude.kr(sig, 0.05, 0.05);
	# freq, hasFreq = Pitch.kr(sig, ampThreshold: 0.02, median: 7);
	sound = Mix.new(VarSaw.ar(freq * [0.5, 1, 2], 0, LFNoise1.kr(0.3, 0.1, 0.1), amp));
	6.do {
		sound = AllpassN.ar(sound, 0.040, [0.040.rand,0.040.rand], 2) * gain
	};
	Out.ar(out, sound);
}).add;