# MIDI to Macro Converter

A Ruby script that converts MIDI files into macro commands for playing musical instruments in games like Genshin Impact and Where Winds Meet.

## Features

- ✅ Reads standard MIDI files
- ✅ Maps MIDI notes to game keyboard controls
- ✅ Generates .mcr format macro files
- ✅ Preserves timing and rhythm from the original MIDI
- ✅ Supports tempo adjustments and transposition
- ✅ Compatible with macro automation tools

## Prerequisites

- Ruby 2.7 or higher
- RubyGems (comes with Ruby)

## Installation

1. Clone or download this repository

2. Install dependencies:
   
   **If Ruby is in your PATH:**
   ```bash
   gem install midilib
   ```
   
   **If Ruby is not in your PATH (Windows):**
   ```bash
   C:\Ruby34-x64\bin\gem.cmd install midilib
   ```
   
   (Replace `C:\Ruby34-x64` with your Ruby installation path if different)
   
   Note: `optparse` is built into Ruby, so no installation is needed for it.

## Usage

### Basic Usage

Convert a MIDI file to macro commands:

```bash
ruby midi_to_macro.rb song.mid
```

This will create:
- `output_macro.mcr` - Macro file in .mcr format

### Command Line Options

```bash
ruby midi_to_macro.rb [options] <midi_file>
```

Options:
- `-o, --output FILE` - Specify output file path (default: `output_macro.mcr`)
- `-g, --game GAME` - Target game: 'wwm' for Where Winds Meet or 'genshin' for Genshin Impact (default: `wwm`)
- `-t, --tempo-multiplier FLOAT` - Speed multiplier (1.0 = normal, 0.5 = half speed, 2.0 = double speed)
- `-d, --min-duration FLOAT` - Minimum note duration in seconds (default: 0.1)
- `--transpose INTEGER` - Transpose notes by semitones (positive = higher, negative = lower)
- `-h, --help` - Show help message

### Examples

Convert with custom output file:
```bash
ruby midi_to_macro.rb -o my_song.mcr song.mid
```

Slow down the song (half speed):
```bash
ruby midi_to_macro.rb -t 0.5 song.mid
```

Transpose up by 2 semitones:
```bash
ruby midi_to_macro.rb --transpose 2 song.mid
```

Adjust minimum note duration:
```bash
ruby midi_to_macro.rb -d 0.15 song.mid
```

## Game Key Mappings

### Where Winds Meet (Default)

The script maps MIDI notes to three pitch ranges based on the MIDI note number:

**High Pitch (C6 and above, MIDI 84+)**:
- **C** → Q
- **C#** → SHIFT + Q
- **D** → W
- **D#** → CTRL + Q
- **E** → E
- **F** → R
- **F#** → SHIFT + R
- **G** → T
- **G#** → SHIFT + T
- **A** → Y
- **A#** → CTRL + Y
- **B** → U

**Medium Pitch (C5-B5, MIDI 72-83)**:
- **C** → A
- **C#** → SHIFT + A
- **D** → S
- **D#** → CTRL + S
- **E** → D
- **F** → F
- **F#** → SHIFT + F
- **G** → G
- **G#** → SHIFT + G
- **A** → H
- **A#** → CTRL + H
- **B** → J

**Low Pitch (C4 and below, MIDI 0-71)**:
- **C** → Z
- **C#** → SHIFT + Z
- **D** → X
- **D#** → CTRL + X
- **E** → C
- **F** → V
- **F#** → SHIFT + V
- **G** → B
- **G#** → SHIFT + B
- **A** → N
- **A#** → CTRL + N
- **B** → M

Modifier keys (SHIFT, CTRL) are combined with the base key in the macro output.

### Genshin Impact (Windsong Lyre)

To use Genshin Impact mapping, use the `-g genshin` option:

- **Highest octave (Q-U)**: Q, W, E, R, T, Y, U
- **Middle octave (A-J)**: A, S, D, F, G, H, J
- **Lowest octave (Z-M)**: Z, X, C, V, B, N, M

Example mappings:
- C4 (MIDI 60) → Z
- C5 (MIDI 72) → A
- C6 (MIDI 84) → Q

## Using the Generated Macro

The script generates a `.mcr` file in the following format:

```
DELAY : 1200
Keyboard : Q : KeyDown
DELAY : 2
Keyboard : Q : KeyUp
DELAY : 337
Keyboard : W : KeyDown
DELAY : 2
Keyboard : W : KeyUp
```

### Format Explanation

- `DELAY : <milliseconds>` - Wait for the specified number of milliseconds
- `Keyboard : <key> : KeyDown` - Press the specified key down
- `Keyboard : <key> : KeyUp` - Release the specified key

### Using the .mcr File

The `.mcr` file can be used with macro automation tools that support this format. The file contains:
- Precise timing delays between notes
- Key press commands in the correct sequence
- Accurate note durations

To use the macro:
1. Load the `.mcr` file in your preferred macro automation tool
2. Open the game and activate the musical instrument
3. Run the macro when ready

## How It Works

1. **MIDI Parsing**: The script reads MIDI files using the `midilib` gem
2. **Event Extraction**: Extracts note-on and note-off events with precise timing
3. **Tempo Calculation**: Calculates note timing based on MIDI tempo and timing resolution
4. **Key Mapping**: Maps MIDI note numbers (0-127) to game keyboard keys
5. **Macro Generation**: Creates a sequence of key presses with accurate delays in `.mcr` format

## Tips

- **Timing**: If the timing seems off, adjust the `--tempo-multiplier` option
- **Note Range**: Make sure your MIDI file uses notes within the game's playable range (typically C4-C6 for Genshin Impact)
- **Transposition**: Use `--transpose` to shift notes into the playable range
- **Testing**: Test with short songs first to ensure the mapping works correctly
- **Game Policies**: Be aware of your game's terms of service regarding automation tools

## Troubleshooting

**Problem**: Some notes don't have key mappings
- **Solution**: The MIDI file may contain notes outside the game's range. Try using `--transpose` to shift notes

**Problem**: Timing is too fast/slow
- **Solution**: Adjust the `--tempo-multiplier` option (lower = slower, higher = faster)

**Problem**: Notes overlap incorrectly
- **Solution**: Adjust the `--min-duration` option to set minimum note hold time

**Problem**: Macro file format not recognized
- **Solution**: Make sure you're using a macro tool that supports the `.mcr` format, or check that the file extension is correct

## Limitations

- Only maps notes that are in the game's playable range
- Chords are played as sequential notes (games typically only support single notes)
- Complex MIDI files with multiple simultaneous tracks may need to be simplified first

## Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## License

This project is open source and available for personal use. Please respect your game's terms of service when using automation tools.

## Credits

- Uses [midilib](https://github.com/jimm/midilib) gem for MIDI file parsing
- Designed for games like Genshin Impact and Where Winds Meet

