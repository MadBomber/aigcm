module Aicommit
  class StyleGuide
    DEFAULT_GUIDE = <<~GUIDE
      - Use conventional commits format (type: description)
      - Keep first line under 72 characters
      - Use present tense ("add" not "added")
      - Be descriptive but concise
    GUIDE

    def self.load(dir)
      config_file = File.join(dir, '.aicommitrc')
      return DEFAULT_GUIDE unless File.exist?(config_file)

      File.read(config_file)
    rescue StandardError => e
      puts "Warning: Error reading style guide: #{e.message}"
      DEFAULT_GUIDE
    end
  end
end
