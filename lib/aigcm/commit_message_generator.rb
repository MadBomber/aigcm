require "net/http"
require "json"
require "open3"
require "ruby_llm"

module Aigcm
  class CommitMessageGenerator
    class Error < StandardError; end

    MAX_DIFF_SIZE = 4000 # Characters

    def initialize(model:, provider:, max_tokens:, force_external: false, amend: false)
      @model = model
      @provider = provider
      @max_tokens = max_tokens
      @force_external = force_external
      @amend = amend
      infer_provider_from_model
      check_provider_availability

      configure_ruby_llm
      @chat = RubyLLM.chat(model: @model)
    rescue StandardError => e
      raise Error, "Failed to initialize AI client: #{e.message}"
    end

    def generate(style_guide, context = [])
      diff = GitDiff.new(dir: Dir.pwd, amend: @amend).generate_diff
      return "No changes to commit" if diff.strip.empty?

      check_repository_privacy unless @force_external

      # Truncate diff if too large
      if diff.length > MAX_DIFF_SIZE
        diff = diff[0...MAX_DIFF_SIZE] + "\n...[diff truncated]"
      end

      processed_context = process_context(context)
      prompt = build_prompt(diff, style_guide, processed_context)

      begin
        response = @chat.ask(prompt)
        response.content.strip
      rescue StandardError => e
        "Error generating commit message: #{e.message}"
      end
    end

    private

    def infer_provider_from_model
      return if @provider

      model_lower = @model.to_s.downcase
      @provider = if model_lower.include?('gpt') || model_lower.include?('o1') || model_lower.include?('o3')
                    :openai
                  elsif model_lower.include?('claude')
                    :anthropic
                  elsif model_lower.include?('gemini')
                    :google
                  elsif model_lower.include?('mistral') || model_lower.include?('mixtral')
                    :mistral
                  elsif model_lower.include?('llama') || model_lower.include?('qwen') || model_lower.include?('deepseek')
                    :ollama
                  else
                    :openai
                  end
    end

    def configure_ruby_llm
      RubyLLM.configure do |config|
        case @provider
        when :ollama
          config.ollama_api_base = 'http://localhost:11434/v1'
        when :openai
          config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)
        when :anthropic
          config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
        when :google
          config.gemini_api_key = ENV.fetch('GEMINI_API_KEY', nil)
        when :mistral
          config.mistral_api_key = ENV.fetch('MISTRAL_API_KEY', nil)
        end
      end
    end

    def check_provider_availability
      case @provider
      when :ollama
        check_ollama_running
      when :localai
        check_localai_running
      end
    rescue StandardError => e
      raise Error, "Provider not available: #{e.message}"
    end

    def check_ollama_running
      Net::HTTP.get(URI("http://localhost:11434/api/version"))
    rescue StandardError
      raise Error, "Ollama is not running. Please start ollama first."
    end

    def check_localai_running
      Net::HTTP.get(URI("http://localhost:8080/v1/models"))
    rescue StandardError
      raise Error, "LocalAI is not running. Please start localai first."
    end

    def process_context(context_array)
      context_array.map do |ctx|
        if ctx.start_with?("@")
          filename = ctx[1..]
          File.read(filename) rescue "Could not read #{filename}"
        else
          ctx
        end
      end
    end

    def check_repository_privacy
      return if @provider == :ollama # Local provider is always safe

      stdout, _, status = Open3.capture3("gh repo view --json isPrivate -q '.isPrivate'")

      if status.success? && stdout.strip == "true"
        raise Error, "This is a private repository. Use a local model (ollama) or run with --force-external flag"
      end
    rescue Errno::ENOENT
      puts "Warning: Unable to check repository privacy status (gh command not found)"
    end

    def build_prompt(diff, style_guide, context)
      <<~PROMPT
        Generate a commit message for the git diff that follows these instructions.
        Do not wrap your response in a code block.
        Follow these style guidelines when constructing your response:
        #{style_guide}

        #{context.join("\n") unless context.empty?}

        Git diff:
        #{diff}
      PROMPT
    end
  end
end
