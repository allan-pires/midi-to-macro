# frozen_string_literal: true

require 'midilib/sequence'
require_relative 'config'
require_relative 'key_mapper'
require_relative 'macro_processor'

# Parses MIDI files and converts them to macro commands
class MidiToMacro
  def initialize(midi_file, options = {})
    @midi_file = midi_file
    @options = build_options(options)
    @sequence = MIDI::Sequence.new
    @key_mapper = KeyMapper.new(@options[:game])
    @processor = MacroProcessor.new(
      @key_mapper,
      @options[:output_file],
      min_note_duration: @options[:min_note_duration],
      min_delay_threshold: Config.min_delay_threshold
    )
  end

  def convert
    puts "Reading MIDI file: #{@midi_file}"
    
    load_file
    
    info = midi_info
    puts "Tracks: #{info[:tracks]}"
    puts "Tempo: #{info[:bpm]} BPM"
    puts "PPQ: #{info[:ppqn]}"

    note_events = parse
    puts "Found #{note_events.length} note events"
    
    macro_commands = @processor.generate(note_events)
    @processor.write(macro_commands)
    
    puts "Conversion complete! Output written to: #{@options[:output_file]}"
  end

  def midi_info
    {
      tracks: @sequence.tracks.length,
      bpm: @sequence.bpm,
      ppqn: @sequence.ppqn
    }
  end

  def parse
    extract_note_events
  end

  private

  def load_file
    File.open(@midi_file, 'rb') do |file|
      @sequence.read(file)
    end
  end

  def build_options(options)
    {
      output_file: options[:output] || default_output_file,
      game: options[:game] || Config.default_game,
      tempo_multiplier: options[:tempo_multiplier] || Config.default_tempo_multiplier,
      min_note_duration: options[:min_note_duration] || Config.default_min_note_duration,
      transpose: options[:transpose] || Config.default_transpose
    }
  end

  def default_output_file
    output_dir = Config.output_directory
    base_name = File.basename(@midi_file, File.extname(@midi_file))
    
    if output_dir.empty?
      "#{base_name}.mcr"
    else
      File.join(output_dir, "#{base_name}.mcr")
    end
  end

  def extract_note_events
    events = []
    ticks_per_quarter = @sequence.ppqn.to_f
    tempo_map = build_tempo_map

    @sequence.each do |track|
      track_time = 0
      track.each do |event|
        track_time += event.delta_time
        
        if event.is_a?(MIDI::NoteOn) && event.velocity > 0
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

    events.sort_by { |e| e[:time_ms] }
  end

  def build_tempo_map
    tempo_map = { 0 => 500_000 } # Default tempo: 120 BPM
    
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
    relevant_tempo_ticks = tempo_map.keys.select { |t| t <= ticks }.max || 0
    tempo = tempo_map[relevant_tempo_ticks]
    ms_per_tick = (tempo / ticks_per_quarter) / 1000.0
    (ticks * ms_per_tick * @options[:tempo_multiplier]).round(2)
  end
end
