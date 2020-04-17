// "http://composerprogrammer.com/teaching/supercollider/sctutorial/10.1 Open Sound Control.html"
//
//
//

n = NetAddr("192.168.1.71", 57200);// Say this is remote but it's not (was local addr at the time).
n = NetAddr("192.168.1.71", 57110);
n = NetAddr("127.0.0.1", 57110);
p = Server.new("OSC", n);
p.makeWindow; // make the gui window
p.boot; // boot it
o = OSCFunc({ arg x,y; [x,y].postln; }, '/multi/1', n);
o = OSCFunc({ arg msg, time, addr, recvPort; [msg, time, addr, recvPort].postln; }, '/multi/1', n);
p.addr
o.free;    // remove the OSCFunc when you are done.
p.quit;p.free;
OSCFunc.trace(true);
//////////////////////////////////////////////
(
OSCdef.new(\new12a,
	{arg  x,y;
		x.postln ;
		y.postln ;
		},
	"/multi/1"
);
)

////////////////////////////////////////////////////////
// this example is basically like OSCFunc.trace but filters out
// /status.reply messages
(
f = { |msg, time, addr|
    if(msg[0] == '/multi/1') {
        "time: % sender: %\nmessage: %\n".postf(time, addr, msg);
    }
};

);
f.free
// post event
thisProcess.addOSCRecvFunc(f);
// stop posting.
thisProcess.removeOSCRecvFunc(f);
///////////////////////////////////////////////////////

["d_load", "synthdefs/void.scsyndef",
				["/multi/1", 60, 80] // completion message
		]
///////////////////////////////////////////////
(
    SynthDef( "guru2", { arg mfreq=40;
        var env, amp;

        env = Env.perc( 0, 0.2 );
        amp = EnvGen.kr(env, 1, doneAction:2);

        Out.ar([0,1], SinOsc.ar( mfreq.midicps ) * amp * 0.5);
    }).send(s);
)

n = NetAddr("192.168.1.71", 8000)
o = OSCresponderNode(nil, '/multi/1', { |x,y| Synth( "guru2", [\mfreq, x]);  }).add;

o.remove
o.free
///////////////////////////////////////
(
a = {
	var	trig = Dust.kr(8),
	decay = Decay2.kr(trig, 0.01, 0.1),
	sig = SinOsc.ar(TExpRand.kr(200, 600, trig), 0, 0.1) * decay;
	SendReply.kr(trig, '/multi/1', trig);
	sig ! 2
}.play;

o = OSCpathResponder(s.addr, '/multi/1', { |time, thisResponder, msg|
	msg.postln;
}).add;
)

a.free; o.remove;