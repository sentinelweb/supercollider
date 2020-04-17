

(
SynthDef(\playTone, { |freq, duration|
    var w = SinOsc.ar(freq) * XLine.ar(1001,1,duration,add: -1,doneAction:2) / 1000;
    Out.ar(0,w!2);
}).add;
)

(
SynthDef(\recordTone, { |buffer|
    RecordBuf.ar(In.ar(0,2), buffer, loop: 0, doneAction: 2);
}).add;
)

(Routine({
    var recordfn = { |freq, duration|
        var server = Server.local;
        var buffer = Buffer.alloc(server, server.sampleRate * duration, 2);

        server.sync;

        server.makeBundle(func: {
            var player = Synth(\playTone, [\freq, freq, \duration, duration]);
            var recorder = Synth.after(player, \recordTone, [\buffer, buffer]);
        });

        duration.wait;

        buffer.write(
            "/Users/robert/Dropbox/music/projects/theremin/test.wav",
            "WAVE",
            "int16",
            completionMessage: ["/b_free", buffer]
        );
    };

    recordfn.value(440,5);

}).next)
//
// Booting server 'localhost' on address 127.0.0.1:57110.
// Found 0 LADSPA plugins
// Number of Devices: 7
// 0 : "Built-in Microph"
// 1 : "Built-in Output"
// 2 : "UMC404HD 192k"
// 3 : "DDJ-1000"
// 4 : "Soundflower (2ch)"
// 5 : "Soundflower (64ch)"
// 6 : "rekordbox Aggregate Device"
//
// "Built-in Microph" Input Device
// Streams: 1
// 0  channels 2
//
// "UMC404HD 192k" Output Device
// Streams: 1
// 0  channels 4

// "UMC404HD 192k"
{ In.ar(2,[3]) }.play; // input 1
{ In.ar(2,[4]) }.play; // input 2
{ In.ar(2,[5]) }.play; // input 3
{ In.ar(2,[6]) }.play; // input 4
ServerOptions.inDevices
s.boot;
(
Ndef(\theremin, {

	var in = In.ar(2,[3]) ! 2  * 4;
	var hpf = HPF.ar(HPF.ar(in, 200),20);
	var distorted = hpf.clip2(0.6);

	var lpf = LPF.ar(distorted, 1000);
	var buffer = Buffer.alloc(s, 1024, 1);
	var chain = FFT(buffer, in);
	var out = distorted;
	distorted.scope;
	// create a new analyzer
	FreqScope.new(400, 200, 0, server: s);

	Out.ar(1, out);
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

// pulse width modulation
(
{ LFPulse.ar(100,0,MouseY.kr(0,1),0.1) }.scope(1, zoom: 4);
{ LFPulse.ar(100,0,LFTri.kr(0.2,0,0.5,0.5),0.1) }.scope(1, zoom: 4);
)

{ LPF.ar(Saw.ar(200,0.1), SinOsc.kr(XLine.kr(0.7,300,20),0,3600,4000)) }.play;