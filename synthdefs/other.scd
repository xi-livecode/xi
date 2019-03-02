(
SynthDef(\kick, { |out=0, amp=1, freq=70, attack=0.001, xstart=1, xend=0.25, xdur=0.05, release=0.15, pan=0.5|
  var sig = SinOsc.ar(freq * XLine.ar(xstart, xend, xdur));
  var env = EnvGen.ar(Env.perc(attack, release, 1, -4), doneAction: 2);
  sig = Pan2.ar(sig, pan) * env;
  sig = (sig * 5).tanh;
  OffsetOut.ar(out, Pan2.ar(sig * env, pan, amp * 0.25));
}).add;

SynthDef(\snare, { |out=0, amp=1, freq=1000, freq2=180, attack=0.01, release=0.2, pan=0|
  var snd1 = WhiteNoise.ar(amp);
  var snd2 = SinOsc.ar(freq2, 0, amp);
  var env = Env.perc(attack, release).kr(doneAction: 2);
  var sum = RHPF.ar(snd1 * env, 2500) + LPF.ar(snd2 * env, 1500);
  OffsetOut.ar(out, Pan2.ar(sum, pan, amp * 0.1))
}).add;

SynthDef(\bassy, { |out=0, amp=1, freq=440, hctf=1000, lctf=5000, rq=0.5, attack=0.001, release=1, mul=1, pan=0.5|
  var sig = Saw.ar(freq);
  var env = EnvGen.ar(Env.perc(attack, release), doneAction: 2);
  sig = mul * BHiPass.ar(RLPF.ar(sig, lctf * env, rq), hctf, rq);
  OffsetOut.ar(out, Pan2.ar(sig * env, pan, amp * 0.1))
}).add;

SynthDef(\sin, { |out, amp=1, attack=0.001, release=1, sustain=1, pan=0, accelerate=0, freq=440, detune=0.1|
  var env = EnvGen.ar(Env.perc(attack, release, 1, -4), timeScale: sustain / 2, doneAction: 2);
  var sound = SinOsc.ar([freq, freq+detune] * Line.kr(1,1+accelerate, sustain));
  OffsetOut.ar(out, Pan2.ar(sound * env, pan, amp));
}).add;

SynthDef(\fm, { |out, amp=1, attack=0.001, sustain=1, pan=0, accelerate=0, freq=440, carPartial=1, modPartial=1, index=3, mul=0.1, detune=0.1|
  var env = EnvGen.ar(Env.perc(attack, 0.999, 1, -3), timeScale: sustain / 2, doneAction: 2);
  var mod = SinOsc.ar(freq * modPartial * Line.kr(1,1+accelerate, sustain), 0, freq * index * LFNoise1.kr(5.reciprocal).abs);
  var car = SinOsc.ar(([freq, freq+detune] * carPartial) + mod, 0, mul);
  OffsetOut.ar(out, Pan2.ar(car * env, pan, amp));
}).add;

SynthDef(\saw, {|out, amp=1, attack=0.001, sustain=1, pan=0, accelerate=0, freq=440, detune=0.1|
  var env = EnvGen.ar(Env.perc(attack, 0.999, 1, -4), timeScale: sustain / 2, doneAction: 2);
  var sound = Saw.ar([freq, freq + detune] * Line.kr(1, 1 + accelerate, sustain));
  OffsetOut.ar(out, Pan2.ar(sound * env, pan, amp * 0.1));
}).add;
)
