require "net/http"
require "json"
require "open3"
require "ai_client"

module Aicommit
  class CommitMessageGenerator
    class Error < StandardError; end

    MAX_DIFF_SIZE = 4000 # Characters

    def initialize(api_key:, model:, max_tokens:, base_url: nil, force_external: false)
      @force_external = force_external
      validate_model_provider_combination(model)
      check_provider_availability
      @client = AiClient.new(model, api_key: api_key)
    rescue StandardError => e
      raise Error, "Failed to initialize AI client: #{e.message}"
    end

    def generate(diff, style_guide, context = [])
      return "No changes to commit" if diff.strip.empty?

      check_repository_privacy unless @force_external

      # Truncate diff if too large
      if diff.length > MAX_DIFF_SIZE
        diff = diff[0...MAX_DIFF_SIZE] + "\n...[diff truncated]"
      end

      processed_context = process_context(context)
      prompt = build_prompt(diff, style_guide, processed_context)

      begin
        response = @client.chat(prompt)
        response.to_s.strip
      rescue StandardError => e
        "Error generating commit message: #{e.message}"
      end
    end

    private

    def validate_model_provider_combination(model)
      client = AiClient.new(model)
      @provider = client.provider
    rescue ArgumentError => e
      raise Error, "Invalid model/provider combination: #{e.message}"
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
