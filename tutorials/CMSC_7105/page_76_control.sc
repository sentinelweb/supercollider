(
// Double click the parenthesis above to quickly select
// the entire patch
// Or use com-shift-b
{
var out, delay;
out = SinOsc.ar( // Sine wave osc
	abs( // This protects against negative values
		LFNoise1.kr(
		0.5, // frequency overall wandering
		600, // range of overall wandering
		LFSaw.kr(
			1.5, // speed of the individual sweeps
			mul: 50, // depth of sweep
			add: 500 // range of sweep
			)
		)
	),
	0,
	0.1 // volume, stay below 0.2
); // delay
delay = CombN.ar(out,
	0.1, // max delay -
	[1.35, 0.7], // actual delay, stay below max delay
	6 // delay decay
);
Pan2.ar(out, 0) + delay
}.play
)

// Second patch. You can run them at the same time, or several // instances of the same patch.
(
// <- double click the parenthesis
{
Mix.ar(
	Array.fill(5, // not too many values, could crash
			{Pan2.ar(
		SinOsc.ar(SinOsc.ar(1/10, rrand(0, 6.0), 200, 500)),
		1.0.rand)} )
)*0.02
}.play
)

// This one controls the three dimensions of sound: pitch, amp, and timbre.
(
{
	var trig, out, delay;
	trig = Impulse.kr(6);
	out = Blip.ar(
		TRand.kr(48, 72, trig).midicps, TRand.kr(1, 12, trig),
		max(0, TRand.kr(-0.5, 0.4, trig))
	);
	out = Pan2.ar(out, TRand.kr(-1.0, 1.0, trig));
	out = out*EnvGen.kr(Env.perc(0, 1), trig);
	out = Mix.ar({out}.dup(6))*0.2;
	delay = CombL.ar(out, 2.0, 4/6, 6);
	Out.ar(2, out + delay)
}.play
)

// OK, one more.
(
SynthDef("player4",{
	Mix.ar(	Array.fill(5,
		{arg c;
		SinOsc.ar(
			LFSaw.ar((c*0.2 + 1)/3, mul: 500, add: 700)
			)
		}
	)
	)*0.1
})

)
(
var player4;
player4 = Synth("player4");
player4.play()
)
