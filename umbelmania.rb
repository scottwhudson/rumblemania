require 'rest-client'
require 'json'
require 'pry'
require 'dotenv'

Dotenv.load

def count_moves(moves_array)
  moves_array.reduce Hash.new(0) do |hash, num|
    hash[num] += 1
    hash
  end
end

def calculate_best_move(moves, move_count)
  return 'A' if move_count.empty? # default

  moves_count_hash = {}
  moves.each do |move|
    moves_count_hash[move[0]] = move[1]['beats'].map { |a| move_count[a] }.compact.inject(0, :+)
  end

  return moves_count_hash.max_by{|k,v| v}[0]
end

moves = JSON.parse(RestClient.get(ENV['ENDPOINT'] + '/moves/'))
opponents = JSON.parse(RestClient.get(ENV['ENDPOINT'] + '/opponents/'))

game_config  = {
  'player_name' => 'Scoots McGoots',
  'email' => 'test@test.com',
  'opponent' => 'senor-amistoso'
}

game = JSON.parse( RestClient.post("#{ENV['ENDPOINT']}/training/",
                   game_config.to_json,
                   content_type: :json)
                 )
                 
game['gamestate']['moves_remaining'].times do
  opponent_move_count = count_moves(game['gamestate']['opponent_moves'])
  your_move = calculate_best_move(moves, opponent_move_count)

  game['move'] = your_move
  game = JSON.parse(RestClient.post("#{ENV['ENDPOINT']}/training/" , game.to_json, content_type: :json))

  puts "your move: #{your_move}, opponents move: #{game['gamestate']['opponent_move']}, total score: #{game['gamestate']['total_score']}, moves remaining: #{game['gamestate']['moves_remaining']}"
end

puts game
