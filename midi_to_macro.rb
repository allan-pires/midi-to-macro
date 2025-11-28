#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/config'
require_relative 'lib/midi_to_macro'
require_relative 'lib/cli'

# Main entry point
if __FILE__ == $0
  options = CLI.parse_options
  midi_file_arg = ARGV[0]
  
  # Get MIDI file (interactive mode if not provided)
  midi_file, interactive_options = CLI.get_midi_file_or_interactive(midi_file_arg)
  options.merge!(interactive_options) if interactive_options
  
  CLI.validate_midi_file(midi_file)
  
  converter = MidiToMacro.new(midi_file, options)
  converter.convert
end
