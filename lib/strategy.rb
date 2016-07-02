require 'marky_markov'
require 'nbayes'

class Strategy
  def initialize(strategy, opponent)
    @strategy = strategy
    @opponent = opponent
    @moves = JSON.parse(RestClient.get(ENV['BASE_URI'] + '/moves/'))
    @dictionary = generate_dictionary
  end

  def generate_response(game_object)
    self.send(@strategy, game_object)
  end

  private

  def generate_dictionary
    if @strategy == :markov
      dictionary = MarkyMarkov::TemporaryDictionary.new
    elsif @strategy == :nbayes
      dictionary = NBayes::Base.new
    else
      return nil
    end

    train_dictionary(dictionary)
  end

  def train_dictionary(dictionary)
    game_objects = load_training_files
    puts "training dictionary with #{game_objects.count} files"

    game_objects.each do |game|
      if @strategy == :markov
        dictionary.parse_string game[:gamestate][:opponent_moves].join(" ")
      elsif @strategy == :nbayes
        moves_hash = fetch_index_pairs(game)
        moves_hash.each { |hash| dictionary.train(hash[1], hash[0]) }
      end
    end

    dictionary
  end

  def load_training_files(files = [])
    Dir.chdir('./data')
    filenames = Dir.glob("*#{@opponent}*").select {|f| File.file? f}
    filenames.each { |f| files << YAML::load_file(f) }
    Dir.chdir('..')
    files
  end

  # move strategy methods go here
  # :TODO remove game param from unused methods
  def random(game)
    %w(A B C D E F G H I J K).sample
  end

  def move_sum(game)
    opp_move_count = count_moves(game.gamestate.opponent_moves)
    return calc_best_move(@moves, opp_move_count)
  end

  def markov(game)
    opp_move = [@dictionary.generate_1_words]
    determine_move(opp_move)
  end

  def nbayes(game)
    move_index = 1000 - game.gamestate.moves_remaining
    opp_moves_hash = @dictionary.classify([move_index.to_s])
    moves_with_prob = opp_moves_hash.sort_by { |move, prob| prob}.reverse.first(5)
    opp_moves = moves_with_prob.map { |val| val[0] }
    determine_move(opp_moves)
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

  def fetch_index_pairs(file, training_hash = {})
    @moves.each do |move|
      move_indices = []

      file[:gamestate][:opponent_moves].each_with_index do |m, index|
        move_indices << "#{index}" if m == move[0]
      end

      training_hash[move[0]] = move_indices
    end

    training_hash
  end

  # all 5 moves
  # iterate through possible moves, if array subtraction = 0, return value
  # if array subtraction != 0, pop array and retry
  def determine_move(opp_move_array)
    optimal_move = nil

    @moves.each do |move|
      if opp_move_array - move[1]['beats'] == []
        optimal_move = move[0]
        break
      end
    end

    if optimal_move == nil
      opp_move_array.pop
      determine_move(opp_move_array)
    else
      return optimal_move
    end
  end

end
