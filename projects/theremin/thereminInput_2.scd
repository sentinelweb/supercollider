(
// sometimes there are eathing problems with the mac input sounds is distorted. connecting the headphones output to the speaker fixed it
Server.default.options.inDevice_("UMC404HD 192k");
Server.default.options.blockSize = 512;
Server.default.options.sampleRate = 192000;
Server.default.options.outDevice_("UMC404HD 192k");
// fixme cant get any audio with 4 channels
// Server.default.options.numOutputBusChannels = 4;
Server.default.options.numOutputBusChannels.postln;


s.plotTree;
s.boot;
s.meter;
~thereminBus = Bus.audio(s,2);
SynthDef(\thereminInput, {
	arg inamp = 1, out = 0, in = 0;
	var sig;
	sig = SoundIn.ar(in) ! 2  * inamp;
	sig.scope(\input);
	Out.ar(out, sig);
}).add;

SynthDef(\patch, {|out = 0, in = 0|
	var sig;
	sig = SoundIn.ar(in);
	Out.ar(out, sig);
}).add;
)

(
//(~thereminBus==nil) .if { ~thereminBus = Bus.audio(s,2);};
//  (~thereminVoiceBus == nil) .if { ~thereminVoiceBus = Bus.audio(s,2);};
  (~thereminInGrp != nil).if { ~thereminInGrp.free; };
  (~thereminOutGrp != nil).if { ~thereminOutGrp.free; };
  ~thereminInGrp = Group.new;
  ~thereminOutGrp =  Group.after(~thereminInGrp);

  (~patch != nil).if { ~patch.free; postln("free patch");};
// ~patch =  Synth(\patch, [\out, 0, \in, ~thereminBus], ~thereminOutGrp);

  (~thereminInput != nil).if { ~thereminInput.free; postln("free input");};
  ~thereminInput = Synth(\thereminInput,[\out, ~thereminBus, \inamp, 1], ~thereminInGrp);
)
FreqScope.new(400, 200, 0, server: s);
s.scope;
