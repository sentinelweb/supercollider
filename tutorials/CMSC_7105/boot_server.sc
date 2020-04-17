// from CMSC7105_sc_tutorial.pdf

{// making a custom server
	o = ServerOptions.new;
	o.outDevice="Robert Munro’s Beats Studi";
	o.sampleRate = 44100;
	o.numBuffers = 1024 * 16;
	t = Server(\Local3, NetAddr("127.0.0.1", 57111), o);
	t.makeWindow();
	t.boot();
}

t.quit;
// default server
Server.default = s = Server.internal.boot;
s.options.outDevice="Robert Munro’s Beats Studi";

{SinOsc.ar(LFNoise0.ar([10, 15], 400, 800), 0, 0.3)}.play(t)



{
RLPF.ar(
	LFSaw.ar([8, 12], 0, 0.2), abs(LFNoise1.ar([2, 3].choose, 1500, 1600)), 0.05
)
}.play(t)

// ghosty sound
{
	CombN.ar(
		SinOsc.ar(
			LFNoise1.kr(
				4, // freq
				24, // range
				LFSaw.kr(
					[8,7.23],//freq
					0,
					3, // range
					80 // offset
				)
			).midicps,
		0,
		0.04 ),
	0.2, // max delay
	0.2, // actual delay
	4 // decay
) }.play(t)

s.boot
s.quit


{SinOsc.ar([500, 500], 0, 0.4, 0)}.scope(2)
{SinOsc.ar(500, 0, 1.0)}.scope(1)

// mouse control
// make a patch that use the x coord to control frequency/note/pitch
(
{
	Out.ar(0, In.ar(MouseY.kr(15, 23).div(1), 1)*0.8)
}.scope;


{
	Out.ar(16, [SinOsc.ar, Saw.ar, Pulse.ar, LFTri.ar, LFNoise0.ar(200), Dust.ar(100), PinkNoise.ar, WhiteNoise.ar])
}.play(t)
)

{
	SinOsc.ar(Pulse.kr(5, 0.7, 5, 5))
}.play(t)

