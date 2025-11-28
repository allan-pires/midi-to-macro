# frozen_string_literal: true

require 'optparse'

# Command-line interface for MIDI to Macro converter
class CLI
  def self.parse_options
    options = {}
    
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby midi_to_macro.rb [options] <midi_file>"
      
      opts.on("-o", "--output FILE", "Output file path") do |f|
        options[:output] = f
      end
      
      opts.on("-g", "--game GAME", "Target game: 'wwm' or 'genshin'") do |g|
        options[:game] = g
      end
      
      opts.on("-t", "--tempo-multiplier FLOAT", Float, "Tempo multiplier") do |t|
        options[:tempo_multiplier] = t
      end
      
      opts.on("-d", "--min-duration FLOAT", Float, "Minimum note duration in seconds") do |d|
        options[:min_note_duration] = d
      end
      
      opts.on("--transpose INTEGER", Integer, "Transpose notes by semitones") do |t|
        options[:transpose] = t
      end
      
      opts.on("-h", "--help", "Show this help message") do
        puts opts
        exit
      end
    end.parse!
    
    options
  end

  def self.validate_midi_file(midi_file)
    if midi_file.nil? || midi_file.empty?
      puts "Error: No MIDI file specified"
      puts "Usage: ruby midi_to_macro.rb [options] <midi_file>"
      exit 1
    end
    
    unless File.exist?(midi_file)
      puts "Error: MIDI file not found: #{midi_file}"
      exit 1
    end
    
    midi_file
  end
end

