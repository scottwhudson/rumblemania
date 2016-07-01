require 'marky_markov'

class Strategy
  def initialize(strategy, opponent)
    @strategy = strategy
    @opponent = opponent
    @moves = JSON.parse(RestClient.get(ENV['BASE_URI'] + '/moves/'))
    @dictionary = build_dictionary
  end

  def generate_response(game_object)
    self.send(@strategy, game_object)
  end

  private

  def build_dictionary
    if @strategy == :markov
      dictionary = MarkyMarkov::TemporaryDictionary.new
      game_objects = load_training_files
      files_to_parse.each do |file|
        dictionary.parse_string file[:gamestate][:opponent_moves].join(" ")
      end
    else
      nil
    end

    dictionary
  end

  def load_training_files(files_array = [])
    Dir.chdir('./data')
    files = Dir.glob("*#{@opponent}*").select {|f| File.file? f}

    files.each do |file|
      files_array << YAML::load_file(file)
    end

    files_array
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
    opp_move = @dictionary.generate_1_words
    determine_move(opp_move)
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

  def determine_move(opp_move)
    # fetch the first result that beats the opp_move
  end

end
