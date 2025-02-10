require "open3"

module Aigcm
  class GitDiff
    class Error < StandardError; end

    def initialize(dir:, commit_hash: nil)
      @dir = dir
      @commit_hash = commit_hash
      @amend = amend
      validate_git_repo
    end

    def generate_diff
      Dir.chdir(@dir) do
        cmd = if @amend
            "git diff --cached HEAD^ 2>/dev/null || git diff --cached"
          elsif @commit_hash
            "git diff #{@commit_hash}^..#{@commit_hash}"
          else
            "git diff --cached"
          end

        stdout, _, status = Open3.capture3(cmd)

        raise Error, "Git command failed" unless status.success?
        raise Error, "No changes detected" if stdout.strip.empty?

        stdout
      end
    end

    private

    def validate_git_repo
      Dir.chdir(@dir) do
        _, _, status = Open3.capture3("git rev-parse --git-dir")
        raise Error, "Not a git repository" unless status.success?
      end
    rescue Errno::ENOENT
      raise Error, "Directory not found: #{@dir}"
    end
  end
end
