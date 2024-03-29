(

SynthDef(\prayer_bell, { |outbus, t_trig = 1, sing_switch = 0, freq = 2434, amp = 0.5, decayscale = 1, lag = 10, i_doneAction = 0, gate=1|
	var sig, input, first, freqscale, mallet, sing;
	freqscale = freq / 2434;
	freqscale = Lag3.kr(freqscale, lag);
	decayscale = Lag3.kr(decayscale, lag);

	mallet = LPF.ar(Trig.ar(t_trig, SampleDur.ir)!2, 10000 * freqscale);
	sing = LPF.ar(
		LPF.ar(
			{
				PinkNoise.ar * Integrator.kr(sing_switch * 0.001, 0.999).linexp(0, 1, 0.01, 1)
			} ! 2,
			2434 * freqscale
		) + Dust.ar(0.1), 10000 * freqscale
	) * LFNoise1.kr(0.5).range(-45, -30).dbamp;
	input = mallet + (sing_switch.clip(0, 1) * sing);


	sig = DynKlank.ar(`[
		[
			(first = LFNoise1.kr(0.5).range(2424, 2444)) + Line.kr(20, 0, 0.5),
			first + LFNoise1.kr(0.5).range(1,3),
			LFNoise1.kr(1.5).range(5435, 5440) - Line.kr(35, 0, 1),
			LFNoise1.kr(1.5).range(5480, 5485) - Line.kr(10, 0, 0.5),
			LFNoise1.kr(2).range(8435, 8445) + Line.kr(15, 0, 0.05),
			LFNoise1.kr(2).range(8665, 8670),
			LFNoise1.kr(2).range(8704, 8709),
			LFNoise1.kr(2).range(8807, 8817),
			LFNoise1.kr(2).range(9570, 9607),
			LFNoise1.kr(2).range(10567, 10572) - Line.kr(20, 0, 0.05),
			LFNoise1.kr(2).range(10627, 10636) + Line.kr(35, 0, 0.05),
			LFNoise1.kr(2).range(14689, 14697) - Line.kr(10, 0, 0.05)
		],
		[
			LFNoise1.kr(1).range(-10, -5).dbamp,
			LFNoise1.kr(1).range(-20, -10).dbamp,
			LFNoise1.kr(1).range(-12, -6).dbamp,
			LFNoise1.kr(1).range(-12, -6).dbamp,
			-20.dbamp,
			-20.dbamp,
			-20.dbamp,
			-25.dbamp,
			-10.dbamp,
			-20.dbamp,
			-20.dbamp,
			-25.dbamp
		],
		[
			20 * freqscale.pow(0.2),
			20 * freqscale.pow(0.2),
			5,
			5,
			0.6,
			0.5,
			0.3,
			0.25,
			0.4,
			0.5,
			0.4,
			0.6
		] * freqscale.reciprocal.pow(0.5)
	], input, freqscale, 0, decayscale);
	// DetectSilence.ar(sig, doneAction: i_doneAction);
	sig = sig * EnvGen.kr(Env.adsr(2,1,1,10), gate, doneAction:2) * amp;
	Out.ar(outbus, sig);
}).add;

/* ----------------------
Synthetic triangle
---------------------- */
SynthDef(\tri, {
	arg amp = 0.5, dura = 0.25, freq = 50, metal = 1.1, out = 0 ;
	var amp_env, phase_env, phase, sig;

	amp_env   = EnvGen.ar(Env.perc(1e-6,dura), doneAction:2);
	phase_env = EnvGen.ar(Env.perc(1e-6,0.125));

	phase = SinOsc.ar(20,0,pi) * phase_env;
	sig = SinOsc.ar([freq, metal*freq], phase) * amp_env * amp;

	Out.ar(out, sig);
}).add;

~meditationLength = 60; //min
~timeQuant = 60; //sec
~bowlsSeq = Pdef(\bowls,
	Pmono(\prayer_bell,
		\dur, ~timeQuant*5,
		\midinote, Pseq([32, 37, 32, 39]+7, inf),
		\sing_switch,0,
		\amp,0.5,
		\lag,0
	)
);

~triSeq = Pdef(\tri, Pbind(
	\instrument, \tri,
	\dur, ~timeQuant,
	\amp, 0.05,
	\midinote, Pseq([ Rest(), 100, 102, 100, 102]+2, inf),
	\dura, 2, \metal, 1.003)
);

~endSeq = Pdef(\end, Pbind(\instrument, \tri,
	\dur, ~timeQuant * ~meditationLength,
	\amp, 0.5,
	\midinote, Pseq([ Rest(), 110], inf),
	\dura, 10,
	\metal, 1.003)
);

~bowlsSeq.play;
~triSeq.play;
~endSeq.play;
)

/// test //////
// 32, 37, 39
~bowl = Synth(\prayer_bell, [\freq, 34.midicps, \amp, 0.5, \lag, 0, \trig, 1, \sing_switch, 0, \decayscale, 1] )
~bowl.set(\gate, 0)
~bowl.free

~triangle = Synth.new(\tri,[\freq, 110.midicps, \dura, 1, \metal, 1.003, \dura:10]);