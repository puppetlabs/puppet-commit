# frozen_string_literal: true

class PuppetCommit
  require 'openai'
  require 'open3'
  require 'json'
  require 'ruby_figlet'

  def self.commit(client, create_pr = false)
    generating_commit_waiting_message
    commit_msg = create_commit_message(client)
    user_prompt(commit_msg, client)
    create_pr(client) if create_pr
  end
end

def user_prompt(commit_msg, client)
  ARGV.clear # clear the ARGV array so that the user can be prompted for input
  msg = commit_msg['choices'][0]['message']['content']
  satisfactory_message = false
  count = 0
  until satisfactory_message
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
      msg = create_commit_message(client)['choices'][0]['message']['content']
    else
      puts 'No valid response given'
      break
    end
  end
end

def create_commit_message(client)
  branch = git_branch

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
            ' The title should be prefixed by a tag. The tag should be placed in between parenthesis. ' \
            " The following list contains all valid tags you can use alongside a description for each of them: #{styles} " \
            'You only need to prefix the tag, there is no need to include the description of the tag.' \
            'Do not reference irrelevant changes, such as translation. Your entire response will be passed directly into a git commit. ' \
            "Git Diff = #{Open3.capture3('git diff')}"

  client.chat(
    parameters: {
      model: 'gpt-3.5-turbo', # Required.
      messages: [{ role: 'user', content: command }], # Required.
      temperature: 0.3 # Controls randomness
    }
  )
end

def create_pr(client)
  labels = %w[maintenance bugfix feature backwards-incompatible]
  branch = git_branch
  git_diff = Open3.capture3("git log origin/main..#{branch}")
  command = 'generate a github PR title, based on the git commits at the end of this message. ' \
            "The PR title should be no more than 72 characters long, and you should pick the most relevant label in #{labels} and return this seperately as 'Label: <insert_label_here>'. " \
            "Git commits = #{git_diff}"

  pr = client.chat(
    parameters: {
      model: 'gpt-3.5-turbo', # Required.
      messages: [{ role: 'user', content: command }], # Required.
      temperature: 0.3
    }
  )
  msg = pr['choices'][0]['message']['content']
  label = get_substring(msg, 'Label')
  title = get_substring(msg, 'Title')
  puts "Pushing branch #{branch}..."
  Open3.capture3("git push origin #{branch}")
  cmd = "gh pr create --title \"#{title.gsub('"', '')}\" --body \"#{msg.gsub('"', '')}\" --label #{label}"
  Open3.capture3(cmd)
end

# used to return the label and title from the returned ai message
def get_substring(msg, string)
  msg.to_s.match(/#{string}: (,?.*)/).captures[0]
end

def generating_commit_waiting_message
  puppet_commit_art
  10.times do |i|
    print "Getting an AI generated commit#{'.' * (i % 5)}  \r"
    $stdout.flush
    sleep(0.5)
  end
end

def puppet_commit_art
  art = RubyFiglet::Figlet.new 'puppet-commit', 'cyberlarge'
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
