# Environment Variables Configuration

Create a `.env` file in the project root with the following variables:

```env
# MIDI to Macro Converter Configuration

# Default output directory for generated .mcr files
# Leave empty to use current directory
OUTPUT_DIRECTORY=C:/SamplePath/

# Default game mapping (wwm or genshin)
DEFAULT_GAME=wwm

# Default tempo multiplier (1.0 = normal speed)
DEFAULT_TEMPO_MULTIPLIER=1.0

# Default minimum note duration in seconds
DEFAULT_MIN_NOTE_DURATION=0.1

# Default transpose amount in semitones (0 = no transposition)
DEFAULT_TRANSPOSE=0

# Minimum delay threshold in milliseconds (to avoid micro-delays)
MIN_DELAY_THRESHOLD=5

# Key press delay in milliseconds (delay between key down and key up)
KEY_PRESS_DELAY=2
```

## How to Use

1. Copy the contents above into a file named `.env` in the project root
2. Modify the values as needed for your setup
3. The script will automatically load these values when it runs

Note: The `.env` file is typically ignored by git (should be in .gitignore) to keep your personal configuration private.

