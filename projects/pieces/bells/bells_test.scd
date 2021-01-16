// https://sccode.org/1-4W8
SynthDef(\risset2, {|out = 0, pan = 0, freq = 400, amp = 0.1, att = 0.005, rel = 2, gate = 1|
		var amps = #[1, 0.67, 1, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33, 1, 1.33];
		var durs = #[1, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075];
		var frqs = #[0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2, 2.74, 3, 3.76, 4.07];
		var dets = #[0, 1, 0, 1.7, 0, 0, 0, 0, 0, 0, 0];
		var doneActionEnv = EnvGen.ar(Env.linen(0, att+rel, 0), gate, doneAction: 2);
		var src = Mix.fill(11, {|i|
			var env = EnvGen.ar(Env.perc(att, rel * durs[i], amps[i], att.explin(0.005, 4, -4.5, 0)), gate);
			SinOsc.ar(freq*frqs[i] + dets[i], 0, amp*env);
		});
		src = src * doneActionEnv * 0.5; // make sure it releases node after the end.
		Out.ar(out, Pan2.ar(src, pan));
	}).add;

	FreqScope.new

~risset = Synth(\risset2, [\freq , 10000,])


///////////////////////////////////////////////////////////////////////////////////
https://sccode.org/1-5ay
// 1. define the synth
(
SynthDef(\bell, {
	|fs=1, t60=1, pitchy=1, amp=0.25, gate=1, exatt = 0.001, exsus=1, exrel=0.05 |
	var sig, exciter;
	//exciter = Impulse.ar(0);
	//exciter = WhiteNoise.ar() * EnvGen.ar(Env.perc(exatt,  exrel), gate) * 0.25;
	// exciter = WhiteNoise.ar() * EnvGen.ar(Env.linen(att, sus, rel), gate) * 0.25;
	exciter = SinOsc.ar(10, 0.25, 1) * EnvGen.ar(Env.linen(exatt, exsus, exrel), gate) * 0.25;

	sig = Klank.ar(
		`[
			[1, 2, 2.803, 3.871, 5.074, 7.81, 10.948, 14.421],   // freqs
			[1, 0.044, 0.891, 0.0891, 0.794, 0.1, 0.281, 0.079], // amplitudes
			[1, 0.205, 1, 0.196, 0.339, 0.047, 0.058, 0.047]*t60     // ring times
		],
		exciter,
		freqscale:fs * pitchy);
	sig = FreeVerb.ar(sig) * amp;
	DetectSilence.ar(sig, 0.001, 0.5, doneAction:2);
	Out.ar(0, sig!2);
}).add
)


// 2. Test a single note
x = Synth(\bell, [\fs, 60.midicps, \t60, 9.177, \pitchy, 8]);


// 3. Test different textures

// glokenspiel
(
Pbind(
	\instrument, \bell,
	\fs, Pseq( (60..72), 1).midicps,
	\t60, 6,
	\pitchy, 4,
	\dur, 0.25
).play;
)

// my attempt - gong try for tibetan singing bowl
(
Pbind(
	\instrument, \bell,
	\fs, Pseq( [10,12,15,10,15,12,15,12], 1).midicps,
	\t60, 40,
	\att, 10,
	\sus, 10,
	\rel, 5,
	\pitchy, 4,
	\dur, 2
).play;
)

// tubular bells
(
Pbind(
	\instrument, \bell,
	\fs, Pseq( (60..72), 1).midicps,
	\t60, 9,
	\pitchy, 1,
	\dur, 1
).play;
)

// xilophone
(
Pbind(
	\instrument, \bell,
	\fs, Pseq( (60..72), 1).midicps,
	\t60, 1,
	\pitchy, 4,
	\dur, 0.25
).play;
)

// marimba
(
Pbind(
	\instrument, \bell,
	\fs, Pseq( (60..72), 1).midicps,
	\t60, 0.5,
	\pitchy, 1,
	\dur, 0.25
).play;
)

//////////////////////////////////////////////////////////
IDEAS
Make one bell go for 5 mins and have a warble with the breath rhythm

https://sccode.org/1-4VL
//«Tibetan prayer bells» by wondersluyter
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
        PinkNoise.ar * Integrator.kr(sing_switch * 0.001, 0.999).linexp(0, 1, 0.01, 1) * amp
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
	sig = sig * EnvGen.kr(Env.adsr(2,1,1,10), gate, doneAction:2);
  Out.ar(outbus, sig);
}).add;
)

~bowl = Synth(\prayer_bell, [\freq,120,\amp,0.1,\lag,0,\trig,1,\sing_switch,0, \decayscale, 3] )
~bowl.set(\gate, 0)
~bowl.free

~bowlsSeq = Pdef(\bowls,
	Pmono(\prayer_bell,
		\dur, 15,
		\freq, Pseq([120, 240, 360, 440], inf),
		\sing_switch,1,
		\amp,0.3
)
)
~bowlsSeq.play
~bowlsSeq.stop

(
~bowlsSeqOrig = Pdef(\bell_1,
  Pmono(\prayer_bell,
    \dur, Pseq([8, 20], inf),
    \freq, Pseq([2500, 500], inf),
    \amp, 0.5,
    \lag, 0,
    \trig, Pseq([0.1], inf) * Pwhite(0.5, 1, inf) * Pwrand([0, 1], [1, 5].normalizeSum, inf),
    \sing_switch, Pseq((0!4) ++ (1!4), inf)
  )
)
)
~bowlsSeqOrig.play
~bowlsSeqOrig.stop