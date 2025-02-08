# Aicommit

## Overview

**Aicommit** is a Ruby gem designed to generate high-quality commit messages for git diffs. It leverages AI to analyze changes in your codebase and create concise, meaningful commit messages following best practices.

*Inspired by the Go-based CLI tool [aicommit](https://github.com/coder/aicommit), this Ruby gem aims to provide similar capabilities with some enhancements.*

## Features

- **Automatic Commit Message Generation**: Automatically generate commit messages based on code diffs.
- **Security-Aware Provider Selection**: Detects execution in a private repository and ensures non-local providers are not used for security reasons. This means that if you are working within a private repository, the gem will default to local providers unless explicitly forced otherwise.
- **Configurable Style Guide**: Allows using a specific style guide for commit messages, either from a default location or specified by the user.
- **AI Model Integration**: Integration with various AI models for enhanced message generation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aicommit'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install aicommit
```

## Usage

To generate a commit message:

```shell
aicommit [options] [ref]
```

### Options

- `-a, --amend`: Amend the last commit.
- `-c, --context=CONTEXT`: Extra context beyond the diff. 
  
  Examples:
  1. If your commit involves refactoring a function to improve its performance, you might provide context like:
     ```shell
     aicommit -m MODEL -c "Refactored to improve performance by using algorithm X"
     ```
     This context helps the AI craft a more informative commit message.
  
  2. When your commit is related to a specific JIRA ticket:
     ```shell
     aicommit -m MODEL -c "Resolved issues as per JIRA ticket JIRA-1234"
     ```
     Including the JIRA ticket helps relate the commit to external tracking systems.

  3. Including multiple context strings:
     ```shell
     aicommit -m MODEL -c "Refactored for performance" -c "JIRA-1234"
     ```
     Multiple context strings can be added by repeating the `-c` option.

- `-d, --dry`: Dry run the command without making any changes.
- `-m, --model=MODEL`: Specify the AI model to use.
- `--provider=PROVIDER`: Specify the provider (ollama, openai, anthropic, etc). Note: This only needs to be used when the specified model is available from multiple providers; otherwise, the owner of the model is used by default.
- `--force-external`: Force using external AI provider even for private repos.
- `-s, --style=STYLE`: Path to the style guide file. If not provided, the system looks for `COMMITS.md` in the repo root or uses the default style guide.
- `--version`: Show version.

### Style Guide Example
Here is an example of what a style guide might include:

```
- Use conventional commits format (type: description)
- Keep first line under 72 characters
- Use present tense ("add" not "added")
- Be descriptive but concise
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

1. Fork it (<https://github.com/your_username/aicommit/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
