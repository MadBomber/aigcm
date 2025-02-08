module Aicommit
  class StyleGuide
    DEFAULT_GUIDE = <<~GUIDE
      - Use conventional commits format (type: description)
      - Keep first line under 72 characters
      - Use present tense ("add" not "added")
      - Be descriptive but concise
    GUIDE

    def self.load(dir, custom_path = nil)
      # If a custom path is provided, use it
      if custom_path
        return load_from_file(custom_path)
      end

      # Check for COMMITS.md in the repository root
      config_file = File.join(dir, 'COMMITS.md')
      return load_from_file(config_file) if File.exist?(config_file)

      # Fallback to the default style guide
      DEFAULT_GUIDE
    rescue StandardError => e
      puts "Warning: Error reading style guide: #{e.message}"
      DEFAULT_GUIDE
    end

    private_class_method def self.load_from_file(path)
      File.read(path)
    end
  end
end
