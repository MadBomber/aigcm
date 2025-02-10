require 'optparse'

module Aigcm
  class Options
    def self.parse
      options = {
        amend: false,
        context: [],
        dry: false,
        model: 'gpt-4o-mini',
        provider: nil,
        force_external: false,
        style: nil
      }

      OptionParser.new do |opts|
        opts.banner = "Usage: aigcm [options] [ref]"

        opts.on("-a", "--amend", "Amend the last commit") { options[:amend] = true }

        opts.on("-cCONTEXT", "--context=CONTEXT", "Extra context beyond the diff") do |context|
          options[:context] << context
        end

        opts.on("-d", "--dry", "Dry run the command") { options[:dry] = true }

        opts.on("-mMODEL", "--model=MODEL", "The model to use") { |model| options[:model] = model }

        opts.on("--provider=PROVIDER", "Specify the provider (ollama, openai, anthropic, etc)") do |provider|
          provider = provider.to_sym
          unless [:ollama, :openai, :anthropic, :google, :mistral].include?(provider)
            puts "Invalid provider specified. Valid providers are: ollama, openai, anthropic, google, mistral"
            exit 1
          end
          options[:provider] = provider
        end

        opts.on("--force-external", "Force using external AI provider even for private repos") {
          options[:force_external] = true
        }

        opts.on("-sSTYLE", "--style=STYLE", "Path to the style guide file") { |style| options[:style] = style }

        opts.on("--default", "Print the default style guide and exit") do
          puts "\nDefault Style Guide:"
          puts "-------------------"
          puts StyleGuide::DEFAULT_GUIDE
          exit
        end

        opts.on("--version", "Show version") { puts Aigcm::VERSION; exit }

      end.parse!

      options
    end
  end
end