AkaiAPC40 {
	classvar ctlMap, ctlChMap, noteMap, noteChMap, colorMap;
	var indexOfAkai = 0, midiOut, inFunc, outFunc;

	*initClass {
        ctlMap = (
			/*top nobs*/ \k1:48,\k2:49,\k3:50,\k4:51,\k5:52,\k6:53,\k7:54,\k8:55,
			/*side nobs*/ \sk1:16,\sk2:17,\sk3:18,\sk4:19,\sk5:20,\sk6:21,\sk7:22,\sk8:23,
			/*sliders*/ \s1:7,\s2:7,\s3:7,\s4:7,\s5:7,\s6:7,\s7:7,\s8:7,
			\master:14, \cross:15,\cue:47, \tempo: 13
		);
		ctlChMap = (
			\s1:0,\s2:1,\s3:2,\s4:3,\s5:4,\s6:5,\s7:6,\s8:7,
		);
		noteMap = (
			\grid11:0,\grid21:1,\grid31:2,\grid41:3,\grid51:4,\grid61:5,\grid71:6,\grid81:7,
			\grid12:8,\grid22:9,\grid32:10,\grid42:11,\grid52:12,\grid62:13,\grid72:14,\grid82:15,
			\grid13:16,\grid23:17,\grid33:18,\grid43:19,\grid53:20,\grid63:21,\grid73:22,\grid83:23,
			\grid14:24,\grid24:25,\grid34:26,\grid44:27,\grid54:28,\grid64:29,\grid74:30,\grid84:31,
			\grid15:32,\grid25:33,\grid35:34,\grid45:35,\grid55:36,\grid65:37,\grid75:38,\grid85:39,
			\clipStop1:52,\clipStop2:52,\clipStop3:52,\clipStop4:52,\clipStop5:52,\clipStop6:52,\clipStop7:52,\clipStop8:52,

		);
		noteChMap = (
			\clipStop1:0,\clipStop2:1,\clipStop3:2,\clipStop4:3,\clipStop5:4,\clipStop6:5,\clipStop7:6,\clipStop8:7,
		);
		colorMap = (
			\red:5,\orange:9,\yellow:13,\yel_grn:75,\green:17,\teal:65,\cyan:37,\blue:45,\move:53,\pink:57,\purple:49, \white:119, \off:0
		);
    }

	*new {
        ^super.new.init;
    }

	controlIn {|val, num, chan, src|
		var func = inFunc[\control][this.key(num,chan)]??inFunc[\control][this.key(num,\all)];
		~val = val;
		if (func.notNil) {currentEnvironment.use(func);this.update} {["akai-in-cc", "v", val, "ctl", num, "ch",chan, "src", src].postln;}

	}

	noteOnIn {|val, note, chan, src|
		var func = inFunc[\noteOn][this.key(note,chan)]??inFunc[\noteOn][this.key(note,\all)];
		~val = val;
		if (func.notNil) {currentEnvironment.use(func);this.update} {["akai-in-no", "v", val, "note", note, "ch",chan, "src", src].postln;}

	}

	noteOffIn {|val, note, chan, src|
		var func = inFunc[\noteOff][this.key(note,chan)]??inFunc[\noteOff][this.key(note,\all)];
		~val = val;
		if (func.notNil) {currentEnvironment.use(func);this.update} {["akai-in-nf", "v", val, "note", note, "ch",chan, "src", src].postln;}

	}

	init {
		MIDIClient.init();
		indexOfAkai = MIDIClient.sources.detectIndex({arg ep; ep.name.contains("APC40 mkII")});
		MIDIIn.connect(indexOfAkai, MIDIClient.sources[indexOfAkai]);
		MIDIdef.cc(\akaiController, {|v,cn,ch,id| this.controlIn(v,cn,ch,id)}, srcID: this.uidin);
		MIDIdef.noteOn(\akaiNoteOn, {|v,n,ch,id| this.noteOnIn(v,n,ch,id)}, srcID: this.uidin);
		MIDIdef.noteOff(\akaiNoteOff, {|v,n,ch,id| this.noteOffIn(v,n,ch,id)}, srcID: this.uidin);

		inFunc = (\control:IdentityDictionary(), \noteOn:IdentityDictionary(), \noteOff:IdentityDictionary());
		outFunc = (\control:(), \note:());

		midiOut = MIDIOut.new(indexOfAkai, this.uidout);
		midiOut.latency = 0.0;
		midiOut.program(0);// sets the controller to work simply - no state saving buttons & right knobs
	}

	uidin {
		^MIDIClient.sources.at(indexOfAkai).uid;
	}

	uidout {
		^MIDIClient.destinations.at(indexOfAkai).uid;
	}

	channel {|bank|
		midiOut.program(bank);
	}

	key {|n,c|
		^("n"++n++"c"++c).asSymbol
	}

	addCtlIn{|button, func|
		var num = ctlMap[button];
		var chan = ctlChMap[button]?\all;
		inFunc[\control].add(this.key(num,chan) -> func);
	}

	addNoteIn{|button, func, off = false|
		var num = noteMap[button];
		var chan = noteChMap[button]?\all;
		inFunc[\noteOn].add(this.key(num,chan) -> func);
		if (off) {inFunc[\noteOff].add(this.key(num,chan) -> func);}
	}

	addNoteOut {|key,func|
		outFunc[\note].add(key -> func);
	}

	update {
		outFunc[\note].keys.do{arg key;
			var color = outFunc[\note][key].value;
			if (color.isInteger.not) {color = colorMap[color]};
			if (color.isInteger) {midiOut.noteOn(noteChMap[key]?0, noteMap[key], color);}
			{(color++" is not valid note:"++key).postln}
		}
	}

	dump{
		inFunc.postln;
		outFunc.postln;
	}

	togPdef{|pdefkey|
		^{if (Pdef(pdefkey).isPlaying){Pdef(pdefkey).stop}{Pdef(pdefkey).play}}
	}

}