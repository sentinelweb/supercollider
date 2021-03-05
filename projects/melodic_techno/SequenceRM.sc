Seqr[] {
    var <allOfThem;
	var ctr = 0;

	add { |item|
        allOfThem = allOfThem.add(item)
    }

	next {
		var r = allOfThem[ctr];
		ctr = (ctr + 1).mod(allOfThem.size)
		^r;
	}

	v {
		^allOfThem[ctr];
	}

	offset {|off = 0|
		^( off + allOfThem[ctr] );
	}
}