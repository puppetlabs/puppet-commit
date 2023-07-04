class PuppetCommit
  require 'openai'
  def self.commit
    # Configure OpenAI API credentials
    client = OpenAI::Client.new(
      access_token: ENV.fetch('OPENAI_API_KEY'),
      request_timeout: 240
    )
    puts client.class
  end
end
