(
SynthDef(\insert, { arg bus;
    ReplaceOut.ar(bus, VSTPlugin.ar(In.ar(bus, 2), 2));
}).add;


VSTPlugin.search(verbose:true);
)
(
// create the synth:
~synth = Synth(\insert, [\bus, 0]);
// get a handle to the VSTPlugin:
~fx = VSTPluginController(~synth);
// open a plugin by name/key (might require VSTPlugin.search!)
~fx.open("Serum", verbose: true, multiThreading:true, editor:true);
//~fx.open("TDR Nova", verbose: true, multiThreading:true, editor:true);
)

(
~fx.editor;
//~fx.gui;
~fx.getProgramData({|data| data.postln}, async: true)
)

(
// two VST plugins in series:
SynthDef(\drivingbase, { arg bus;
    var sig;
    sig = VSTPlugin.ar(sig, 2, id: \serum);
    sig = VSTPlugin.ar(sig, 2, id: \eq);
    ReplaceOut.ar(bus, sig);
}).add;
)

(
~config = ();
~config[\drivingBase] = ();
~config[\drivingBase][\synth]=Synth(\drivingbase, [\bus, 0]);
~config[\drivingBase][\serum]= VSTPluginController(~config[\drivingBase][\synth],\serum).open("Serum", verbose: true, multiThreading:true, editor:true);
~config[\drivingBase][\eq]=VSTPluginController(~config[\drivingBase][\synth], \eq).open("TDR Nova", verbose: true, multiThreading:true, editor:true);
)
(
~openEditors= {arg key;
~config[\drivingBase][\serum].editor;
~config[\drivingBase][\eq].editor;
};
~pathExp= {arg key;
	~path++key++".fxp".postln
}
)
//~fx.gui;
~config[\drivingBase][\serum].getProgramData({|data| ~serumData = data}, async: true);
~serumData.postln;
~config[\drivingBase][\serum].setProgramData(~serumData);
~config[\drivingBase][\serum].info.printPresets;
~config[\drivingBase][\serum].savePreset("drivingBase");
~config[\drivingBase][\serum].loadPreset("drivingBase");

~config[\drivingBase][\eq].info.printPresets;
~config[\drivingBase][\eq].savePreset("drivingBase");
~config[\drivingBase][\eq].loadPreset("drivingBase");
~path = PathName(thisProcess.nowExecutingPath).parentPath++"data/";
~config[\drivingBase][\serum].writeProgram(~path++"drivingBase.fxp");
~config[\drivingBase][\serum].readProgram(~path++"drivingBase.fxp");
(
p = Pbind(
    \type, \vst_midi,
    \vst, ~config[\drivingBase][\serum], // the VSTPluginController instance
    \midicmd, \noteOn, // the default, can be omitted
    \chan, 0, // MIDI channel (default: 0)
    \midinote, Pseq(#[32, 35, 33, 37], inf),
    \dur, 1,
    \amp, Pexprand(0.5, 1.0, inf)
).play(quant: 1);
)
p.stop;
(
p.free;
~config[\drivingBase][\synth].free;
~config[\drivingBase][\serum].free;
~config[\drivingBase][\eq].free;
)
~openEditors.(\drivingBase)
~pathExp.(\drivingBase)
//////////////////////////////////////////////////////////////
(
var h, k, path, testData, loadData;
testData = Int8Array();
testData.addAll([1,2,3,4]);
testData.postln;
path = PathName(thisProcess.nowExecutingPath).parentPath++"data/";
path.mkdir();
path = path++"serum.dat";
path.postln;
h = File(path, "wb");
//h.inspect;
// h.write( testData);
//h.write( FloatArray[1.1, 2.2, 3.3, pi, 3.sqrt] );
testData.length.do({h.putInt8()})
h.flush;
h.close;

/*loadData = Int8Array();
k = File(path++"serum.dat", "rb");
(k.length).do({ loadData.add(k.getInt8) });
loadData.postln;
k.close;*/
)
