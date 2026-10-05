"""Compose/render Paper Skies: an original, sample-free 100 BPM electronic loop.

Requires Python, numpy and scipy. Run from anywhere; output is assets/audio.
No downloaded music, samples, or artist imitation. Circular tails preserve looping.
"""
from pathlib import Path
import json
import wave
import numpy as np
from scipy.signal import butter, sosfilt

SR = 44100
BPM = 100
BARS = 32
BEAT = 60 / BPM
N = round(BARS * 4 * BEAT * SR)
RNG = np.random.default_rng(71024)
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/audio'


def hz(note):
    return 440 * 2 ** ((note - 69) / 12)


def lowpass(signal, cutoff):
    return sosfilt(butter(2, cutoff, fs=SR, output='sos'), signal)


def place(bus, signal, beat, gain=1, pan=0):
    """Wrap releases into the beginning so the render is a steady-state loop."""
    start = round(beat * BEAT * SR) % N
    stereo = signal[:, None] * np.array([
        np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)
    ])[None, :] * gain
    first = min(len(signal), N - start)
    bus[start:start + first] += stereo[:first]
    if first < len(signal):
        bus[:len(signal) - first] += stereo[first:]


def tone(note, duration, kind):
    t = np.arange(round(duration * SR)) / SR
    f = hz(note)
    if kind == 'pad':
        signal = (np.sin(2*np.pi*f*t) + .32*np.sin(2*np.pi*f*1.002*t)
                  + .17*np.sin(2*np.pi*f*2*t) + .08*np.sin(2*np.pi*f*3*t)) / 1.57
        env = np.minimum(t/.4, 1) * np.minimum((duration-t)/.9, 1)
    elif kind == 'pluck':
        signal = (np.sin(2*np.pi*f*t) + .28*np.sin(2*np.pi*f*2*t)*np.exp(-t*5)
                  + .1*np.sin(2*np.pi*f*3*t)*np.exp(-t*8))
        env = np.minimum(t/.006, 1) * np.exp(-t*3.8) * np.minimum((duration-t)/.08,1)
    else:
        signal = np.sin(2*np.pi*f*t) + .2*np.sin(2*np.pi*2*f*t)
        env = np.minimum(t/.008,1)*np.minimum((duration-t)/.06,1)*np.exp(-t*.8)
    return (signal * env).astype(np.float32)


def drum(kind):
    length = {'kick': .36, 'clap': .18, 'hat': .09, 'open': .23}[kind]
    t = np.arange(round(length * SR)) / SR
    noise = RNG.standard_normal(len(t))
    if kind == 'kick':
        phase = 2*np.pi*(49*t + (110-49)*.017*(1-np.exp(-t/.017)))
        signal = np.sin(phase)*np.exp(-t*13) + .05*noise*np.exp(-t*180)
    elif kind == 'clap':
        noise = lowpass(noise, 5500) - lowpass(noise, 900)
        env = np.exp(-t*28)*(.35+.65*np.sin(2*np.pi*80*t)**2)
        signal = noise*env
    else:
        noise = lowpass(noise, 10000) - lowpass(noise, 6500)
        signal = noise*np.exp(-t*(55 if kind == 'hat' else 19))
    signal *= np.minimum(t/.0015,1)*np.minimum((length-t)/.008,1)
    return signal.astype(np.float32)


def main():
    pads = np.zeros((N,2), np.float32)
    notes = np.zeros_like(pads)
    rhythm = np.zeros_like(pads)
    bass = np.zeros_like(pads)
    # Dmaj7, Amaj9, Eadd9, Bm7: wide voicings with an unhurried two-bar rhythm.
    chords = [(62,66,69,73),(61,64,68,71),(59,64,66,68),(59,62,66,69)]
    roots = [38,33,40,35]
    kick, clap, hat, opened = [drum(k) for k in ('kick','clap','hat','open')]
    for bar in range(BARS):
        chord_index = (bar//2)%4
        chord = chords[chord_index]
        beat = bar*4
        section = bar//8
        if bar%2 == 0:
            for j, note in enumerate(chord):
                place(pads, tone(note,8*BEAT+1,'pad'),beat,gain=.085,pan=(j-1.5)/3)
        # The middle eight bars relax the drums; the harmonic loop stays continuous.
        for b in range(4):
            if section != 2 or b in (0,2):
                place(rhythm,kick,beat+b,.52)
            if b in (1,3):
                place(rhythm,clap,beat+b,.15 if section!=2 else .08,pan=.06)
            if section!=2:
                place(rhythm,opened,beat+b+.5,.055,pan=.28)
            for half in (0,.5):
                place(rhythm,hat,beat+b+half+.015,.055 if half else .025,pan=-.35)
        for offset, length in ((0,.65),(.75,.4),(1.5,.6),(2.75,.45),(3.5,.4)):
            place(bass,tone(roots[chord_index],length*BEAT,'bass'),beat+offset,.28)
        pattern = [(0,0),(.75,2),(1.5,1),(2.5,3),(3.25,2)]
        for step,(offset,index) in enumerate(pattern):
            if section==2 and step%2:
                continue
            place(notes,tone(chord[index]+12,1.4,'pluck'),beat+offset,
                  .095 if bar%2==0 else .075,pan=(-.3 if step%2 else .3))
        if section in (1,3) and bar%2:
            for offset,note in ((.5,chord[2]+12),(2,chord[1]+12),(3,chord[0]+12)):
                place(notes,tone(note,1.7,'pluck'),beat+offset,.055,pan=-.15)
    # Tempo-synced stereo echoes and a quiet diffuse ambience, all circular.
    dry = notes.copy()
    for delay,level in ((.75,.23),(1.5,.12),(2.25,.065)):
        notes += np.roll(dry[:,::-1],round(delay*BEAT*SR),axis=0)*level
    wet = pads+notes
    ambience = np.zeros_like(wet)
    for seconds,level in ((.113,.12),(.197,.09),(.307,.075),(.431,.05),(.613,.04)):
        ambience += np.roll(wet[:,::-1],round(seconds*SR),axis=0)*level
    time = np.arange(N)/SR
    duck = (1-.23*np.exp(-(time%BEAT)/.13)).astype(np.float32)[:,None]
    mix = rhythm + bass*duck + (pads+notes+ambience)*duck
    mix -= mix.mean(axis=0)
    mix = np.tanh(mix*1.1)
    mix *= .79 / np.max(np.abs(mix))
    # A tiny boundary bridge prevents a waveform discontinuity at the loop point.
    width = round(.003*SR)
    boundary = (mix[0]+mix[-1])/2
    mix[:width] += (boundary-mix[0]) * np.linspace(1,0,width)[:,None]
    mix[-width:] += (boundary-mix[-1]) * np.linspace(0,1,width)[:,None]
    pcm = np.round(np.clip(mix,-1,1)*32767).astype('<i2')
    OUT.mkdir(parents=True,exist_ok=True)
    target = OUT/'PaperSkies.wav'
    with wave.open(str(target),'wb') as audio:
        audio.setnchannels(2);audio.setsampwidth(2);audio.setframerate(SR)
        audio.writeframes(pcm.tobytes())
    report = dict(title='Paper Skies',bpm=BPM,bars=BARS,duration_seconds=N/SR,
                  sample_rate=SR,channels=2,bit_depth=16,file_bytes=target.stat().st_size,
                  peak_dbfs=round(float(20*np.log10(np.max(np.abs(mix)))),2),
                  rms_dbfs=round(float(20*np.log10(np.sqrt(np.mean(mix**2)))),2),
                  clipped_samples=int(np.sum(np.abs(pcm.astype(np.int32))>=32767)),
                  loop_boundary_delta=int(np.max(np.abs(pcm[0].astype(int)-pcm[-1].astype(int)))),
                  composition='Original algorithmic composition; synthesized instruments; no external samples')
    assert report['clipped_samples']==0 and report['file_bytes']<20_000_000
    assert report['loop_boundary_delta']<=1
    (OUT/'PaperSkies.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,indent=2))


if __name__=='__main__':
    main()
