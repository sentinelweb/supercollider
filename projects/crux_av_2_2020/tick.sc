// crux aleton link Jam patch
// todo
// - have a preview channels and an output channel (both stereo) - use soundcard as main and inbuilt as preview
// -

s.boot;

Link.enable

(
Ndef(\foo, {
	// var gate1 = LinkLane.kr(4, 8, [0,2,4,5,7]);
	var gate1 = LinkLane.kr(8, 16, [0,2,4,5,7,12,13,14]);
	var freq1 = MouseX.kr(20,80).midicps;
	var sig1 = PMOsc.ar(freq1, freq1*0.5, MouseY.kr(0.2,5), 3.14157/6.0, EnvGen.kr(Env.perc(0.0, 0.5, 0.3), gate1)) ! 2;

	var sig2 = { LPF.ar(sig1.distort, MouseX.kr(1e2,2e4,1), 3) };

	sig1 * 0 + sig2 * 1;

	//var out  = Out.ar(sig1, sig1);

	//Pan2.ar(SinOsc.ar(100,0, EnvGen.kr(Env.perc(0.0,0.4,0.3), LinkTrig.kr(2))))
}).play
)
ServerOptions.outDevices

(
s.boot.doWhenBooted{
b = Buffer.alloc(s, 1024, 1);
c = Buffer.read(s,"/Users/robert/Dropbox/music/samples/Drum Samples/Visco SpaceDrum/BASSDRUM/Bassdrum-01.wav");
}
)

Link.enable
// spectral delay - here we use a DelayN UGen to delay the bins according to MouseX location (from )
(
Ndef(\bass, {
	var in, chain, v;
	var gate1 = LinkLane.kr(8, 16, [0,4,8,12]);

	in = PlayBuf.ar(1, c, BufRateScale.kr(c), trigger: gate1);
	chain = FFT(b, in);

	v = MouseX.kr(0.1, 1);

	chain = chain.pvcollect(b.numFrames, {|mag, phase, index|
		mag + DelayN.kr(mag, 1, v);
	}, frombin: 0, tobin: 256, zeroothers: 1);

	Out.ar(0, 0.5 * IFFT(chain).dup);
}).play(s);
)

{ SinOsc.ar(300, 0, MouseX.kr(0.1,80,1)).distort * 0.2 }.scope(1);