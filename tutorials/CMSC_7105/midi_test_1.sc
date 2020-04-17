// see also
// file:///Users/robert/Library/Application%20Support/SuperCollider/Help/Guides/UsingMIDI.html
// these examples use MIDIIn - which is NOT the recommended way - better to use MIDIFunc and MIDIdef apparently as they can have multiple handlers
// ----------------------------------------------------------------------------
// midi bus (working)
// ----------------------------------------------------------------------------
// how to connect synths together? i.e. op to input (for modular chaining) (answer : busses)
(
SynthDef("moto-rev", { |out, ffreq = 100, q = 0.1, clip = 0.4, lfreq = 0.2, gain = 1, pmul=10, poff=51 |
    x = CombL.ar(
		RLPF.ar(
			LFPulse.ar(
				SinOsc.kr(lfreq, 0, pmul, poff),
				[0, 0.1],
				0.1
			),
			ffreq,
			q,
			gain
		),
		0.4,
		0.3,
		0.5
	).clip2(clip); // todo add a filter to the output

    Out.ar(out, x );
}).add;
)

(
// todo clear mapping : make sure you clean each time to remove all created other wise ..  the handle is lost .. click the bottom (cleanup) section each time after this section

b = Bus.control(s);
x = Synth("moto-rev");
// map the synth's first input (ffreq) to read
// from the bus' output index
x.map(0, b);

MIDIClient.init; //make sure to init when plugging ina new device!!

// MIDIIn.connect(0,1); // device 1
MIDIIn.connectAll;
//set the action:
(
MIDIIn.removeFuncFrom(\control, ~control);
~control = {arg src, chan, num, val;
	var f33, f32, f71,f74, f5;
	["control", chan, num, val].postln;

	f = {arg n, v = 20; ( "unassigned: n:" + n + " v: " + v).postln;};
	p = {arg osc, n, v;

		x.set(osc, v );
		( "send n:" + n + " v: " + v+" o:"+osc);
	};

	c = switch (num)
	{106} {  p.value(\clip, 33 , val / 127);}
	{102} {  p.value(\ffreq, 32 , val* 10 + 100);}
	{107} {  p.value(\q, 71 , val / 10);}
	{103} {  p.value(\lfreq, 74 , val / 10);}
	{108}  {  p.value(\gain, 5 , val/10);}
	{104} {  f.value(52,val);}
	{109}  {  f.value(6,val);}
	{105} {  f.value(83,val);}
	{"unmapped:"+chan +":"+ num + " -> "+val};
	c.postln;

};
MIDIIn.addFuncTo(\control, ~control);
)
)

// cleanup
(
x.free;
b.free;
MIDIIn.removeFuncFrom(\control, ~control);
MIDIIn.disconnect;
)

// ----------------------------------------------------------------------------
// midi control (keyboard)
// ----------------------------------------------------------------------------
MIDIClient.init;//make sure to init when plugging ina new device!!
MIDIIn.connect(0,1); // also MIDIIn.connectAll;
(
SynthDef("sik-goo", { |out, freq = 440, formfreq = 100, gate = 1.0, bwfreq = 800|
    var x;
    x = Formant.ar(
        SinOsc.kr(0.02, 0, 10, freq),
        formfreq,
        bwfreq
    );
    x = EnvGen.kr(Env.adsr, gate, Latch.kr(gate, gate)) * x;
    Out.ar(out, x);
}).add;
)

x = Synth("sik-goo");

//set the action:
(
~noteOn = {arg src, chan, num, vel;
	["note_on",chan,num,vel].postln;
	 x.set(\freq, num.midicps / 4.0);
	 x.set(\gate, vel / 200 );
	 x.set(\formfreq, vel / 127 * 1000);
};
MIDIIn.addFuncTo(\noteOn, ~noteOn);

~noteOff = { arg src,chan,num,vel;
    x.set(\gate, 0.0);
};
MIDIIn.addFuncTo(\noteOff, ~noteOff);

~control = {arg src, chan, num, val;
	["control",chan,num,val].postln;
};
MIDIIn.addFuncTo(\control, ~control);

~bend = { arg src,chan,val;
    ["bend",src, chan, val].postln;
	x.set(\bwfreq, val * 0.048828125 );
};
MIDIIn.addFuncTo(\bend, ~bend);
)
)

(
//cleanup
x.free;
MIDIIn.removeFuncFrom(\noteOn, ~noteOn);
MIDIIn.removeFuncFrom(\noteOff, ~noteOff);
MIDIIn.removeFuncFrom(\control, ~control);
MIDIIn.removeFuncFrom(\bend, ~bend);
)

/////////////////////////////////////////////////////////////
// "Using MIDI" help guide example (uses : MIDIFunc)
////////////////////////////////////////////////////////////
s.boot;

(
var notes, on, off;

MIDIClient.init;
MIDIIn.connectAll;

notes = Array.newClear(128);    // array has one slot per possible MIDI note

on = MIDIFunc.noteOn({ |veloc, num, chan, src|
    notes[num] = Synth(\default, [\freq, num.midicps,
        \amp, veloc * 0.00315]);
});

off = MIDIFunc.noteOff({ |veloc, num, chan, src|
    notes[num].release;
});

q = { on.free; off.free; };
)

// when done:
q.value;
