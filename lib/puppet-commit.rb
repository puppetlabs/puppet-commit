# frozen_string_literal: true

class PuppetCommit
  require 'openai'
  require 'open3'
  require 'json'
  require 'highline'
  def self.commit
    generating_commit_waiting_message()
    OpenAI.configure do |config|
      config.access_token = ENV.fetch('OPENAI_API_KEY', nil)
    end

    client = OpenAI::Client.new

    # Choose a type from the type-to-description JSON below that best describes the git diff:\n${
    styles = {
      docs: 'Documentation only changes',
      style: 'Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)',
      maint: "Other changes that don't modify source code",
      revert: 'Reverts a previous commit',
      feat: 'A new feature',
      bugfix: 'A bug fix'
    }

    command = 'generate a concise commit messgage in the present tense, based on the git diff supplied at the end of this message. ' \
              "The commit message title should be no more than 72 characters long, and you should pick and follow the most relevant style in #{styles} " \
              'Exclude anything unnecessary such as translation. Your entire response will be passed directly into git commit. ' \
              "Git Diff = #{Open3.capture3('git diff')}"

    commit_msg = client.chat(
      parameters: {
        model: 'gpt-3.5-turbo', # Required.
        messages: [{ role: 'user', content: command }], # Required.
        temperature: 0.3
      }
    )

    msg = commit_msg['choices'][0]['message']['content']
    user_prompt(msg)
  end
end

def generating_commit_waiting_message()
  10.times do |i|
    print "Getting an AI generated commit" +  ("." * (i % 5)) + "  \r"
    $stdout.flush
    sleep(0.5)
  end
end

def user_prompt(msg)
  puts "\nCommit message:\n'#{msg}'\n\nAre you happy with the above commit message? [Y/n] "
  answer = gets
  case answer.strip
  when 'Y', 'y', 'yes', 'Yes'
    git_add
    git_commit(msg)
  when 'N', 'n', 'No', 'no'
    puts 'No'
  else
    puts 'No valid response given'
    puts answer
  end
end

def git_add
  puts 'Staging files'
  Open3.capture3('git add .')
end

def git_commit(msg)
  puts "Committing with message: #{msg}"
  Open3.capture3("git commit -m '#{msg}'")
end
