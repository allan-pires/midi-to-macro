# frozen_string_literal: true

# Handles MIDI note to keyboard key mapping for different games
class KeyMapper
  # Base note mappings for Where Winds Meet - three pitch ranges
  WWM_HIGH_MAP = {
    'C'  => 'Q',
    'C#' => ['SHIFT', 'Q'],
    'D'  => 'W',
    'D#' => ['CTRL', 'E'],
    'E'  => 'E',
    'F'  => 'R',
    'F#' => ['SHIFT', 'R'],
    'G'  => 'T',
    'G#' => ['SHIFT', 'T'],
    'A'  => 'Y',
    'A#' => ['CTRL', 'U'],
    'B'  => 'U'
  }.freeze

  WWM_MEDIUM_MAP = {
    'C'  => 'A',
    'C#' => ['SHIFT', 'A'],
    'D'  => 'S',
    'D#' => ['CTRL', 'D'],
    'E'  => 'D',
    'F'  => 'F',
    'F#' => ['SHIFT', 'F'],
    'G'  => 'G',
    'G#' => ['SHIFT', 'G'],
    'A'  => 'H',
    'A#' => ['CTRL', 'J'],
    'B'  => 'J'
  }.freeze

  WWM_LOW_MAP = {
    'C'  => 'Z',
    'C#' => ['SHIFT', 'Z'],
    'D'  => 'X',
    'D#' => ['CTRL', 'D'],
    'E'  => 'C',
    'F'  => 'V',
    'F#' => ['SHIFT', 'V'],
    'G'  => 'B',
    'G#' => ['SHIFT', 'B'],
    'A'  => 'N',
    'A#' => ['CTRL', 'M'],
    'B'  => 'M'
  }.freeze

  GENSHIN_KEYBOARD_MAP = {
    84 => 'Q',  # C6
    85 => 'W',  # C#6
    86 => 'E',  # D6
    87 => 'R',  # D#6
    88 => 'T',  # E6
    89 => 'Y',  # F6
    90 => 'U',  # F#6
    72 => 'A',  # C5
    73 => 'S',  # C#5
    74 => 'D',  # D5
    75 => 'F',  # D#5
    76 => 'G',  # E5
    77 => 'H',  # F5
    78 => 'J',  # F#5
    60 => 'Z',  # C4
    61 => 'X',  # C#4
    62 => 'C',  # D4
    63 => 'V',  # D#4
    64 => 'B',  # E4
    65 => 'N',  # F4
    66 => 'M',  # F#4
  }.freeze

  NOTE_NAMES = %w[C C# D D# E F F# G G# A A# B].freeze

  def initialize(game = 'wwm')
    @game = game.downcase
    @mapping = build_mapping
  end

  def map(note)
    note = [[note, 0].max, 127].min # Clamp to valid MIDI range
    @mapping[note]
  end

  def note_name(note)
    NOTE_NAMES[note % 12]
  end

  def note_full_name(note)
    octave = (note / 12) - 1
    "#{NOTE_NAMES[note % 12]}#{octave}"
  end

  private

  def build_mapping
    case @game
    when 'wwm', 'wherewindmeet', 'where winds meet'
      build_wwm_mapping
    when 'genshin', 'genshin impact'
      GENSHIN_KEYBOARD_MAP.dup
    else
      puts "Warning: Unknown game '#{@game}', using WWM mapping"
      build_wwm_mapping
    end
  end

  def build_wwm_mapping
    mapping = {}
    
    (0..127).each do |midi_note|
      note_index = midi_note % 12
      note_name = NOTE_NAMES[note_index]
      
      if midi_note >= 84
        # High pitch: C6 and above
        mapping[midi_note] = WWM_HIGH_MAP[note_name]
      elsif midi_note >= 72
        # Medium pitch: C5-B5
        mapping[midi_note] = WWM_MEDIUM_MAP[note_name]
      else
        # Low pitch: C0-B4
        mapping[midi_note] = WWM_LOW_MAP[note_name]
      end
    end
    
    mapping
  end
end

