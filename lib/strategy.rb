require 'marky_markov'
require 'nbayes'

class Strategy

  # @param strategy [Symbol] type of strategy used in the current game
  # @param opponent [String] name of opponent in the current game
  def initialize(strategy, opponent)
    @strategy = strategy
    @opponent = opponent
    @moves = JSON.parse(RestClient.get(ENV['BASE_URI'] + '/moves/'))
    @dictionary = generate_dictionary
  end

  # calls the correct strategy method and passes the game object to the strategy
  # method if necessary
  #
  # @param game [OpenStruct] json response from API containing all game data
  def generate_response(game)
    if @strategy == :random || @strategy == :markov
      self.send(@strategy)
    else
      self.send(@strategy, game)
    end
  end

  private

  # creates new instance of dictionary object if using markov chains or
  # naive bayes and initializes the training of the dictionary
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

  # Loads the training games into memory and trains the provided dictionary using
  # corresponding strategy
  #
  # @param dictionary [Dictionary] used for machine-learning responses to input
  def train_dictionary(dictionary)
    training_games = load_training_files
    puts "training dictionary with #{training_games.count} files"

    training_games.each do |game|
      if @strategy == :markov
        dictionary.parse_string game[:gamestate][:opponent_moves].join(" ")
      elsif @strategy == :nbayes
        opponent_moves = fetch_index_pairs(game)
        opponent_moves.each { |hash| dictionary.train(hash[1], hash[0]) }
      end
    end

    dictionary
  end

  # Fetches YAML filenames in /data with corresponding opponent name, loads
  # files into files array and returns the files array to the caller
  def load_training_files(files = [])
    Dir.chdir('./data')
    filenames = Dir.glob("*#{@opponent}*").select {|f| File.file? f}
    filenames.each { |f| files << YAML::load_file(f) }
    Dir.chdir('..')
    files
  end

  # Returns a randomly generated move
  def random
    %w(A B C D E F G H I J K).sample
  end

  # Determines the opponent's most commonly used move and passes this to #counter_move
  #
  # @param game [OpenStruct] json response from API containing all game data
  def move_sum(game)
    opp_move = [count_moves(game)]
    counter_move(opp_move)
  end

  # Randomly generates a move based on the markov chain dictionary and passes it to
  # #counter_move
  def markov
    opp_move = [@dictionary.generate_1_words]
    counter_move(opp_move)
  end

  # Determines the current move number and passes it to #fetch_opponent_moves,
  # and passes the result to #counter_move
  #
  # @param game [OpenStruct] json response from API containing all game data
  def nbayes(game)
    move_index = 1000 - game.gamestate.moves_remaining
    opp_moves = fetch_opponent_moves(move_index)
    counter_move(opp_moves)
  end

  # Queries the dictionary with move_index which returns a hash of all possible responses
  # with their probabilities. We'll fetch the 5 most probable responses
  #
  # @param move_index [Integer] index position of move
  def fetch_opponent_moves(move_index)
    opp_moves_hash = @dictionary.classify([move_index.to_s])
    moves_with_prob = opp_moves_hash.sort_by { |move, prob| prob }.reverse.first(5)
    opp_moves = moves_with_prob.map { |val| val[0] }
    opp_moves
  end

  # @param game [OpenStruct] json response from API containing all game data
  def count_moves(game)
    game.gamestate.opponent_moves.max_by(&:size)
  end

  # @param game [OpenStruct] json response from API containing all game data
  def fetch_index_pairs(game, move_hash = {})
    @moves.each do |move|
      move_indices = fetch_indices(game, move[0])
      move_hash[move[0]] = move_indices
    end

    move_hash
  end

  # @param game [OpenStruct] json response from API containing all game data
  # @param move [String] single-letter move identifier (ex: "A")
  def fetch_indices(game, move, indices = [])
    game[:gamestate][:opponent_moves].each_with_index do |m, index|
      indices << index.to_s if m == move
    end

    indices
  end

  # Iterates through @moves to find move that will counter all possible opponent
  # moves using array subtraction.  If one is not found, the last element of the
  # array is popped and the method recurses until a counter move is found.
  #
  # @param opp_move_array [Array] expected moves the opponent will make this turn
  def counter_move(opp_move_array, optimal_move = nil)
    @moves.each do |move|
      if opp_move_array - move[1]['beats'] == []
        optimal_move = move[0]
        break
      end
    end

    return optimal_move if optimal_move
    opp_move_array.pop
    counter_move(opp_move_array)
  end

end
