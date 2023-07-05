# frozen_string_literal: true

class PuppetCommit
  require 'openai'
  require 'open3'
  require 'json'
  require 'highline'
  require 'ruby_figlet'
  def self.commit
    generating_commit_waiting_message
    OpenAI.configure do |config|
      config.access_token = ENV.fetch('OPENAI_API_KEY', nil)
    end

    commit_msg = create_commit_message

    user_prompt(commit_msg)
  end
end

def user_prompt(commit_msg)
  msg = commit_msg['choices'][0]['message']['content']
  satisfactory_message = false
  count = 0
  while !satisfactory_message
    puts "\n\n--------------------------------------------------------------------------------------"
    puts "Commit message:\n\n'#{msg}'\n\n"
    puts "\n--------------------------------------------------------------------------------------"
    puts "\nAre you happy with the above commit message? [Y/n] "
    answer = gets
    case answer.strip
    when 'Y', 'y', 'yes', 'Yes', 'YES'
      git_add
      git_commit(msg)
      satisfactory_message = true
    when 'N', 'n', 'No', 'no', 'NO'
      if count == 2
        puts 'Exiting...'
        break
      end
      count += 1
      msg = create_commit_message['choices'][0]['message']['content']
    else
      puts 'No valid response given'
      break
    end
  end
end

def create_commit_message
  client = OpenAI::Client.new
  branch = git_branch()

  # Choose a type from the type-to-description JSON below that best describes the git diff:\n${
  styles = {
    docs: 'Documentation only changes',
    syntax: 'Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)',
    maint: "Other changes that don't modify source code",
    revert: 'Reverts a previous commit',
    feat: 'Code that adds new functionality to the system',
    bugfix: 'A bug fix'
  }

  command = 'Generate a concise commit message in the present tense, based on the git diff supplied at the end of this message. ' \
            "The commit message title should be no more than 72 characters long. The title should be based on the branch name: #{branch}. " \
            " The title should be prefixed by a tag. The tag should be placed in between parenthesis. " \
            " The following list contains all valid tags you can use alongside a description for each of them: #{styles} " \
            'You only need to prefix the tag, there is no need to include the description of the tag.' \
            'Do not reference irrelevant changes, such as translation. Your entire response will be passed directly into a git commit. ' \
            "Git Diff = #{Open3.capture3('git diff')}"

  commit_msg = client.chat(
    parameters: {
      model: 'gpt-3.5-turbo', # Required.
      messages: [{ role: 'user', content: command }], # Required.
      temperature: 0.3 # Controls randomness
    }
  )

  commit_msg
end

def generating_commit_waiting_message
  puppet_commit_art
  10.times do |i|
    print "Getting an AI generated commit" +  ("." * (i % 5)) + "  \r"
    $stdout.flush
    sleep(0.5)
  end
end

def puppet_commit_art
  art = RubyFiglet::Figlet.new "puppet-commit", 'cyberlarge'
  puts art
  puts ''
end

def git_add
  puts 'Staging files'
  Open3.capture3('git add .')
end

def git_commit(msg)
  puts "Committing with message: #{msg}"
  Open3.capture3("git commit -m '#{msg}'")
end

def git_branch
  Open3.capture3('git branch --show-current')[0].strip
end
