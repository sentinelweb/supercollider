// cp /Users/robmunro/Library/Application\ Support/SuperCollider/Extensions/Custom/SequenceRM.sc projects/melodic_techno/
Seqr[] {//extend SimmpleNumber remove v
    var <allOfThem;
	var ctr = nil;

	add { |item|
        allOfThem = allOfThem.add(item)
    }

	next {
		if (ctr.isNil) {ctr=0}
		{ctr = (ctr + 1).mod(allOfThem.size)}
		^allOfThem[ctr];
	}

	v {
		^if (ctr.isNil)
		{-1}
		{allOfThem[ctr]}
	}

	offset {|off = 0|
		^( off + this.v );
	}

	pos {
		["pos:", ctr, "val:", this.v].postln;
		^this;
	}
}