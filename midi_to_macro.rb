#!/usr/bin/env ruby
# frozen_string_literal: true

require 'midilib/sequence'
require 'optparse'

# MIDI to Macro Converter
# Converts MIDI files to macro commands for games like Where Winds Meet and Genshin Impact
class MidiToMacro
  # Base note mappings for Where Winds Meet - three pitch ranges
  # Format: [modifier, base_key] array or just base_key string
  # Modifiers: 'SHIFT' or 'CTRL'
  
  # High pitch (C6 and above, MIDI notes 84+)
  WWM_HIGH_MAP = {
    'C'  => 'Q',
    'C#' => ['SHIFT', 'Q'],
    'D'  => 'W',
    'D#' => ['CTRL', 'E'],  # Db
    'E'  => 'E',
    'F'  => 'R',
    'F#' => ['SHIFT', 'R'],
    'G'  => 'T',
    'G#' => ['SHIFT', 'T'],
    'A'  => 'Y',
    'A#' => ['CTRL', 'U'],  # Ab
    'B'  => 'U'
  }.freeze

  # Medium pitch (C5-B5, MIDI notes 72-83)
  WWM_MEDIUM_MAP = {
    'C'  => 'A',
    'C#' => ['SHIFT', 'A'],
    'D'  => 'S',
    'D#' => ['CTRL', 'D'],  # Db
    'E'  => 'D',
    'F'  => 'F',
    'F#' => ['SHIFT', 'F'],
    'G'  => 'G',
    'G#' => ['SHIFT', 'G'],
    'A'  => 'H',
    'A#' => ['CTRL', 'J'],  # Ab
    'B'  => 'J'
  }.freeze

  # Low pitch (C4 and below, MIDI notes 0-71)
  WWM_LOW_MAP = {
    'C'  => 'Z',
    'C#' => ['SHIFT', 'Z'],
    'D'  => 'X',
    'D#' => ['CTRL', 'D'],  # Db
    'E'  => 'C',
    'F'  => 'V',
    'F#' => ['SHIFT', 'V'],
    'G'  => 'B',
    'G#' => ['SHIFT', 'B'],
    'A'  => 'N',
    'A#' => ['CTRL', 'M'],  # Ab
    'B'  => 'M'
  }.freeze

  # Generate WWM mapping for all MIDI notes (0-127)
  # Maps notes to appropriate pitch range based on octave
  WWM_KEYBOARD_MAP = begin
    mapping = {}
    note_names = %w[C C# D D# E F F# G G# A A# B]
    
    (0..127).each do |midi_note|
      note_index = midi_note % 12
      note_name = note_names[note_index]
      octave = midi_note / 12
      
      # Determine which pitch range to use based on MIDI note number
      # C4 = 60, C5 = 72, C6 = 84
      # Low: 0-71 (C0 to B4), Medium: 72-83 (C5 to B5), High: 84-127 (C6 and above)
      if midi_note >= 84
        # High pitch: C6 and above (Q-U range)
        mapping[midi_note] = WWM_HIGH_MAP[note_name]
      elsif midi_note >= 72
        # Medium pitch: C5-B5 (A-J range)
        mapping[midi_note] = WWM_MEDIUM_MAP[note_name]
      else
        # Low pitch: C0-B4 (Z-M range)
        mapping[midi_note] = WWM_LOW_MAP[note_name]
      end
    end
    
    mapping.freeze
  end

  # Note mappings for Genshin Impact Windsong Lyre
  # Keys: Q-U (highest), A-J (middle), Z-M (lowest)
  GENSHIN_KEYBOARD_MAP = {
    # Highest octave (Q-U)
    84 => 'Q',  # C6
    85 => 'W',  # C#6
    86 => 'E',  # D6
    87 => 'R',  # D#6
    88 => 'T',  # E6
    89 => 'Y',  # F6
    90 => 'U',  # F#6
    # Middle octave (A-J)
    72 => 'A',  # C5
    73 => 'S',  # C#5
    74 => 'D',  # D5
    75 => 'F',  # D#5
    76 => 'G',  # E5
    77 => 'H',  # F5
    78 => 'J',  # F#5
    # Lower octave (Z-M)
    60 => 'Z',  # C4
    61 => 'X',  # C#4
    62 => 'C',  # D4
    63 => 'V',  # D#4
    64 => 'B',  # E4
    65 => 'N',  # F4
    66 => 'M',  # F#4
  }.freeze

  # Extended mapping to cover more notes
  # Maps MIDI note numbers (0-127) to keyboard keys
  def self.generate_extended_mapping
    mapping = {}
    
    # Generate mappings for multiple octaves
    base_notes = {
      'C' => ['Z', 'A', 'Q'],
      'C#' => ['X', 'S', 'W'],
      'D' => ['C', 'D', 'E'],
      'D#' => ['V', 'F', 'R'],
      'E' => ['B', 'G', 'T'],
      'F' => ['N', 'H', 'Y'],
      'F#' => ['M', 'J', 'U']
    }
    
    # MIDI note 60 is C4 (middle C)
    (0..127).each do |midi_note|
      note_name = self.note_number_to_name(midi_note)
      octave = (midi_note / 12) - 1
      
      # Find the closest key in the available range
      key = self.find_closest_key(midi_note, base_notes, mapping)
      mapping[midi_note] = key if key
    end
    
    mapping
  end

  def self.note_number_to_name(note_num)
    note_names = %w[C C# D D# E F F# G G# A A# B]
    note_names[note_num % 12]
  end

  def self.find_closest_key(midi_note, base_notes, existing_mapping)
    # Use the standard Genshin mapping if available
    return GENSHIN_KEYBOARD_MAP[midi_note] if GENSHIN_KEYBOARD_MAP[midi_note]
    
    # Find closest mapped note
    closest_note = existing_mapping.keys.min_by { |n| (n - midi_note).abs }
    return existing_mapping[closest_note] if closest_note && (closest_note - midi_note).abs <= 12
    
    nil
  end

  def initialize(midi_file, options = {})
    @midi_file = midi_file
    @options = {
      output_file: options[:output] || 'output_macro.mcr',
      game: options[:game] || 'wwm',
      tempo_multiplier: options[:tempo_multiplier] || 1.0,
      min_note_duration: options[:min_note_duration] || 0.1,
      transpose: options[:transpose] || 0
    }
    @sequence = MIDI::Sequence.new
    
    # Select key mapping based on game
    case @options[:game].downcase
    when 'wwm', 'wherewindmeet', 'where winds meet'
      @key_mapping = WWM_KEYBOARD_MAP.dup
    when 'genshin', 'genshin impact'
      @key_mapping = GENSHIN_KEYBOARD_MAP.dup
    else
      puts "Warning: Unknown game '#{@options[:game]}', using WWM mapping"
      @key_mapping = WWM_KEYBOARD_MAP.dup
    end
  end

  def convert
    puts "Reading MIDI file: #{@midi_file}"
    
    File.open(@midi_file, 'rb') do |file|
      @sequence.read(file)
    end

    puts "Tracks: #{@sequence.tracks.length}"
    puts "Tempo: #{@sequence.bpm} BPM"
    puts "PPQ: #{@sequence.ppqn}"

    # Extract all note events with timing
    note_events = extract_note_events
    
    puts "Found #{note_events.length} note events"
    
    # Generate macro commands
    macro_commands = generate_macro_commands(note_events)
    
    # Write output
    write_output(macro_commands)
    
    puts "Conversion complete! Output written to: #{@options[:output_file]}"
  end

  private

  def extract_note_events
    events = []
    ticks_per_quarter = @sequence.ppqn.to_f
    tempo_map = build_tempo_map(ticks_per_quarter)

    @sequence.each do |track|
      track_time = 0
      track.each do |event|
        track_time += event.delta_time
        
        if event.is_a?(MIDI::NoteOn) && event.velocity > 0
          # Calculate time in milliseconds
          time_ms = ticks_to_milliseconds(track_time, ticks_per_quarter, tempo_map)
          
          events << {
            type: :note_on,
            note: event.note + @options[:transpose],
            velocity: event.velocity,
            time_ms: time_ms,
            time_ticks: track_time
          }
        elsif event.is_a?(MIDI::NoteOff) || 
              (event.is_a?(MIDI::NoteOn) && event.velocity == 0)
          time_ms = ticks_to_milliseconds(track_time, ticks_per_quarter, tempo_map)
          
          events << {
            type: :note_off,
            note: event.note + @options[:transpose],
            time_ms: time_ms,
            time_ticks: track_time
          }
        end
      end
    end

    # Sort events by time
    events.sort_by { |e| e[:time_ms] }
  end

  def build_tempo_map(ticks_per_quarter)
    tempo_map = { 0 => 500_000 } # Default tempo: 120 BPM = 500000 microseconds per quarter
    cumulative_ticks = 0
    
    @sequence.each do |track|
      track_time = 0
      track.each do |event|
        track_time += event.delta_time
        if event.is_a?(MIDI::Tempo)
          tempo_map[track_time] = event.tempo
        end
      end
    end
    
    tempo_map
  end

  def ticks_to_milliseconds(ticks, ticks_per_quarter, tempo_map)
    # Find the most recent tempo change before this tick
    relevant_tempo_ticks = tempo_map.keys.select { |t| t <= ticks }.max || 0
    tempo = tempo_map[relevant_tempo_ticks]
    
    # Convert: ticks * (tempo / ticks_per_quarter) / 1000
    # tempo is in microseconds per quarter note
    ms_per_tick = (tempo / ticks_per_quarter) / 1000.0
    (ticks * ms_per_tick * @options[:tempo_multiplier]).round(2)
  end

  def generate_macro_commands(events)
    commands = []
    last_time = 0
    active_notes = {} # Track note-on events to calculate note durations
    
    events.each do |event|
      if event[:type] == :note_on
        note = event[:note]
        note = [[note, 0].max, 127].min # Clamp to valid MIDI range
        
        key = @key_mapping[note]
        
        if key
          time_since_last = event[:time_ms] - last_time
          
          # Add delay if needed (with small threshold to avoid micro-delays)
          if time_since_last > 5 # 5ms minimum delay threshold
            delay_ms = time_since_last.round
            commands << {
              type: :delay,
              value_ms: delay_ms
            }
          end
          
          # Calculate note duration (will be updated when note_off is encountered)
          active_notes[note] = event[:time_ms]
          
          # Add key press
          commands << {
            type: :key_press,
            key: key,
            note: note,
            time_ms: event[:time_ms],
            duration_ms: (@options[:min_note_duration] * 1000).round
          }
          
          last_time = event[:time_ms]
        else
          puts "Warning: No key mapping for MIDI note #{note} (#{note_number_to_name(note)})"
        end
      elsif event[:type] == :note_off
        note = event[:note]
        note = [[note, 0].max, 127].min
        
        # Update duration if note was pressed
        if active_notes[note]
          note_duration = event[:time_ms] - active_notes[note]
          # Find the last key_press for this note and update its duration
          cmd = commands.reverse.find { |c| c[:type] == :key_press && c[:note] == note }
          if cmd && note_duration > 0
            cmd[:duration_ms] = [note_duration.round, @options[:min_note_duration] * 1000].max.round
          end
          active_notes.delete(note)
        end
      end
    end
    
    commands
  end

  def note_number_to_name(note_num)
    note_names = %w[C C# D D# E F F# G G# A A# B]
    octave = (note_num / 12) - 1
    "#{note_names[note_num % 12]}#{octave}"
  end

  def write_output(commands)
    File.open(@options[:output_file], 'w') do |file|
      commands.each do |cmd|
        case cmd[:type]
        when :delay
          file.puts "DELAY : #{cmd[:value_ms]}"
        when :key_press
          key = cmd[:key]
          
          # Handle modifier keys (array format: [modifier, base_key])
          if key.is_a?(Array)
            modifier, base_key = key
            modifier_key = modifier_to_key_name(modifier)
            
            # Modifier key down
            file.puts "Keyboard : #{modifier_key} : KeyDown"
            file.puts "DELAY : 2"
            # Base key down
            file.puts "Keyboard : #{base_key} : KeyDown"
            # Base key up immediately
            file.puts "Keyboard : #{base_key} : KeyUp"
            # Modifier key up
            file.puts "Keyboard : #{modifier_key} : KeyUp"
          else
            # Simple key press (no modifier)
            file.puts "Keyboard : #{key} : KeyDown"
            file.puts "DELAY : 2"
            file.puts "Keyboard : #{key} : KeyUp"
          end
        end
      end
    end
  end

  def modifier_to_key_name(modifier)
    case modifier.upcase
    when 'SHIFT'
      'ShiftLeft'
    when 'CTRL', 'CONTROL'
      'ControlLeft'
    when 'ALT'
      'AltLeft'
    else
      modifier
    end
  end
end

# CLI Interface
if __FILE__ == $0
  options = {}
  
  OptionParser.new do |opts|
    opts.banner = "Usage: ruby midi_to_macro.rb [options] <midi_file>"
    
    opts.on("-o", "--output FILE", "Output file path (default: output_macro.mcr)") do |f|
      options[:output] = f
    end
    
    opts.on("-g", "--game GAME", "Target game: 'wwm' or 'genshin' (default: wwm)") do |g|
      options[:game] = g
    end
    
    opts.on("-t", "--tempo-multiplier FLOAT", Float, "Tempo multiplier (default: 1.0)") do |t|
      options[:tempo_multiplier] = t
    end
    
    opts.on("-d", "--min-duration FLOAT", Float, "Minimum note duration in seconds (default: 0.1)") do |d|
      options[:min_note_duration] = d
    end
    
    opts.on("--transpose INTEGER", Integer, "Transpose notes by semitones (default: 0)") do |t|
      options[:transpose] = t
    end
    
    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end.parse!
  
  if ARGV.empty?
    puts "Error: No MIDI file specified"
    puts "Usage: ruby midi_to_macro.rb [options] <midi_file>"
    exit 1
  end
  
  midi_file = ARGV[0]
  
  unless File.exist?(midi_file)
    puts "Error: MIDI file not found: #{midi_file}"
    exit 1
  end
  
  converter = MidiToMacro.new(midi_file, options)
  converter.convert
end

