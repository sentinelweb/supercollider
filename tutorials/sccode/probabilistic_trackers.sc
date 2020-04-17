(

var synth; // This variable wil hold the synth definition which will produce sound
var folder_path = "/Users/robert/sc_test/"; // Get the actual folder name to load the tracker module

// The tracker will work modifying an array of note playing probabilities (i.e. 1 = 100% chance, 0.5 = 50% chance, etc). The size of the array will define the beat number. Here, we'll have three examples, one for the binary tracker, one for the brobabilist tracker, and one for the duo tracker, which is a combination of these two.

var rythm = [ 1, 0, 0, 1, 0, 0, 1, 0 ];
var rythm2 = [ 1, 0.28571428571429, 0, 0.57142857142857, 0.28571428571429, 0.57142857142857 ];
var rythm3 = [ 1, 0, 0.28571428571429, 0.57142857142857, 0, 0.57142857142857, 1, 0.28571428571429, 0, 1 ];

var binary_tracker_text, probabilist_tracker_text, duo_tracker_text;

var win = Window.new( "Tracker Example", Rect( 100, 100, 500, 300 ) ); // Obviously, the purpose of these trackers is to be displayed somewhere.

t = TempoClock.new(); // Let's define a TempoClock to drive the routines.
t.tempo = 4;

synth = SynthDef( \test_synth, { | freq = 220 | // A really simple synth for example purposes

	var env = Env.perc( 0.05, 1, 1 );
	var envgen = EnvGen.kr( env, doneAction: Done.freeSelf );
	var snd = SinOsc.ar( freq, mul: envgen * 0.25 );

	Out.ar( 0, [ snd, snd ] );

}).add();


Routine { // Routine associated to the first tracker.

	var count = 0; // This will store the current beat

	loop {
		if( rythm[count].coin, {	Synth( \test_synth, [\freq, 440] ) } ); // Coin function used against the note playing probability at the current rythm index.
		count = count + 1; // Current beat moving on...
		if( count == rythm.size, { count = 0 } ); // ...getting back to 0 if it passed the rythm length.
		1.wait; // Wait for the next beat, please.
	};
}.play( t ); // Our TempoClock will drive the routine.

Routine { // Rythm #2
	var count = 0;
	loop {
		if( rythm2[count].coin, { Synth( \test_synth, [\freq, 440 * 3/2] ) } );
		count = count + 1;
		if( count == rythm2.size, { count = 0 } );
		1.wait;
	};
}.play( t );

Routine { // Rythm #3
	var count = 0;
	loop {
		if( rythm3[count].coin, { Synth( \test_synth, [\freq, 440 * 5/4] ) } );
		count = count + 1;
		if( count == rythm3.size, { count = 0 } );
		1.wait;
	};
}.play( t );

this.executeFile( ( folder_path ++ "tracker.scd" ).standardizePath ); // Now load the tracker functions, which will be stored on global variables.

// Now add the three tracker types. See tracker.scd for a description of the algorithms.

binary_tracker_text = StaticText.new( win, Rect( 0, 0, win.bounds.width, 30 ) );
binary_tracker_text.align = \center;
binary_tracker_text.string = "Binary Tracker :";

~add_binary_tracker.value( rythm, win, Rect( 0, 30, win.bounds.width, win.bounds.height / 3 - 30 ), 1, Color( 1, 0.5, 0 ) );

probabilist_tracker_text = StaticText.new( win, Rect( 0, win.bounds.height * 0.333, win.bounds.width, 30 ) );
probabilist_tracker_text.align = \center;
probabilist_tracker_text.string = "Probabilist Tracker :";

~add_probabilist_tracker.value( rythm2, win, Rect( 0, win.bounds.height * 0.333 + 30, win.bounds.width, win.bounds.height / 3 - 30 ), 1, [ 0, 0.5, 1 ], 0, 1, 8 );

duo_tracker_text = StaticText.new( win, Rect( 0, win.bounds.height * 0.666, win.bounds.width, 30 ) );
duo_tracker_text.align = \center;
duo_tracker_text.string = "Duo Tracker :";

~add_duo_tracker.value( rythm3, win, Rect( 0, win.bounds.height * 0.666 + 30, win.bounds.width, win.bounds.height / 3 - 30 ), 1, [ 0, 1, 0.5 ], 0, 1, 8 );

// Finally, bring the window to the front.
win.front;
CmdPeriod.doOnce({Window.closeAll}); // Kill GUI and server sounds on < Ctrl + ^ + . > .
win.onClose = {
	s.freeAll;
	Window.closeAll;
};

)