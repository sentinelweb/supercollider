s.boot;
// theremin input
(
Ndef(\theremin, {

	var in = In.ar(2,[3]) ! 2  * 4;
	var hpf = HPF.ar(HPF.ar(in, 200),20);
	// var distorted = filtered.clip2(0.1)*20;
	// var lpf = LPF.ar(distorted, 1000);
	var buffer = Buffer.alloc(s, 1024, 1);
	var chain = FFT(buffer, in);
	var out = hpf;
	// create a new analyzer
	FreqScope.new(400, 200, 0, server: s);

	Out.ar(0, out);
	// var gate1 = LinkLane.kr(4, 8, [0,2,4,5,7]);
	// var gate1 = LinkLane.kr(8, 16, [0,2,4,5,7,12,13,14]);
	// var freq1 = MouseX.kr(20,80).midicps;
	// var sig1 = PMOsc.ar(freq1, freq1*0.5, MouseY.kr(0.2,5), 3.14157/6.0, EnvGen.kr(Env.perc(0.0, 0.5, 0.3), gate1)) ! 2;
	//
	// var sig2 = { LPF.ar(sig1.distort, MouseX.kr(1e2,2e4,1), 3) };
	//
	// sig1 * 0 + sig2 * 1;

	//var out  = Out.ar(sig1, sig1);

	//Pan2.ar(SinOsc.ar(100,0, EnvGen.kr(Env.perc(0.0,0.4,0.3), LinkTrig.kr(2))))
}).play(s)
)

//////// dust ////////////////////////////////////////////////////////////////
(
// Dust randomly triggers Decay to create an exponential
// decay envelope for the WhiteNoise input source
Ndef(\dust, {
	var z = Decay.ar(Dust.ar(1,0.5), 0.3, WhiteNoise.ar);
	var out = DelayN.ar(z, 0.2, 0.2, 1, z); // input is mixed with delay via the add input
	Out.ar(0, out);
}).play(s)
)

// 3) ========= Bell synthesis ==========

// let's make a bell sound using subtractive synthesis
(
Ndef(\bells,{
var chime, freqSpecs, burst, harmonics = 10;
var burstEnv, burstLength = 0.001;

freqSpecs = `[
	{rrand(2000, 2100)}.dup(harmonics), //freq array
	{rrand(0.3, 1.0)}.dup(harmonics).normalizeSum, //amp array
	{rrand(3.0, 20.0)}.dup(harmonics)]; //decay rate array

burstEnv = Env.perc(0, burstLength); //envelope times
burst = PinkNoise.ar(EnvGen.kr(burstEnv, gate: Impulse.kr(4))*0.3); //Noise burst

Klank.ar(freqSpecs, burst)
}).play
)
