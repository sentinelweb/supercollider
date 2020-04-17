(
SynthDef('kickdrum', {

    var osc, env, output;

    osc = {SinOsc.ar(60)};
    env = {Line.ar(1, 0, 1, doneAction: 2)};

    output = osc * env;

    Out.ar(0,
        Pan2.ar(output, 0)
    )

}).send(s);
)

t = Synth('kickdrum');

// this is a bit worse than the first one !!
(
SynthDef('fullkickdrum', {

	var subosc, subenv, suboutput, clickosc, clickenv, clickoutput;

	subosc = {SinOsc.ar(60)};
	subenv = {Line.ar(1, 0, 1, doneAction: 2)};

	clickosc = {LPF.ar(WhiteNoise.ar(1),1500)};
	clickenv = {Line.ar(1, 0, 0.02)};

	suboutput = (subosc * subenv);
	clickoutput = (clickosc * clickenv);

	Out.ar(0,
		Pan2.ar(suboutput + clickoutput, 0)
	)

}).send(s);
)

t = Synth('fullkickdrum');

//////////////////////////////
// https://sccode.org/1-4WI
//////////////////////////////

/* ----------------------
   Synthetic bass drum
   ---------------------- */
~bass = {
	arg amp=0.5;
	{
		var amp_env, phase_env, phase, freq, dur;

		freq = 50.rand + 40;
		dur = 0.25;

		amp_env   = EnvGen.ar(Env.perc(1e-6,dur), doneAction:2);
		phase_env = EnvGen.ar(Env.perc(1e-6,0.125));

		phase = SinOsc.ar(20,0,pi) * phase_env;
		SinOsc.ar([freq,1.01*freq],phase) * amp_env * amp;
	}
}

~bass.value.play;



/* ----------------------
   Synthetic snare
   ---------------------- */


~snare = {
	arg amp=0.5;
	{
		var amp_env, cut_freq, dur;

		cut_freq = 3000;
		dur = [0.0625, 0.125, 0.25].choose;

		amp_env = EnvGen.ar(Env.perc(1e-6, dur), doneAction:2);
		LPF.ar( {WhiteNoise.ar(WhiteNoise.ar)}.dup * amp_env, cut_freq ) * amp;
	}
}

~snare.value.play;



/* ----------------------
   Synthetic hi-hat
   ---------------------- */


~hat = {
	arg amp=0.5;
	{
		var amp_env, cut_freq, dur;

		cut_freq = 6000;
		dur = [0.0625, 0.125, 0.25].choose;

		amp_env = EnvGen.ar(Env.perc(1e-7, dur), doneAction:2);
		HPF.ar( {WhiteNoise.ar}.dup * amp_env, cut_freq ) * amp / 4;
	}
}

~hat.value.play;


/* ------------------------
   Simple 8-step sequencer
   ------------------------ */

~player = {
	arg beat_list, synth;
	{
		arg i;
		var amp = beat_list.wrapAt(i);
		if( amp>0, { synth.value(amp).play } );
	}
}

~bd_player = ~player.value([1, 1, 0, 0.1, 0.5, 0, 0, 1], ~bass).play;
~sn_player = ~player.value([1, 0.1, 0.75, 0, 0.175, 0, 1, 0.5], ~snare);
~hh_player = ~player.value([1, 0.1, 0.1, 1, 0.25, 0.1, 0.75, 0.5], ~hat);


(
c = TempoClock.new(1);
~swing = 0.3; // swing amount
~times = [1 + ~swing, 1 - ~swing, 1 + ~swing, 1 - ~swing]; // add swing
{
	inf.do{
		arg i;
		~bd_player.value(i);
		~sn_player.value(i);
		~hh_player.value(i);

		~times.wrapAt(i).wait;
	};

}.fork(c);
)

c.tempo = 6;

c.stop
~bd_player = ~player.value([0], ~bass);
~sn_player = ~player.value([0], ~snare);
~hh_player = ~player.value([0], ~hat);
