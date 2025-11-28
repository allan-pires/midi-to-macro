# frozen_string_literal: true

require 'dotenv/load'

# Configuration management using environment variables
class Config
  class << self
    def output_directory
      ENV.fetch('OUTPUT_DIRECTORY', '')
    end

    def default_game
      ENV.fetch('DEFAULT_GAME', 'wwm')
    end

    def default_tempo_multiplier
      Float(ENV.fetch('DEFAULT_TEMPO_MULTIPLIER', '1.0'))
    end

    def default_min_note_duration
      Float(ENV.fetch('DEFAULT_MIN_NOTE_DURATION', '0.1'))
    end

    def default_transpose
      Integer(ENV.fetch('DEFAULT_TRANSPOSE', '0'))
    end

    def min_delay_threshold
      Integer(ENV.fetch('MIN_DELAY_THRESHOLD', '5'))
    end

    def key_press_delay
      Integer(ENV.fetch('KEY_PRESS_DELAY', '2'))
    end
  end
end

