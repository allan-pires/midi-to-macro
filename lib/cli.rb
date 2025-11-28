# frozen_string_literal: true

require 'optparse'
require_relative 'config'

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

  def self.get_midi_file_or_interactive(midi_file)
    return [midi_file, {}] if midi_file && !midi_file.empty?
    
    interactive_mode
  end

  def self.validate_midi_file(midi_file)
    unless File.exist?(midi_file)
      puts "Error: MIDI file not found: #{midi_file}"
      exit 1
    end
    
    midi_file
  end

  def self.interactive_mode
    puts "\n" + "="*60
    puts "  MIDI to Macro Converter - Interactive Mode"
    puts "="*60 + "\n"

    # List MIDI files
    midi_files = list_midi_files
    
    if midi_files.empty?
      puts "No .mid files found in: #{Config.midi_directory}"
      puts "\nPlease specify a MIDI file or add files to the MIDI directory."
      exit 1
    end

    # Select file
    selected_file = select_midi_file(midi_files)
    
    # Ask for options
    options = prompt_for_options
    
    [selected_file, options]
  end

  def self.list_midi_files
    midi_dir = Config.midi_directory
    
    unless Dir.exist?(midi_dir)
      puts "Warning: MIDI directory does not exist: #{midi_dir}"
      return []
    end
    
    Dir.glob(File.join(midi_dir, "*.mid")) + Dir.glob(File.join(midi_dir, "*.MID"))
  end

  def self.select_midi_file(files)
    puts "Available MIDI files:\n\n"
    
    files.each_with_index do |file, index|
      basename = File.basename(file)
      puts "  [#{index + 1}] #{basename}"
    end
    
    puts "\n" + "-"*60
    print "Select a file (1-#{files.length}): "
    
    begin
      input = gets
      exit 0 if input.nil? # Handle EOF
      
      selection = input.chomp.to_i
      
      if selection < 1 || selection > files.length
        puts "\n❌ Invalid selection. Please enter a number between 1 and #{files.length}.\n"
        return select_midi_file(files)
      end
      
      selected_file = files[selection - 1]
      puts "\n✓ Selected: #{File.basename(selected_file)}\n"
      selected_file
    rescue Interrupt
      puts "\n\n✗ Cancelled."
      exit 0
    end
  end

  def self.prompt_for_options
    options = {}
    
    puts "Optional parameters (press Enter to skip):\n"
    
    begin
      # Transpose
      print "  Transpose (semitones, e.g., -5, 0, 5): "
      transpose_input = gets
      exit 0 if transpose_input.nil?
      transpose_input = transpose_input.chomp.strip
      if !transpose_input.empty?
        begin
          options[:transpose] = Integer(transpose_input)
        rescue ArgumentError
          puts "    ⚠ Invalid number, skipping transpose."
        end
      end
      
      # Tempo multiplier
      print "  Tempo multiplier (e.g., 0.5 for half speed, 2.0 for double): "
      tempo_input = gets
      exit 0 if tempo_input.nil?
      tempo_input = tempo_input.chomp.strip
      if !tempo_input.empty?
        begin
          options[:tempo_multiplier] = Float(tempo_input)
        rescue ArgumentError
          puts "    ⚠ Invalid number, skipping tempo multiplier."
        end
      end
      
      # Game
      print "  Game (wwm/genshin): "
      game_input = gets
      exit 0 if game_input.nil?
      game_input = game_input.chomp.strip.downcase
      if !game_input.empty? && %w[wwm genshin].include?(game_input)
        options[:game] = game_input
      elsif !game_input.empty?
        puts "    ⚠ Invalid game, using default."
      end
      
      # Min duration
      print "  Minimum note duration in seconds (e.g., 0.1): "
      duration_input = gets
      exit 0 if duration_input.nil?
      duration_input = duration_input.chomp.strip
      if !duration_input.empty?
        begin
          options[:min_note_duration] = Float(duration_input)
        rescue ArgumentError
          puts "    ⚠ Invalid number, skipping minimum duration."
        end
      end
      
      puts "\n"
    rescue Interrupt
      puts "\n\n✗ Cancelled."
      exit 0
    end
    
    options
  end
end

