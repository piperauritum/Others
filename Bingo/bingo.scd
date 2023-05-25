/*
Party (2020) by Kokichi Yanagisawa

"NEXT" Button : Counts 20 pitches
"ONE to WIN!" Button : Counts 50 pitches
Sequences of the same pitch are ignored.

Premiered at Ftarri, Tokyo, Nov 22, 2020
- Kokichi Yanagisawa (electric guitar)
- Shibatetsu (piano)
- Takumi Ikeda (computer)
*/

(
~num_balls = 75;

/* window */
r = Window.availableBounds;
w = Window(\bingo, Rect(0, 0, r.width, r.height)).front;
w.background = Color.black;
w.alwaysOnTop = true;
w.onClose = { CmdPeriod.run };
r = w.bounds;

b = Button(w, Rect(r.width*0.8, r.height*0.75, r.width*0.2, r.height*0.1));
b.string = "NEXT";
b.font = Font("Arial", 40);
b.action = {
	~num_notes = 20;
	~bingo.start;
};

c = Button(w, Rect(r.width*0.8, r.height*0.85, r.width*0.2, r.height*0.1));
c.string = "ONE to WIN!";
c.font = Font("Arial", 40);
c.action = {
	~num_notes = 50;
	~bingo.start;
};

Array.fill(5, {|i|
	a = StaticText(w, Rect(0, r.height/10*i, r.width/16, r.height/10));
	a.font = Font("Arial", 60);
	a.align = \center;
	a.string = "BINGO".at(i);
	a.stringColor = [Color.red, Color.yellow, Color.green, Color.blue, Color.magenta][i];
});

~ntxt = Array.fill(~num_balls, {|i|
	var txt;
	txt = StaticText(w, Rect(r.width/16*(i%15+1), r.height/10*((i/15).floor), r.width/16, r.height/10));
	txt.stringColor = Color.white;
	txt.font = Font("Arial", 60);
	txt.align = \center;
	txt.string = i+1;
});

~ctxt = Array.fill(2, {|i|
	var txt;
	a = StaticText(w, Rect(r.width/3*i, r.height/2, r.width/3, r.height/6));
	a.stringColor = Color.white;
	a.font = Font("Arial", 40);
	a.align = \center;
	a.string = ["Call", "Remaining Notes"][i];
	txt = StaticText(w, Rect(r.width/3*i, r.height*0.6, r.width/3, r.height/4));
	txt.stringColor = Color.white;
	txt.font = Font("Arial", 190);
	txt.align = \center;
});


/* lottery */
~balls = Array.fill(~num_balls, {|i| i + 1});
~bid = 0;

~call = {|bid|
	~bingo.pause;
	s.sendMsg(\s_new, \wav, -1, 0, 0);
	x = ~balls[~bid];
	x.postln;
	defer{
		~ntxt[x-1].stringColor = Color.black;
		~ntxt[x-1].background = Color.green;
		~ctxt[0].string = x;
		~ctxt[0].stringColor = Color.magenta;
	};
	~balls.removeAt(~bid);
};

~bingo = Task({
	~balls.postln;
	~sel = nil;
	~past = nil;

	defer{
		~ctxt[0].stringColor = Color.white;
		~ctxt[1].string = ~num_notes;
	};

	inf.do({
		~past = ~sel;
		~bid = ((~balls.size-1).rand.floor + ~bid + 1) % ~balls.size;
		~sel = ~balls[~bid] - 1;
		defer{
			if(~past != nil){
				~ntxt[~past].stringColor = Color.white;
				~ntxt[~past].background = Color.clear;
			};
			~ntxt[~sel].stringColor = Color.black;
			~ntxt[~sel].background = Color.yellow;
		};
		1.wait;
	});
});


/* count notes */
~mem = [];
o.free;
o = OSCFunc({|msg|
	if(~bingo.isPlaying){
		if((~num_notes > 0), {

			// Excludes sequences of the same pitch
			if(~mem.indexOf(msg[3])==nil, {
				if(~mem.size==8, { ~mem.removeAt(0) });
				~mem = ~mem.add(msg[3]);
				~num_notes = ~num_notes - 1;
				defer{ ~ctxt[1].string = ~num_notes };
			});
		}, {
			~call.(~bid);
		});
	};
}, '/ping');


/* sounds */
// s.sendMsg(\b_allocRead, 0, "test.wav".resolveRelative);	// use test sound
s.sendMsg(\b_allocRead, 10, "bingo.wav".resolveRelative);

SynthDef(\wav, {
	a = PlayBuf.ar(1, 10, 1.2, doneAction: 2);
	Out.ar(0, a!2);
}).add;


/* listening */
SynthDef(\listen, {
	a = SoundIn.ar();
	// a = PlayBuf.ar(1, loop:1);	// use test sound
	b = Pitch.kr(a, median: 8)[0];
	c = Changed.kr(cpsmidi(b), 1);
	SendReply.kr(c, '/ping', b.cpsmidi.round);
	// Out.ar(0, a!2);				// listen test sound
}).play;
)