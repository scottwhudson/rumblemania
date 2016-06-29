require 'rest-client'
require 'json'
require 'pry'
require 'dotenv'
require 'yaml'

class Game
  attr_accessor :json
  attr_reader :moves

  def initialize
    @json = JSON.parse(fetch_json(load_config), object_class: OpenStruct)
    @moves = JSON.parse(RestClient.get(ENV['BASE_URI'] + '/moves/'))
  end

  def play
    until self.json.gamestate.moves_remaining == 0 do
      opponent_move_count = count_moves(self.json.gamestate.opponent_moves)
      your_move = calc_best_move(self.moves, opponent_move_count)

      self.json.move = your_move

      self.json = JSON.parse(fetch_json(ostruct_to_hash(self.json)), object_class: OpenStruct)

      puts turn_report(self.json)
    end
  end

  def save_data
    puts "saving data"

    File.open("./data/#{Time.now.to_i}#{self.json.gamestate.opponent}.yml", "w") {|f| f.write(ostruct_to_hash(self.json).to_yaml) }
  end

  private

  def load_config
    YAML::load_file(File.join(__dir__, '../config/config.yml'))
  end

  def fetch_json(hash)
    RestClient.post("#{ENV['BASE_URI']}" + '/training/', hash.to_json, content_type: :json)
  end

  def ostruct_to_hash(ostruct, hash = {})
    ostruct.each_pair do |k, v|
      hash[k] = v.is_a?(OpenStruct) ? ostruct_to_hash(v) : v
    end

    hash
  end

  def count_moves(moves_array)
    moves_array.reduce Hash.new(0) do |hash, num|
      hash[num] += 1
      hash
    end
  end

  def calc_best_move(moves, move_count, hash = {})
    return 'A' if move_count.empty? # default

    moves.each do |move|
      hash[move[0]] = move[1]['beats'].map { |a| move_count[a] }.compact.inject(0, :+)
    end

    return hash.max_by{|k,v| v}[0]
  end

  def random_move
    %w(A B C D E F G H I J K).sample
  end

  def turn_report(game)
    "your move: #{game.gamestate.your_moves.last}, " +
    "opponents move: #{game.gamestate.opponent_move}, " +
    "total score: #{game.gamestate.total_score}, " +
    "moves remaining: #{game.gamestate.moves_remaining}"
  end

end
