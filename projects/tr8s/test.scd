MIDIClient.init();
~indexOfTr8s = MIDIClient.sources.detectIndex({arg ep; ep.name.contains("TR-8S")});
MIDIIn.connect(~indexOfTr8s, MIDIClient.sources[~indexOfTr8s]);
~indexOfTr8sCtl = MIDIClient.sources.detectIndex({arg ep; ep.name.contains("TR-8S CTRL")});
MIDIIn.connect(~indexOfTr8sCtl, MIDIClient.sources[~indexOfTr8sCtl]);

~tr8sCtrlUid = MIDIClient.destinations.at(~indexOfTr8sCtl).uid;
~midiOut = MIDIOut.new(~indexOfTr8sCtl,~tr8sCtrlUid);
~midiOut.control(10 , 49, 100)

~tempoClock = TempoClock.default;
~tempoClock.tempo = 125/60;
Pdef(\mt, Pbind(
    \type, \midi,
    \midicmd, \control,
    \midiout, ~midiOut,
    \chan, 10,
	\ctlNum, 49,
    \dur, 4,
	\control, Pseq([64,20,59,53,38,47,68,32,64,60,20,32,68,52,20,40],inf)
)
).quant_(~tempoClock.beatsPerBar);
Pdef(\mt).play;
PdefAllGui();
//////////////////////////////////////////////////////////
MIDIIn.connectAll;
MIDIdef.noteOn(\tr8sNoteOn, {|v,n,ch,id| ["noteOn",v,n,ch,id].postln;});
MIDIdef.noteOff(\tr8sNoteOff, {|v,n,ch,id| ["noteOff",v,n,ch,id].postln;});
MIDIdef.cc(\tr8sCtl, {|v,n,ch,id| ["control",v,n,ch,id].postln;});

FreqScope.new(400, 200, 0, server: s);
ServerOptions.inDevices[1];
ServerOptions.outDevices;
Server.default.options.inDevice_("TR-8S");
Server.default.options.outDevice_("TR-8S");
s.quit
s.boot

Scale.major.at([1,2,3])