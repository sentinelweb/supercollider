// functions
f = { arg a, b; a / b; };    // '/' means divide
f.value(2, 10);            // regular style
f.value(b: 2, a: 10);        // keyword style

(
f = { arg a, b;
    var firstResult, finalResult;
    firstResult = a + b;
    finalResult = firstResult * 2;
    finalResult;
};
f.value(2, 3);    // this will return (2 + 3) * 2 = 10
)

// local server
s.avgCPU
s.serverRunning
s.addr//a NetAddr(127.0.0.1, 57110)
s.postln;//localhost
s.makeWindow; // shows window
s.boot
s.quit
s.quit;s.boot;

// custom servers
n = NetAddr("127.0.0.1", 57200); // IP (get it from whatsmyip.org) and port
p = Server.new("thor", n);
p.makeWindow; // make the gui window
p.boot; // boot it
// try the server:
{SinOsc.ar(444)}.play(p);
// stop it
p.quit;


// 2) ========= The Unit Generators ==========

/*
Unit Generators (UGens) are plugins of the server that generate or manipulate audio.
They are C/C++ code encapsulations of complex DSP algorithms presented as simple UGens.
These can be connected in various ways. The main idea is that they are modular and
can work on each other.
*/

// Here is a sine wave unit generator

{SinOsc.ar(440, 0, 1)}.play // the arguments are frequency, phase and amplitude
// Now we can use another sine wave unit generator to manipulate the frequency of the first

{SinOsc.ar(440*SinOsc.ar(4, mul:0.125, add:1), 0, 1)}.scope // and we get vibrato

// We could also manipulate the amplitude:
{SinOsc.ar(440, 0, 1*SinOsc.ar(5, mul:0.5, add:1))}.freqscope // and we get tremolo

// The output of one UGen can be used as the input of another:
{RLPF.ar(Saw.ar(333), SinOsc.ar(1).range(400, 14000), 0.1)}.freqscope
// here the sine is controlling the cutoff frequency of the low pass filter

// synth as variable - external control
x = { |freq = 440| SinOsc.ar(freq, 0, 0.3) }.play; // this returns a Synth object;
x.set(\freq, 880); // note you can set the freq argument
x.set(\freq, 220); // note you can set the freq argument
x.defName; // the name of the resulting SynthDef (generated automatically in a cycle of 512)
x.release(4); // fadeout over 4 seconds

/*
NOTE: There is a difference in the Function-play code and the SynthDef, in that
we need the Out Ugen in a synth definition to tell the server
which audiobus the sound should go out of. (0 is left, 1 is right)
*/

// which leads up to the question: how to make a stereo signal:

(
SynthDef(\stereosine, {arg freq=333, amp=0.4, pan=0.0; // we add a new argument
	var signal;
	signal = SinOsc.ar(freq, 0, amp);
	signal = Pan2.ar(signal, pan);
	Out.ar(0, signal);
}).add // we add the synthdef to the server
)

Synth(\stereosine); // try it!

// kill the above with Apple+dot and then we run it again
a = Synth(\stereosine, [\freq, 150]); // we assign the synth to a variable
a.set(\freq, 444) // set the frequency from outside
a.set(\amp, 0.8)

// trying the panning
a.set(\pan, -1)
a.set(\pan, 1)
a.set(\pan, 0)

a.free; // free the synth
// stereo - nice
(
{ var freq;
    freq = [[660, 880], [440, 660], 1320, 880].choose;
    SinOsc.ar(freq, 0, 0.2);
}.play;
)

{ Pan2.ar(PinkNoise.ar(0.2), SinOsc.kr(0.5)) }.play;// panning noise
// Check the available UGens:

UGen.browse
// from dust help
(
SynthDef("help-Dust", { arg out=0;
    Out.ar(out,
        Dust.ar(200, 0.5)
    )
}).play;
)

(
SynthDef("help-Dust", { arg out=0;
    Out.ar(out,
        Dust.ar(XLine.kr(20000, 2, 10), 0.5)
    )
}).play;
)
// movie ??
(
w = Window("mov").front;
m = MovieView(w, Rect(0,20,360, 260));
m.path_("/Users/robert/pics/rob/raw/orkney09.15/GOPR0510.MP4");
// b = Button(w, Rect(0, 0, 150, 20))
//     .states_([["pick a file"]])
//     .action_({ File.openDialog("", { |path| m.path_(path) }) });

)