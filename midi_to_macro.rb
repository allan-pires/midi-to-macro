#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/config'
require_relative 'lib/midi_to_macro'
require_relative 'lib/cli'

# Main entry point
if __FILE__ == $0
  options = CLI.parse_options
  midi_file = CLI.validate_midi_file(ARGV[0])
  
  converter = MidiToMacro.new(midi_file, options)
  converter.convert
end
