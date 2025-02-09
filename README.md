# AIGC

The AI git commit message generator.

## Overview

**aigc** is a Ruby gem designed to generate high-quality commit messages for git diffs. It leverages AI to analyze changes in your codebase and create concise, meaningful commit messages following best practices.

## Features

- **Automatic Commit Message Generation**: Automatically generate commit messages based on code diffs.
- **Security-Aware Provider Selection**: Detects execution in a private repository and ensures non-local providers are not used for security reasons. This means that if you are working within a private repository, the gem will default to local providers unless explicitly forced otherwise.
- **Configurable Style Guide**: Allows using a specific style guide for commit messages, either from a default location or specified by the user.
- **AI Model Integration**: Integration with various AI models for enhanced message generation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aigc'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install aigc
```

## Usage

To generate a commit message:

```shell
aigc [options] [ref]
```

### Options

- `-a, --amend`: Amend the last commit.
- `-c, --context=CONTEXT`: Extra context beyond the diff.
- `-d, --dry`: Dry run the command without making any changes.
- `-m, --model=MODEL`: Specify the AI model to use.
- `--provider=PROVIDER`: Specify the provider (ollama, openai, anthropic, etc). Note: This only needs to be used when the specified model is available from multiple providers; otherwise, the owner of the model is used by default.
- `--force-external`: Force using external AI provider even for private repos.
- `-s, --style=STYLE`: Path to the style guide file. If not provided, the system looks for `COMMITS.md` in the repo root or uses the default style guide.
- `--default`: Print the default style guide and exit the application.
- `--version`: Show version.

### Examples

If your commit involves refactoring a function to improve its performance, you might provide context like:
   ```shell
   aigc -m MODEL -c "Refactored to improve performance by using algorithm X"
   ```

   This context helps the AI craft a more informative commit message.
  
When your commit is related to a specific JIRA ticket:
   ```shell
   aigc -m MODEL -c "Resolved issues as per JIRA ticket JIRA-1234"
   ```

   Including the JIRA ticket helps relate the commit to external tracking systems.

Including multiple context strings:
   ```shell
   aigc -m MODEL -c "Refactored for performance" -c "JIRA-1234"
   ```

   Multiple context strings can be added by repeating the `-c` option.

Using environment variables in context:
   ```shell
   aigc -c "Put the work ticket as the first entry on the subject line" -c "Ticket: $TICKET"
   ```

   This allows you to dynamically include environment variables in your commit message.

### Style Guide Example

The style guide is used as part of the generative AI prompt that instructs the large language model (LLM) how to craft its summary of the `git diff` results.  The see the default style guide use the `--default` option.

You can create your own style guide named `COMMITS.md` in the root directory of your repository.  You can also use the `--style` option to point `aigc` to your style guide if you choose to keep it in a different place.  This is handy when you want to have consistent commit messages across several different projects.

This would be a simple style guide:

```
- Use conventional commits format (type: description)
- Keep first line under 72 characters
- Use present tense ("add" not "added")
- Be descriptive but concise
- Have fun. Be creative. Add ASCII art if you feel like it.
```

## Last Thoughts

This gem saves its commit message in the file `.aigc_msg` at the root directory of the repository.  Its there even if you do a `--dry` run.  This could be handy if you want to incorporate `aigc` into some larger workflow.

Remember that the style guide can be extended using one or more `--context` strings.  For example you could create a shell alias like this:

```
alias gc='aigc -c "JIRA $JIRA_TICKET"'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

1. Fork it (<https://github.com/your_username/aigc/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
