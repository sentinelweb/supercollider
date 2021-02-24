(
SynthDef(\insert, { arg bus;
    ReplaceOut.ar(bus, VSTPlugin.ar(In.ar(bus, 2), 2));
}).add;
)

VSTPlugin.search(verbose:true);
~synth = Synth(\insert, [\bus, 0]);

// create the synth:
~synth = Synth(\insert, [\bus, 0]);
// get a handle to the VSTPlugin:
~fx = VSTPluginController(~synth);
// open a plugin by name/key (might require VSTPlugin.search!)
~fx.open("Serum", verbose: true, multiThreading:true, editor:true);
~fx.open("TDR Nova", verbose: true, multiThreading:true, editor:true);
// alternatively, you can open a plugin by its file path
// (this only works if the file contains a single plugin, like most VST2.x plugins)
~fx.open("⁨/Library/Audio/Plug-Ins/VST/TDR Nova.vst/Contents/MacOS/TDR Nova⁩", verbose: true, multiThreading:true);
~fx.editor;
~fx.gui;
~fx.getProgramData({|data| data.postln}, async: true)
(
~synth.free;
~fx.free;
)