# frozen_string_literal: true

class PuppetCommit
  require 'openai'
  require 'open3'
  require 'json'
  require 'highline'
  def self.commit
    OpenAI.configure do |config|
      config.access_token = ENV.fetch('OPENAI_API_KEY', nil)
    end

    client = OpenAI::Client.new

    # Choose a type from the type-to-description JSON below that best describes the git diff:\n${
    styles = {
      docs: 'Documentation only changes',
      style: 'Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)',
      refactor: 'A code change that neither fixes a bug nor adds a feature',
      maint: "Other changes that don't modify src or test files",
      revert: 'Reverts a previous commit',
      feat: 'A new feature',
      bugfix: 'A bug fix'
    }

    command = 'generate a concise commit messgage in the present tense, based on the git diff supplied at the end of this message.' \
              "The commit message title should be no more than 72 characters long, and you should pick and follow the most relevant style in #{styles}" \
              'Exclude anything unnecessary such as translation. Your entire response will be passed directly into git commit.' \
              "Git Diff = #{Open3.capture3('git diff')}"

    commit_msg = client.chat(
      parameters: {
        model: 'gpt-3.5-turbo', # Required.
        messages: [{ role: 'user', content: command }], # Required.
        temperature: 0.3
      }
    )
    puts 'staging files'
    Open3.capture3('git add .')

    msg = commit_msg['choices'][0]['message']['content']
    puts "committing with message: #{msg}"
    Open3.capture3("git commit -m '#{msg}'")
  end
end
