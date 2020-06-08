

// setup ///////////
(
Server.default.options.inDevice_("UMC404HD 192k");
Server.default.options.outDevice_("Built-in Output");// UMC404HD 192k <- weird crackling ...q
Server.default.options.blockSize = 512;
s.boot;
// ServerOptions.inDevices;
 ServerOptions.outDevices;
~thereminBus = Bus.audio(s,2);
)

// tools //////
s.plotTree
// synths ///////////////
(
SynthDef(\thereminInput, {
	arg inamp = 3, out = 0;
	var sig;
	sig = In.ar(2,[3]) ! 2  * inamp;
	//sig.scope;
	Out.ar(out, sig);
}).add;
~thereminInGrp = Group.new;
)
//////// inputs testing ////////////////////////
{ In.ar(2,[3]) }.play; // input 1
{ In.ar(2,[4]) }.play; // input 2
{ In.ar(2,[5]) }.play; // input 3
{ In.ar(2,[6]) }.play; // input 4

/*var buffer = Buffer.alloc(s, 1024, 1);
	var chain = FFT(buffer, in);*/


// pulse width modulation
(
{ LFPulse.ar(100,0,MouseY.kr(0,1),0.1) }.scope(1, zoom: 4);
{ LFPulse.ar(100,0,LFTri.kr(0.2,0,0.5,0.5),0.1) }.scope(1, zoom: 4);
)

{ LPF.ar(Saw.ar(200,0.1), SinOsc.kr(XLine.kr(0.7,300,20),0,3600,4000)) }.play;
{ SinOsc.ar(300, 0, MouseX.kr(0.1,80,1)).distort * 0.2 }.scope(1);
{ SinOsc.ar(300, 0, MouseX.kr(0.1,80,1)).clip2(1) * 0.2 }.scope(1);

{SinOsc.ar(300)*EnvGen.ar(Env.asr(0.01, 0.5, 0.01, 1,curve: 'sin'),LFPulse.ar(8, width: 0.5))}.play