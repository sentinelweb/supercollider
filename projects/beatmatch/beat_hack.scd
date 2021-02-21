~outBus = Bus.audio(s,2);
(
a = SynthDef(\help_beattrack, { |out, vol=2, beepvol=1.0, lock=0|
    var in, fft, resample;
    var trackb, trackh, trackq, tempo;
    var bsound, hsound, qsound, beep;

    //in = PlayBuf.ar(1,d, BufRateScale.kr(d),1,0,1);
    in = SoundIn.ar(0);

    fft = FFT(LocalBuf(1024), in); // for sampling rates 44100 and 48000

    #trackb, trackh, trackq, tempo = BeatTrack.kr(fft, lock);

    beep = SinOsc.ar(1000, 0.0, Decay.kr(trackb, 0.1));
	beep = BBandPass.ar(beep, freq: 1000, bw: 0.25, mul: 1.0, add: 0.0);
	beep = BBandPass.ar(beep, freq: 1000, bw: 0.25, mul: 1.0, add: 0.0);

    Out.ar(~outBus, Pan2.ar((vol * in) + (beepvol * beep), 0.0));
	FreqScope.new(400, 200, ~outBus, server: s);
	fork {
		loop {
			tempo.source.postln; // prints "a BeatTrack"
			1.wait;
		}
	}

}).play
)