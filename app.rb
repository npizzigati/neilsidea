require 'bundler/setup'

require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'json'
require 'sinatra/custom_logger'
require 'logger'
require 'puma'

enable :logging
set :logger, Logger.new(STDOUT)

UPLOADS_DIRECTORY_NAME = 'data'.freeze

get '/' do
  redirect :upload
end

get '/upload' do
  erb :upload
end

post '/upload' do
  # Check if user uploaded a file
  return unless params[:file] && params[:file][:filename]

  filename = params[:file][:filename]
  target_path = File.join uploads_path, filename
  retrieve_upload(params, target_path)
  @inflections_map = extract_inflections(target_path).to_json
  erb :editor
end

get '/editor' do
  erb :editor
end

def root_path
  File.expand_path(__dir__)
end

def uploads_path
  File.join root_path, UPLOADS_DIRECTORY_NAME
end

def retrieve_upload(params, target_path)
  logger.info "params[:file] #{params[:file]}"
  # Save file in target_path
  tempfile = params[:file][:tempfile]
  File.open(target_path, 'wb') { |f| f.write tempfile.read }
end

def extract_inflections(target_path)
  headwords = retrieve_headwords(target_path)
  inflections_map = {}

  File.open('data/inflections.txt') do |f|
    f.each_line do |line|
      inflection, lemma, _pos = line.split(', ')
      inflections_map[inflection] = lemma if headwords.include?(lemma)
    end
  end

  inflections_map
end

def retrieve_headwords(target_path)
  raw_headword_text = retrieve_raw_headword_text(target_path)
  retrieve_unique_words(raw_headword_text)
end

def retrieve_raw_headword_text(target_path)
  File.read(target_path).downcase
end

def retrieve_unique_words(raw_headword_text)
  Set.new(raw_headword_text.split("\r\n"))
end