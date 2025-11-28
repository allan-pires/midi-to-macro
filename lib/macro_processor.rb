# frozen_string_literal: true

require_relative 'key_mapper'
require_relative 'config'

# Generates and writes macro commands from MIDI note events
class MacroProcessor
  def initialize(key_mapper, output_file, min_note_duration: nil, min_delay_threshold: nil)
    @key_mapper = key_mapper
    @output_file = output_file
    @min_note_duration = min_note_duration || Config.default_min_note_duration
    @min_delay_threshold = min_delay_threshold || Config.min_delay_threshold
    @key_press_delay = Config.key_press_delay
  end

  def process(events)
    commands = generate(events)
    write(commands)
  end

  def generate(events)
    commands = []
    last_time = 0
    active_notes = {}

    events.each do |event|
      if event[:type] == :note_on
        process_note_on(event, commands, active_notes, last_time)
        last_time = event[:time_ms]
      elsif event[:type] == :note_off
        process_note_off(event, commands, active_notes)
      end
    end

    commands
  end

  def write(commands)
    File.open(@output_file, 'w') do |file|
      commands.each do |cmd|
        case cmd[:type]
        when :delay
          file.puts "DELAY : #{cmd[:value_ms]}"
        when :key_press
          write_key_press(file, cmd[:key])
        end
      end
    end
  end

  private

  def process_note_on(event, commands, active_notes, last_time)
    note = [[event[:note], 0].max, 127].min
    key = @key_mapper.map(note)

    unless key
      puts "Warning: No key mapping for MIDI note #{note} (#{@key_mapper.note_full_name(note)})"
      return
    end

    time_since_last = event[:time_ms] - last_time

    if time_since_last > @min_delay_threshold
      commands << {
        type: :delay,
        value_ms: time_since_last.round
      }
    end

    active_notes[note] = event[:time_ms]

    commands << {
      type: :key_press,
      key: key,
      note: note,
      time_ms: event[:time_ms],
      duration_ms: (@min_note_duration * 1000).round
    }
  end

  def process_note_off(event, commands, active_notes)
    note = [[event[:note], 0].max, 127].min

    return unless active_notes[note]

    note_duration = event[:time_ms] - active_notes[note]
    cmd = commands.reverse.find { |c| c[:type] == :key_press && c[:note] == note }
    
    if cmd && note_duration > 0
      min_duration_ms = (@min_note_duration * 1000).round
      cmd[:duration_ms] = [note_duration.round, min_duration_ms].max
    end
    
    active_notes.delete(note)
  end

  def write_key_press(file, key)
    if key.is_a?(Array)
      write_modifier_key(file, key)
    else
      write_simple_key(file, key)
    end
  end

  def write_modifier_key(file, key_array)
    modifier, base_key = key_array
    modifier_key = modifier_to_key_name(modifier)

    file.puts "Keyboard : #{modifier_key} : KeyDown"
    file.puts "DELAY : #{@key_press_delay}"
    file.puts "Keyboard : #{base_key} : KeyDown"
    file.puts "Keyboard : #{base_key} : KeyUp"
    file.puts "Keyboard : #{modifier_key} : KeyUp"
  end

  def write_simple_key(file, key)
    file.puts "Keyboard : #{key} : KeyDown"
    file.puts "DELAY : #{@key_press_delay}"
    file.puts "Keyboard : #{key} : KeyUp"
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

