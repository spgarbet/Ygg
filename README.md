# Ygg Drone Synthesizer Engine

A Lyra-8 inspired drone synthesizer for SuperCollider and Norns, designed for MPE controllers and evolving spectral harmonies.

**WORK IN PROGRESS YOUR MILEAGE MAY VARY** This is the bleeding edge.

The original supercollider code will be removed in a future version.

## Overview

Ygg is an 8-voice polyphonic drone synthesizer with:
- **Voice stealing** from oldest voice (ring buffer allocation)
- **MPE support** (pitch bend and pressure per note)
- **Cross-modulation matrix** with 3 routing modes
- **Harmonics morphing** (sine → square → saw)
- **Leslie-style vibrato** for stereo expansion
- **Hold mode** for sustained drones
- **2-tap modulated delay**
- **Tube-style distortion**
- **Global LFO** with 4 modes

## Architecture

### Signal Flow

```
8 Voices (to individual buses) → Voice Mixer (sum to stereo) → Delay → Distortion → Main Out
                                      ↓
                                 Cross-Modulation (feedback)
                                      ↑          ↑        
                                  Global LFO  Main Out
```

### Voice Parameters (per voice)

- `freq` - Base frequency in Hz
- `amp` - Amplitude (0-1)
- `attack` - Attack time in seconds
- `release` - Release time in seconds
- `hold` - Hold depth (0-1)
- `vibrato_freq` - Vibrato rate in Hz (0 = mono, >0 = stereo)
- `vibrato_depth` - Depth of Vibrato(0, 1)
- `harmonics` - Waveform morph (0=sine, 0.5=square, 1.0=saw)
- `pitch_bend` - MPE pitch bend in semitones
- `pressure` - MPE pressure (0-1, scales amplitude)
- `voice_mod_source` - Modulation source (0=crossover voice, 1=lfo, 2=predelay, 3=predrive, 4=main)

### Global Parameters

#### Cross-Modulation 

- `mod_depth` (0-1)
- `routing`

Voice pairs: 1-2, 3-4, 5-6, 7-8

**Self (0)**: 1 ↔ 2, 3 ↔ 4, 5 ↔ 6, 7 ↔ 8, 
**Neighbor (1)**: 1-2 ↔ 3-4, 5-6 ↔ 7-8  
**Cross (2)**: 1-2 ↔ 5-6, 3-4 ↔ 7-8  
**Loop (3)**: 1-2 → 3-4 → 5-6 → 7-8 → 1-2

### LFO Modes

- freqA
- freqB
- style

- **Single (0)**: Use freqA only
- **Sum (1)**: freqA + freqB
- **Product (2)**: freqA × freqB
- **FM (3)**: Soft frequency modulation

### Delay Parameters

- `delay_time` - Two taps times (0-2 seconds)
- `delay_mod` - Two taps modulation depth
- `delay_fb` - Feedback amount (0-1)
- `delay_mix` - Dry/wet mix (0-1)
- `delay_mod` - Modulation source (lfo/self)

### Distortion Parameters

- `distDrive` - Drive amount (1-11)
- `distMix` - Dry/wet mix (0-1)

## Installation

### File Structure

The Ygg engine comes in two flavors:

**For SuperCollider (standalone):**

- `sc/ygg_synths.scd` - SynthDef definitions (shared code)
- `sc/ygg_manager.scd` - Manager class (loads synths automatically)
- `demos/ygg_demo.scd` - Demo script

**For Norns:**

- `Omr.lua` - Main Monome Script
- `lib/Engine_Ygg.sc` - Complete self-contained engine
- `img/tree.png` - Logo

