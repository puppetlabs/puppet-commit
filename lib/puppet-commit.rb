# frozen_string_literal: true

class PuppetCommit
  require 'openai'
  require 'open3'
  require 'json'
  require 'ruby_figlet'

  def self.commit(client)
    generating_commit_waiting_message
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

  def self.generating_commit_waiting_message
    puppet_commit_art
    10.times do |i|
      print "Getting an AI generated commit#{'.' * (i % 5)}  \r"
      $stdout.flush
      sleep(0.5)
    end
  end

  def self.puppet_commit_art
    art = RubyFiglet::Figlet.new 'puppet-commit', 'cyberlarge'
    puts art
    puts ''
  end

  def self.user_prompt(msg)
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

  def self.git_add
    puts 'Staging files'
    Open3.capture3('git add .')
  end

  def self.git_commit(msg)
    puts "Committing with message: #{msg}"
    Open3.capture3("git commit -m '#{msg}'")
  end

  def self.create_pr(client)
    labels = %w[maintenance bugfix feature backwards-incompatible]
    git_branch = Open3.capture3('git branch --show-current')[0].strip
    git_diff = Open3.capture3("git diff #{git_branch} origin/main")
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
    puts "Pushing branch #{git_branch}..."
    Open3.capture3("git push origin #{git_branch}")
    cmd = "gh pr create --title \"#{title.gsub('"', '')}\" --body \"#{msg.gsub('"', '')}\" --label #{label}"
    Open3.capture3(cmd)
  end

  # used to return the label and title from the returned ai message
  def self.get_substring(msg, string)
    msg.to_s.match(/#{string}: (,?.*)/).captures[0]
  end
end
