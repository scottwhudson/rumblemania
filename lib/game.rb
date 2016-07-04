require 'rest-client'
require 'json'
require 'pry'
require 'dotenv'
require 'yaml'
require_relative './strategy'

class Game
  attr_accessor :json

  def initialize(strategy)
    @json = JSON.parse(fetch_json(load_config), object_class: OpenStruct)
    @strategy = Strategy.new(strategy, self.json.gamestate.opponent)
  end

  # Loops through the current game, fetches a move response from @strategy at each turn,
  # POSTS the move to the specified endpoint, and prints a report
  def play
    until self.json.gamestate.moves_remaining == 0 do
      self.json.move = @strategy.generate_response(self.json)
      self.json = JSON.parse(fetch_json(ostruct_to_hash(self.json)), object_class: OpenStruct)
      puts turn_report(self.json)
    end
  end

  # saves the final JSON response to a YAML file for easy serialization
  def save_data
    puts "saving data"

    File.open(generate_filename(self), "w") do |f|
      f.write(ostruct_to_hash(self.json).to_yaml)
    end
  end

  private

  # Load config file from /config
  def load_config
    YAML::load_file(File.join(__dir__, '../config/config.yml'))
  end

  # Handles POST request to endpoint with current game data
  #
  # @param game [Hash] game object payload for POST request
  def fetch_json(game)
    RestClient.post("#{ENV['BASE_URI']}" + "#{ENV['ENDPOINT']}", game.to_json, content_type: :json)
  end

  # Interpolates integer timestamp and opponent name for easy retrieval
  # during training step
  #
  # @param game [OpenStruct] object containing current game state
  def generate_filename(game)
    "./data/#{Time.now.to_i}#{game.json.gamestate.opponent}.yml"
  end

  # Converts given OpenStruct object to a Hash
  #
  # @param ostruct [OpenStruct] game object to be converted
  def ostruct_to_hash(ostruct, hash = {})
    ostruct.each_pair do |k, v|
      hash[k] = v.is_a?(OpenStruct) ? ostruct_to_hash(v) : v
    end

    hash
  end

  # Prints report containing player moves, score, and move count
  #
  # @param game [OpenStruct] object containing current game state
  def turn_report(game)
    "your move: #{game.gamestate.your_moves.last}, " +
    "opponents move: #{game.gamestate.opponent_move}, " +
    "total score: #{game.gamestate.total_score}, " +
    "moves remaining: #{game.gamestate.moves_remaining}"
  end

end
