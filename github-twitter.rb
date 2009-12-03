require 'rubygems'
require 'json'
require 'twitter'
require 'sinatra'
require 'erb'
require 'bitly'

REPOS = YAML.load_file('config.yml')

class GithubTwitter

  def initialize(payload)
    payload = JSON.parse(payload)
    return unless payload.keys.include?("repository")
    @repo = payload["repository"]["name"]
    @template = ERB.new(REPOS[@repo]["template"])
    @twitter = connect(@repo)
    @bitly = bitly(@repo)
    payload["commits"].each { |c| process_commit(c) }
  end

  def connect(repo)
    credentials = REPOS[repo]
    httpauth = Twitter::HTTPAuth.new(credentials['username'], credentials['password'])
    return Twitter::Base.new(httpauth)
  end

  def process_commit(commit)
    commit["repo"] = @repo
    proc = Proc.new do
      commit
    end
    commit['url'] = @bitly.shorten(commit['url']).short_url if @bitly
    @twitter.update(@template.result(proc))
  end

  def bitly(repo)
    credentials = REPOS[repo]
    return nil unless credentials['bitly_username'] && credentials['bitly_api_key']
    Bitly.new(credentials['bitly_username'], credentials['bitly_api_key'])
  end
end

post '/' do
  GithubTwitter.new(params[:payload])
  "OMGPONIES! IT WORKED"
end