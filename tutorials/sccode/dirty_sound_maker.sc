// https://sccode.org/1-5cH#c907
(

var win = Window.new( "MiniXul - Dirty Sound Maker", Rect( 0, 0, 1200, 800 ) );

var draw_h_slider;

var margin = 10;

var lfo_value = 0;
var lfo_rate_value = 1.explin( 0.03125, 32, 0, 1 );
var reverb_value = 0;
var amp_value = 0.5;
var fold_value = 0;
var value = 110.linlin( 55, 220, 0, 1 );

var harmo_spectrum;
var harmo_numharm = 32;
var ampBus = Bus.control(s);
var sndBus = Bus. audio(s, 2);
var harmo_view;
var harmo_text;

var amp_slider = UserView( win, Rect( margin, win.bounds.height * 0.78 + ( margin / 2 ), win.bounds.width - (margin*4) / 3, win.bounds.height * 0.1 - margin ) );

var lfo_amount_slider = UserView( win, Rect( margin * 2 + ( win.bounds.width - (margin*4) / 3 ), win.bounds.height * 0.78 + ( margin / 2 ), win.bounds.width - (margin*4) / 3, win.bounds.height * 0.1 - margin ) );

var lfo_rate_slider = UserView( win, Rect( margin * 3 + ( win.bounds.width - (margin*4) / 3 * 2 ), win.bounds.height * 0.78 + ( margin / 2 ), win.bounds.width - (margin*4) / 3, win.bounds.height * 0.1 - margin ) );

var reverb_slider = UserView( win, Rect( margin, win.bounds.height * 0.88 + ( margin / 2 ), win.bounds.width - (margin*4) / 3, win.bounds.height * 0.1 - margin ) );

var tune_slider = UserView( win, Rect( margin * 2 + ( win.bounds.width - (margin*4) / 3 ), win.bounds.height * 0.88 + ( margin / 2 ), win.bounds.width - (margin*4) / 3, win.bounds.height * 0.1 - margin ) );

var fold_slider = UserView( win, Rect( margin * 3 + ( win.bounds.width - (margin*4) / 3 * 2 ), win.bounds.height * 0.88 + ( margin / 2 ), win.bounds.width - (margin*4) / 3, win.bounds.height * 0.1 - margin ) );

// SynthDefs
var luce_synth = SynthDef(\luce, { | out = 0, freq = 110, amp = 0, mini_param = 24 |
	var snd = Resonz.ar( Saw.ar(freq*2), mini_param, 0.2 );
	Out.ar(out, Pan2.ar(snd, 0, amp));});

var bougie_synth = SynthDef(\bougie, { | out = 0, freq = 110, amp = 0, mini_param = 440 |
	var snd = Blip.ar(freq!2, mini_param, 0.5) * amp;
	Out.ar( out, snd );});

var invasion_synth = SynthDef(\invasion, { | out = 0, freq = 110, amp = 0, mini_param = 100 |
	var snd = RLPF.ar( Pulse.ar( [freq,freq*2], 0.5, amp * 0.5 ), mini_param, 0.05, amp * 0.5 );
	Out.ar( out, snd );});

var windy_synth = SynthDef(\windy, { | out = 0, freq = 110, amp = 0, mini_param = 24 |
	var snd = BPF.ar(WhiteNoise.ar, freq*mini_param, 0.4, 0.4);
	Out.ar(out, Pan2.ar(snd, 0, amp));});

var pulser_synth = SynthDef(\pulser, { | out = 0, freq = 110, amp = 0, mini_param = 40 |
	var snd = RLPF.ar( Saw.ar(freq), mini_param, 0.5, 0.2);
	Out.ar(out, Pan2.ar(snd, 0, amp));});

var poussiere_synth = SynthDef(\poussiere, { | out = 0, freq = 110, amp = 0, mini_param = 0.5 |
	var snd = Dust2.ar(mini_param, 1);
	Out.ar(out, Pan2.ar( snd, 0, amp ) );});

var lowvibe_synth = SynthDef(\lowvibe, { | out = 0, freq = 110, amp = 0, mini_param = 24 |
	var snd = SinOsc.ar(freq, 0, mini_param).fold2(1) * 0.2;
	Out.ar( out, Pan2.ar( snd, 0, amp * 0.75 ) );});

var lizard_synth = SynthDef(\lizard, { | out = 0, freq = 110, amp = 0, mini_param = 100 |
	var snd = SyncSaw.ar(freq, mini_param, 0.2);
	Out.ar( out, Pan2.ar( snd, 0, amp * 0.5 ) );});

var master_synth;
~minis = Group();

ampBus.value = 0.1;

{
	SynthDef("additive-multislider", {
		arg outbus, freq = 110, amp = 0.01, freq_mul = 1;
		var snd = SinOsc.ar(freq * freq_mul, 0, Lag.kr(amp, 3));
		Out.ar(outbus, snd!2);
	}).add;

	SynthDef("continuousOut", {
		arg inbus, amp = 0.1, gate = 1, att = 0.1, sus = 1, rel = 1;
		var env = EnvGen.kr(Env.asr(att, sus, rel), gate);
		Out.ar(~master_in, In.ar(inbus, 2) * amp * env * 0.4);
	}).add;

	// Wait for SynthDefs to be added...
	s.sync;

	// Now call the Synths:
	harmo_spectrum = Array.fill(harmo_numharm, {arg i; Synth("additive-multislider", [\freq, 110, \freq_mul, (i+1), \amp, 0.0, \outbus, sndBus], ~minis)});

	Synth("continuousOut", [\inbus, sndBus, \amp, ampBus.asMap], ~minis, \addAfter);

}.fork;

harmo_view = MultiSliderView.new( win, Rect(0, 0, win.bounds.width / 3, win.bounds.height * 0.25 ) );
harmo_view.value = Array.fill(harmo_numharm, {0.0});
harmo_view.isFilled = true;
harmo_view.indexThumbSize = harmo_view.bounds.width / (harmo_numharm);
harmo_view.fillColor = Color.blue;
harmo_view.strokeColor = Color.blue;
harmo_view.gap = 0;
harmo_view.drawRects = false; // Display as bar charts
harmo_view.drawLines = true; // Display as plot

harmo_text = StaticText.new( win, Rect( 0, 0, win.bounds.width / 3, win.bounds.height *0.05 ) );
harmo_text.align = \center;
harmo_text.string = "Harmo";
harmo_text.acceptsMouse = false;

harmo_view.action = {arg multi;
	var index = multi.index;
	var value = multi.currentvalue;
	if( value < 0.025, { value = 0 } );
	harmo_spectrum[index].set(\amp, value*2); };

win.background = Color.new(0.2, 0.1, 0.1);

tune_slider.drawFunc =  { draw_h_slider.value( tune_slider, value, Color.red, "Gravaigu" ) };
tune_slider.refresh;

tune_slider.mouseDownAction = { | slider, x |
	value = (x).linlin( 0, slider.bounds.width, 0, 1 );
	~minis.set( \freq, value.linexp( 0, 1, 55, 440 ) );
	tune_slider.refresh
};
tune_slider.mouseMoveAction = tune_slider.mouseDownAction;

lfo_rate_slider.drawFunc =  { draw_h_slider.value( lfo_rate_slider, lfo_rate_value, Color.blue, "Vitesse de vibrance" ) };
lfo_rate_slider.refresh;
lfo_rate_slider.mouseDownAction = { | slider, x |
	lfo_rate_value = (x).linlin( 0, slider.bounds.width, 0, 1 );
	master_synth.set( \lfo_rate, lfo_rate_value.linexp( 0, 1, 0.03125, 32 ) );
	lfo_rate_slider.refresh
};
lfo_rate_slider.mouseMoveAction = lfo_rate_slider.mouseDownAction;

lfo_amount_slider.drawFunc =  { draw_h_slider.value( lfo_amount_slider, lfo_value, Color.new( 0, 0.8, 0.2 ), "Taux de vibrance" ) };
lfo_amount_slider.refresh;
lfo_amount_slider.mouseDownAction = { | slider, x |
	lfo_value = (x).linlin( 0, slider.bounds.width, 0, 1 );
	master_synth.set( \lfo_amount, lfo_value );
	lfo_amount_slider.refresh
};
lfo_amount_slider.mouseMoveAction = lfo_amount_slider.mouseDownAction;

reverb_slider.drawFunc =  { draw_h_slider.value( reverb_slider, reverb_value, Color.new( 1, 0, 1 ), "Cathédralitude" ) };
reverb_slider.refresh;
reverb_slider.mouseDownAction = { | slider, x |
	reverb_value = (x).linlin( 0, slider.bounds.width, 0, 1 );
	master_synth.set( \reverb_amount, reverb_value );
	reverb_slider.refresh
};
reverb_slider.mouseMoveAction = reverb_slider.mouseDownAction;

amp_slider.drawFunc =  { draw_h_slider.value( amp_slider, amp_value, Color.new( 0, 1, 1 ), "Niveau de respect des voisins" ) };
amp_slider.refresh;
amp_slider.mouseDownAction = { | slider, x |
	amp_value = (x).linlin( 0, slider.bounds.width, 0, 1 );
	master_synth.set( \amp, amp_value );
	amp_slider.refresh
};
amp_slider.mouseMoveAction = amp_slider.mouseDownAction;

fold_slider.drawFunc =  { draw_h_slider.value( fold_slider, fold_value, Color.new( 1, 1, 0 ), "Rauquèneraullance" ) };
fold_slider.refresh;
fold_slider.mouseDownAction = { | slider, x |
	fold_value = (x).linlin( 0, slider.bounds.width, 0, 1 );
	master_synth.set( \dist_amount, fold_value );
	fold_slider.refresh
};
fold_slider.mouseMoveAction = fold_slider.mouseDownAction;

~add_mini = { | view, rect, synthdef, out_channel, group, param_range, name, graphic_numbers, graphic_colors |

	var value = [ 0, 1 ];

	var synth;

	// Graphical number values
	var knob_size = graphic_numbers[0];
	var knob_outline_size = graphic_numbers[1];
	var stroke_size = graphic_numbers[2];
	var margin = graphic_numbers[3];

	// Colors
	var frame_color = graphic_colors[0];
	var frame_border_color = graphic_colors[1];
	var gradient_color = graphic_colors[2];
	var diamond_color = graphic_colors[3];
	var diamond_outline_color = graphic_colors[4];

	var mini_view = UserView.new( view, rect );

	var input_view = UserView.new( mini_view );
	if( name != "", {
		var text_name = StaticText.new( mini_view, Rect( 0, 0, mini_view.bounds.width, mini_view.bounds.height * 0.15 ) );
		text_name.string = name;
		text_name.align = \center;
		if( frame_color == Color.black, { text_name.stringColor = Color.white } );
		input_view.bounds = Rect( margin, mini_view.bounds.height * 0.15 + margin, mini_view.bounds.width - ( margin * 2 ), mini_view.bounds.height * 0.85 - ( margin * 2 ) );
	}, {
		input_view.bounds = Rect( margin, margin, mini_view.bounds.width - ( margin * 2 ), mini_view.bounds.height - ( margin * 2 ) );
	});

	mini_view.background = frame_color;
	mini_view.resize = 5;

	input_view.background_( frame_color );
	synth = synthdef.play(  target: group, args: [\out, out_channel]  );

	// Here is the function used to draw the custom input_view:
	input_view.drawFunc = {

		Pen.width = stroke_size;

		// First, draw the background frame:
		Pen.addRect( Rect(0,0, input_view.bounds.width,input_view.bounds.height) );
		Pen.fillAxialGradient( 0@0, input_view.bounds.width@input_view.bounds.height, Color.black, gradient_color );

		// Draw the diamond itself:
		Pen.moveTo( ( input_view.bounds.width * value[0] - knob_size ) @ ( input_view.bounds.height * value[1] ) );
		Pen.lineTo( ( input_view.bounds.width * value[0] ) @ ( input_view.bounds.height * value[1] - knob_size ) );
		Pen.lineTo( ( input_view.bounds.width * value[0] + knob_size ) @ (( input_view.bounds.height * value[1] ) ) );
		Pen.lineTo( ( input_view.bounds.width * value[0] ) @ ( input_view.bounds.height * value[1] + knob_size ) );
		// Fourth line isn't needed as we fill the shape.

		Pen.fillColor_( diamond_color );
		Pen.fill;

		// Draw the diamond outline:
		Pen.moveTo( 0 @ ( input_view.bounds.height * value[1] ) );
		Pen.lineTo( ( input_view.bounds.width * value[0] - knob_outline_size ) @ ( input_view.bounds.height * value[1] ) );

		Pen.moveTo( ( input_view.bounds.width * value[0] ) @ 0 );
		Pen.lineTo( ( input_view.bounds.width * value[0] ) @ ( input_view.bounds.height * value[1] - knob_outline_size ) );

		Pen.moveTo( ( input_view.bounds.width * value[0] + knob_outline_size ) @ (( input_view.bounds.height * value[1] ) ) );
		Pen.lineTo( input_view.bounds.width @ (( input_view.bounds.height * value[1] ) ) );
		Pen.moveTo( ( input_view.bounds.width * value[0] ) @ (( input_view.bounds.height * value[1] + knob_outline_size ) ) );
		Pen.lineTo( ( input_view.bounds.width * value[0] ) @  input_view.bounds.height );

		Pen.moveTo( ( input_view.bounds.width * value[0] - knob_outline_size ) @ ( input_view.bounds.height * value[1] ) );
		Pen.lineTo( ( input_view.bounds.width * value[0] ) @ ( input_view.bounds.height * value[1] - knob_outline_size ) );
		Pen.lineTo( ( input_view.bounds.width * value[0] + knob_outline_size ) @ (( input_view.bounds.height * value[1] ) ) );
		Pen.lineTo( ( input_view.bounds.width * value[0] ) @ (( input_view.bounds.height * value[1] + knob_outline_size ) ) );
		Pen.lineTo( ( input_view.bounds.width * value[0] - knob_outline_size ) @ ( input_view.bounds.height * value[1] ) );

		Pen.strokeColor_( diamond_outline_color );
		Pen.stroke;

		// Draw the frame border:
		Pen.addRect( Rect(0,0, input_view.bounds.width,input_view.bounds.height) );
		Pen.strokeColor_( frame_border_color );
		Pen.stroke;
	};

	// Set the default action
	input_view.action = {
		synth.set( \amp, 1 - value[1] ); // Requires to invert the value, as the Y axis from GUI goes from top to bottom, and input_views usually goes from bottom to top.
		synth.set(\mini_param, linexp(value[0], 0, 1, param_range[0], param_range[1])); // Exponential mapping between the 0 -> 1 value and the amount range. Change this settings according to your needs.
		input_view.refresh // Call the drawFunc of the input_view to update graphics
	};

	// Define mouse actions
	input_view.mouseDownAction = { arg input_view, x = 0.5, y = 0.5, m;
		([256, 0].includes(m)).if{ // restrict to no modifier
			value[0] = (x).linlin(0,input_view.bounds.width,0,1); // Linear mapping between the input_view size and 0 -> 1
			value[1] = (y).linlin(0,input_view.bounds.height,0,1);
			input_view.doAction };
	};

	input_view.mouseMoveAction = input_view.mouseDownAction; // Map the mouse action to its function
	mini_view;
};

if ( ~master_in == nil, { ~master_in = Bus.audio( s, 2 ); } );

~add_mini.value( win, Rect( win.bounds.width / 3, 0, win.bounds.width / 3, win.bounds.height * 0.25 ), windy_synth, ~master_in, ~minis, [ 1, 128 ], "Windy", [8,15,2,3], [Color.new(0.8, 0.4, 0),Color.yellow,Color.new(0.95,0.8,0),Color.new( 0.6, 0.3, 0 ),Color.new(0.8, 0.4, 0)] );

~add_mini.value( win, Rect( win.bounds.width / 3 * 2, 0, win.bounds.width / 3, win.bounds.height * 0.25 ), poussiere_synth, ~master_in, ~minis, [ 0.5, 10000 ], "Poussière", [8,15,2,3], [Color.black,Color.white,Color.white,Color.black,Color.grey] );

~add_mini.value( win, Rect( 0, win.bounds.height * 0.25, win.bounds.width / 3, win.bounds.height * 0.25 ), luce_synth, ~master_in, ~minis, [ 24, 16000 ], "Luce", [8,15,2,3], [Color.new( 0.7, 0.4, 0 ),Color.new( 1, 0.4, 0 ),Color.new( 0.9, 0.5, 0.3 ),Color.new( 1, 0.75, 0.25 ),Color.new( 0.8, 0.55, 0.05 )] );

~add_mini.value( win, Rect( win.bounds.width / 3, win.bounds.height * 0.25, win.bounds.width / 3, win.bounds.height * 0.25 ), bougie_synth, ~master_in, ~minis, [ 1, 128 ], "Bougie", [8,15,2,3], [Color.new(0,0,0),Color.new(1,1,0),Color.new(1,0,0),Color.new( 1, 0, 0.1),Color.new(1,0,0.2)] );

~add_mini.value( win, Rect( win.bounds.width / 3 * 2, win.bounds.height * 0.25, win.bounds.width / 3, win.bounds.height * 0.25 ), invasion_synth, ~master_in, ~minis, [ 130, 16000 ], "Invasion", [8,15,2,3], [Color.new(1, 0.5, 0.75),Color.white,Color.new( 1, 0.45, 0.65 ),Color.new( 1, 0.25, 0.5 ),Color.new(1, 0.25, 0.5)] );

~add_mini.value( win, Rect( 0, win.bounds.height * 0.5, win.bounds.width / 3, win.bounds.height * 0.25 ), pulser_synth, ~master_in, ~minis, [ 40, 16000 ], "Pulser", [8,15,2,3], [Color.new(0.28, 0, 0.14),Color.black,Color.new(0.75, 0, 0.5),Color.grey,Color.blue] );

~add_mini.value( win, Rect( win.bounds.width / 3, win.bounds.height * 0.5, win.bounds.width / 3, win.bounds.height * 0.25 ), lowvibe_synth, ~master_in, ~minis, [ 1, 128 ], "LowVibe", [8,15,2,3], [Color.new(0.05, 0.35, 0.05),Color.new(0, 0.2, 0),Color.new(0.15, 0.8, 0.3),Color.new(0.1, 0.66, 0.9),Color.new(0, 0.56, 0.8)] );

~add_mini.value( win, Rect( win.bounds.width / 3 * 2, win.bounds.height * 0.5, win.bounds.width / 3, win.bounds.height * 0.25 ), lizard_synth, ~master_in, ~minis, [ 50, 20000 ], "Lizard", [8,15,2,3], [Color.green,Color.red,Color.green,Color.red,Color.red] );

master_synth = SynthDef(\master, { | inBus, amp = 0.5, lfo_rate = 1, lfo_amount = 0, reverb_amount = 0, dist_amount = 0 |
	var snd, dist_snd, reverb, mix;

	snd = In.ar( inBus, 2 );

	dist_snd = snd.abs * dist_amount;

	snd = snd * ( 1 - dist_amount );

	snd = Mix.ar( [ snd, dist_snd ] );

	snd = snd * ( 1 - ( SinOsc.kr( lfo_rate ) * lfo_amount ) );
	reverb = snd;
	4.do( { reverb = AllpassC.ar(reverb, 0.1, { Rand(0.001,0.1) }.dup, 4)} );

	snd = snd * ( 1 - reverb_amount );
	reverb = reverb * reverb_amount;

	mix = Mix.new( [ snd, reverb ] );
	mix = mix * amp;

	Out.ar( 0, mix );

}).play( args: [\inBus, ~master_in], addAction: \addToTail );

// Finally, bring the window to the front.
win.front;
CmdPeriod.doOnce({Window.closeAll}); // Kill GUI and server sounds on < Ctrl + ^ + . > .
win.onClose = {
	s.freeAll;
	Window.closeAll;
};

// Slider Draw Function
draw_h_slider = { | slider, value, color, title |

	var icon_size = slider.bounds.height * 0.2;
	var outline_size = slider.bounds.height * 0.4;

	// Draw the frame
	Pen.strokeColor = Color.white;
	Pen.fillColor = Color.black;
	Pen.addRect( Rect(0, 0, slider.bounds.width, slider.bounds.height ) );
	Pen.width = 2;
	Pen.draw(3);

	if( title != "", {
		var new_font = Font.default.deepCopy;
		new_font.size = slider.bounds.height * 0.3;
		Pen.stringAtPoint( title, ( slider.bounds.height * 0.1 )@( slider.bounds.height * 0.1 ), new_font, color );
	});

	// Draw the losange
	Pen.moveTo( ( ( slider.bounds.width - ( slider.bounds.width * ( 1 - value ) ) ) - icon_size ) @ ( slider.bounds.height/2 ) );

	Pen.lineTo( ( slider.bounds.width - (slider.bounds.width * ( 1 - value )) ) @ ( slider.bounds.height/2 -icon_size ) );

	Pen.lineTo( ( ( slider.bounds.width - ( slider.bounds.width * ( 1 - value )) ) + icon_size ) @ ( slider.bounds.height/2 ) );

	Pen.lineTo( ( slider.bounds.width - (slider.bounds.width * ( 1 - value )) ) @ ( slider.bounds.height/2 + icon_size ) );

	Pen.lineTo( ( ( slider.bounds.width - ( slider.bounds.width * ( 1 - value )) ) - icon_size ) @ ( slider.bounds.height/2 ) );

	Pen.fillColor = color;
	Pen.fill;

	Pen.moveTo( ( ( slider.bounds.width - ( slider.bounds.width * ( 1 - value )) ) - outline_size ) @ ( slider.bounds.height/2 ) );

	Pen.lineTo( ( slider.bounds.width - (slider.bounds.width*( 1 - value )) ) @ ( slider.bounds.height/2 -outline_size ) );

	Pen.lineTo( ( ( slider.bounds.width - ( slider.bounds.width * ( 1 - value )) ) + outline_size ) @ ( slider.bounds.height/2 ) );

	Pen.lineTo( ( slider.bounds.width - (slider.bounds.width*( 1 - value )) ) @ ( slider.bounds.height/2 + outline_size ) );

	Pen.lineTo( ( ( slider.bounds.width - ( slider.bounds.width * ( 1 - value )) ) - outline_size ) @ ( slider.bounds.height/2 ) );

	Pen.moveTo( 0 @ ( slider.bounds.height/2 ) );
	Pen.lineTo( ( ( slider.bounds.width - ( slider.bounds.width * ( 1 - value )) ) - outline_size ) @ ( slider.bounds.height/2 ));

	Pen.moveTo( ( slider.bounds.width ) @ ( slider.bounds.height/2 ) );
	Pen.lineTo( ( ( slider.bounds.width - ( slider.bounds.width * ( 1 - value )) ) + outline_size ) @ ( slider.bounds.height/2 ) );

	Pen.strokeColor = color;
	Pen.stroke;
	Pen.draw(3);
};

)
