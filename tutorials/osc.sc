s.boot


{  SinOsc .ar ( 440, 0, 1, 0 )  } .play

play{x=0; (60..100).do{|f| x=SinOsc.ar(f+[0,f], x*Line.kr(1,5,60,doneAction:2))}; cos(x+Ringz.ar(Impulse.ar(2),45,0.3,3))};
