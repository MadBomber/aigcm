require 'erb'

module Aigcm
  class StyleGuide
    LINE_MAX      = 72
    DEFAULT_GUIDE = ERB.new(
                      File.read(__FILE__)
                      .split("__END__")
                      .last
                      .strip
                    ).result

    def self.load(dir, custom_path = nil)
      # If a custom path is provided, use it
      if custom_path
        return load_from_file(custom_path)
      end

      # Check for COMMITS.md in the repository root
      config_file = File.join(dir, "COMMITS.md")
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

__END__

1. Craft a Clear Subject Line:
• Summarize Concisely: Begin with a brief summary (<%= Aigcm::StyleGuide::LINE_MAX %> characters max).
• Capitalize the Subject: Start the subject line with a capital letter.
• Omit Periods in Subject Line: Avoid ending with a period to save space.
• Use Imperative Mood: Phrase commands as direct actions (e.g., "Add feature" instead of "Added feature").

2. Provide a Detailed Body:
• Separate the body from the subject line with a blank line.
• Explain the Reason: Clearly articulate the rationale for the change rather than just summarizing the modification.
• Wrap Body Text at <%= Aigcm::StyleGuide::LINE_MAX %> Characters: Ensure that the body text wraps at <%= Aigcm::StyleGuide::LINE_MAX %> characters per line.

3. Reference Issues/Tickets:
• Include relevant issue numbers, ticket IDs and/or references when they are provided.  Do not invent your own reference.  Use what has been provided.
