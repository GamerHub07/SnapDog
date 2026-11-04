import os
import math
import wave
import struct

os.makedirs('assets/audio', exist_ok=True)
SAMPLE_RATE = 44100

def write_wav(filename, samples):
    filepath = os.path.join('assets/audio', filename)
    with wave.open(filepath, 'w') as wav:
        wav.setnchannels(1)  # mono
        wav.setsampwidth(2)  # 16-bit
        wav.setframerate(SAMPLE_RATE)
        # normalize samples
        max_val = max(abs(s) for s in samples) if samples else 1.0
        if max_val == 0:
            max_val = 1.0
        
        packed = bytearray()
        for s in samples:
            # Scale to 85% of int16 max to prevent clipping
            norm = (s / max_val) * 0.85
            int_val = int(norm * 32767.0)
            int_val = max(-32768, min(32767, int_val))
            packed.extend(struct.pack('<h', int_val))
        wav.writeframes(packed)
    print(f"Generated {filepath} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.2f}s)")

# 1. cross_pop.wav: soft pop/click (~0.07s)
def gen_cross_pop():
    dur = 0.07
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 60.0) # fast decay
        # Frequency drops from 600Hz to 160Hz
        freq = 600.0 - (440.0 * (t / dur))
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        s = math.sin(phase) * env
        samples.append(s)
    return samples

# 2. dog_chime.wav: pleasant confirmation chime (~0.35s)
def gen_dog_chime():
    dur = 0.35
    num_samples = int(dur * SAMPLE_RATE)
    samples = [0.0] * num_samples
    
    # Note 1: E5 (659.25 Hz) at t=0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env1 = math.exp(-t * 14.0)
        s1 = (math.sin(2 * math.pi * 659.25 * t) + 0.3 * math.sin(2 * math.pi * 1318.5 * t)) * env1
        samples[i] += s1 * 0.7
        
    # Note 2: B5 (987.77 Hz) at t=0.08
    start2 = int(0.08 * SAMPLE_RATE)
    for i in range(start2, num_samples):
        t = (i - start2) / SAMPLE_RATE
        env2 = math.exp(-t * 9.0)
        s2 = (math.sin(2 * math.pi * 987.77 * t) + 0.35 * math.sin(2 * math.pi * 1975.5 * t)) * env2
        samples[i] += s2 * 0.9
        
    return samples

# 3. wrong_bloop.wav: gentle descending bloop (~0.28s)
def gen_wrong_bloop():
    dur = 0.28
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # smooth attack and gentle decay
        attack = min(1.0, t / 0.015)
        decay = math.exp(-t * 8.0)
        env = attack * decay
        # descending frequency: 320 Hz down to 130 Hz
        freq = 130.0 + (190.0 * math.exp(-t * 10.0))
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        # add a touch of warm 2nd harmonic
        s = (math.sin(phase) + 0.2 * math.sin(2 * phase)) * env
        samples.append(s)
    return samples

# 4. undo_pop.wav: soft reverse pop (~0.10s)
def gen_undo_pop():
    dur = 0.10
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # rising envelope then rapid decay
        env = math.sin(math.pi * (t / dur)) ** 1.5
        # rising frequency from 160Hz to 440Hz
        freq = 160.0 + (280.0 * (t / dur))
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        s = math.sin(phase) * env
        samples.append(s)
    return samples

# 5. hint_sparkle.wav: magical sparkle sound (~0.45s)
def gen_hint_sparkle():
    dur = 0.45
    num_samples = int(dur * SAMPLE_RATE)
    samples = [0.0] * num_samples
    pitches = [784.0, 987.77, 1174.66, 1568.0, 1975.5] # G5, B5, D6, G6, B6
    stagger = 0.06
    
    for idx, freq in enumerate(pitches):
        start_idx = int(idx * stagger * SAMPLE_RATE)
        for i in range(start_idx, num_samples):
            t = (i - start_idx) / SAMPLE_RATE
            env = math.exp(-t * 15.0)
            s = (math.sin(2 * math.pi * freq * t) + 0.25 * math.sin(2 * math.pi * freq * 2 * t)) * env
            samples[i] += s * 0.5
            
    return samples

# 6. puzzle_complete.wav: cheerful celebration sound (~0.75s)
def gen_puzzle_complete():
    dur = 0.75
    num_samples = int(dur * SAMPLE_RATE)
    samples = [0.0] * num_samples
    notes = [
        (0.00, 523.25, 0.5), # C5
        (0.10, 659.25, 0.5), # E5
        (0.20, 784.00, 0.6), # G5
        (0.30, 1046.5, 0.9), # C6
        (0.30, 1318.5, 0.5), # E6
    ]
    for start_t, freq, amp in notes:
        start_i = int(start_t * SAMPLE_RATE)
        for i in range(start_i, num_samples):
            t = (i - start_i) / SAMPLE_RATE
            env = math.exp(-t * 6.0)
            s = (math.sin(2 * math.pi * freq * t) + 0.2 * math.sin(2 * math.pi * freq * 2 * t)) * env * amp
            samples[i] += s
            
    return samples

# 7. button_click.wav: subtle UI click (~0.04s)
def gen_button_click():
    dur = 0.04
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 90.0)
        freq = 1100.0 - (600.0 * (t / dur))
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        s = math.sin(phase) * env
        samples.append(s)
    return samples

write_wav('cross_pop.wav', gen_cross_pop())
write_wav('dog_chime.wav', gen_dog_chime())
write_wav('wrong_bloop.wav', gen_wrong_bloop())
write_wav('undo_pop.wav', gen_undo_pop())
write_wav('hint_sparkle.wav', gen_hint_sparkle())
write_wav('puzzle_complete.wav', gen_puzzle_complete())
write_wav('button_click.wav', gen_button_click())
print("All audio generated successfully!")
