require 'rubygems'
require 'json'
require 'twitter'
require 'sinatra'
require 'erb'

REPOS = YAML.load_file('config.yml')

class GithubTwitter
  
  def initialize(payload)
    payload = JSON.parse(payload)
    return unless payload.keys.include?("repository")
    @repo = payload["repository"]["name"]
    @template = ERB.new(REPOS[@repo]["template"] || "[<%= commit['repo'] %>] <%= commit['url'] %> by <%= commit['author']['name'] %> - <%= commit['message'] %>")
    @twitter = connect(@repo)
    payload["commits"].each { |c| process_commit(c.last) }
  end
  
  def connect(repo)
    credentials = REPOS[repo]
    return Twitter::Base.new(credentials['username'], credentials['password'])
  end
  
  def process_commit(commit)
    commit["repo"] = @repo
    proc = Proc.new do 
      commit
    end
    @twitter.post(@template.result(proc))
  end
  
end

post '/' do
  GithubTwitter.new(params[:payload])
  "OMGPONIES! IT WORKED"
end