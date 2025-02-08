# Development Plan for the aicommit Ruby Gem

## Overview
aicommit is a Ruby gem designed to generate AI-powered commit messages using git diffs and optional style guides. While the core classes exist (GitDiff, CommitMessageGenerator, and StyleGuide), several enhancements are needed to make the gem production-ready.

## 1. Core Business Logic Enhancements

### GitDiff
- **Improve Diff Generation:**  
  - Enhance handling for multiple git scenarios: commits, staged changes, and amended commits.
  - Encapsulate system calls to git (e.g., using Open3) and parse errors gracefully.
  - Add clear error reporting (e.g., when there are no changes or if the git command fails).

- **Tests:**  
  - Implement tests that mock/stub git command responses.
  - Create scenarios for both commit ref diffs and amend diff generation.

### CommitMessageGenerator
- **Provider Integration & Abstraction:**  
  - Abstract provider logic so that additional providers (beyond OpenAI) can be supported. Consider creating an AicommitRb::Provider interface.
  - For now, implement the OpenAI integration using a robust HTTP library (e.g., Net::HTTP or a gem like HTTParty) with proper error handling and retries.
  
- **API Response Handling:**  
  - Validate and parse API responses.
  - Detect and report API errors (timeouts, invalid response codes, etc.).

- **Prompt Construction:**  
  - Combine diff text and the style guide in the prompt.
  - Allow customization of prompts based on the project or user configuration.

- **Tests:**  
  - Stub API calls and simulate various responses (success, error, timeout).
  - Validate that the generated commit message is a well-formed string.

### StyleGuide
- **Configuration File Support:**  
  - Enable loading a style guide from a configuration file (e.g., .aicommitrc or a dedicated YAML file) from the project root.
  - Provide a default style guide if no file is found.
  
- **Validation:**  
  - Validate the style guide structure and content to avoid generating invalid commit messages.

- **Tests:**  
  - Create tests for loading, parsing, and falling back to a default style guide.
  - Include tests to simulate missing, misconfigured, or invalid configurations.

## 2. Command-Line Interface (CLI) Improvements

- **Option Parsing Enhancements:**  
  - Refine OptionParser usage to provide clearer help messages.
  - Add verbose/debug options to troubleshoot issues during execution.

- **User Feedback and Error Handling:**  
  - Centralize error reporting (using rescue blocks) to give users friendly messages.
  - Consider logging key operations and failures for better diagnostics.

## 3. Provider Support and Configuration

- **Extend Provider Support:**  
  - Create an abstraction for AI providers so that support for multiple services (e.g., OpenAI, others) can be handled polymorphically.
  - Move the provider-related logic from aicommit.rb into separate provider classes or modules.

- **API Key Handling:**  
  - Enhance the logic for reading API keys:
    - Support environment variables (custom keys like OPENAI_API_KEY, etc.).
    - Allow saving and retrieving keys from a configuration file if the user passes the --save-key flag.

## 4. Testing Strategy

- **Unit Test Implementation:**  
  - Flesh out the stubbed tests in the test files (test_git_diff.rb, test_commit_message_generator.rb, test_style_guide.rb, etc.) with concrete examples and mocks.
  - Utilize Minitest’s stubbing/mocking abilities for system commands and HTTP API calls.

- **Integration Testing:**  
  - Set up tests for the CLI (aicommit-rb and bin/aicommit) to simulate ARGV input and validate overall behavior.

- **Coverage:**  
  - Integrate code coverage tools (e.g., SimpleCov) and aim for high test coverage.

## 5. Continuous Integration & Documentation

- **CI/CD:**  
  - Set up a CI workflow (e.g., using GitHub Actions) to run the test suite on every push or pull request.
  - Configure code coverage reports and enforce minimum coverage criteria.

- **Documentation:**  
  - Update the README with detailed instructions on installation, configuration, and usage.
  - Document the new provider abstraction and how to add new providers.
  - Write developer documentation, including guidelines for contributing and setting up the development environment.

## 6. Future Enhancements

- **Interactive Mode:**  
  - Consider developing an interactive CLI mode that iteratively refines commit messages based on user feedback.

- **Advanced Configurations:**  
  - Allow customization of request parameters (e.g., max_tokens, prompt templates) via config files.

- **Logging Improvements:**  
  - Add a logging mechanism to capture detailed debug information for troubleshooting.

- **Refactoring:**  
  - Continuously refactor the code for better separation of concerns and maintainability, possibly by splitting logic into more modules/classes where needed.

This plan lays out a roadmap to evolve aicommit into a robust and maintainable gem that can support various git workflows, multiple AI providers, and extensive customization while providing a pleasant developer experience.
