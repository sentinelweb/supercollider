// setup ///////////
(
Server.default.options.inDevice_("TR-8S");
Server.default.options.outDevice_("TR-8S");
//Server.default.options.inDevice_("UMC404HD 192k");
//Server.default.options.outDevice_("UMC404HD 192k");// weird clicking :(
// Server.default.options.outDevice_("MacBook Pro Speakers");
// Server.default.options.outDevice_("External Headphones");
Server.default.options.blockSize = 512;
Server.default.options.sampleRate = 44100;
s.boot;
ServerOptions.inDevices;
ServerOptions.outDevices;
~thereminBus = Bus.audio(s,2);

MIDIdef.freeAll;
MIDIClient.init;
MIDIClient.sources;
MIDIIn.connect(2, MIDIClient.sources.at(2));//MIDIEndPoint("USB Oxygen 8 v2", "USB Oxygen 8 v2")
)

// tools //////
s.plotTree
// synths ///////////////
(
SynthDef(\thereminInput, {
	arg inamp = 3, out = 0;//in=3, // todo pass ref?
	var sig;
	sig = In.ar(12,1) ! 2  * inamp;
	Out.ar(out, sig);
}).add;

SynthDef(\ping, {
	arg out=0, gate = 0, amp=0.5;
	var sig;
	sig = EnvGen.ar(Env.asr(0.01, 0.5, 0.01,curve: 'sin'), gate) * SinOsc.ar(440);
	Out.ar(out, sig);
}).add;

MIDIdef.cc(\ccPing,{|val, ctnum, chan|
	["\ccTheremin", val, ctnum, chan].postln;
	c = switch (ctnum)
	{25} {// record button (left)
		if(~pingVal==1,{~pingVal=0},{~pingVal=1});
		~pingVal.postln;
		~ping.set(\gate,~pingVal);
	}

	{"unmapped:"+chan +":"+ ctnum + " -> "+val};
});

~thereminInGrp = Group.new;
(~thereminInput != nil).if { ~thereminInput.free;};
~thereminInput = Synth(\thereminInput,[\out, ~thereminBus,\inamp, 1], ~thereminInGrp);
(~ping != nil).if {~ping.free;};
~ping = Synth(\ping,[\out, 0]);
)

//// commands
~ping.set(\gate,1);
~ping.set(\gate,0);
~pingVal = 1;// for toggle;

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
