require 'json'
require 'rest-client'
require 'pry'
require 'dotenv'
require_relative './lib/game'
require_relative './lib/error'

Dotenv.load

class Rumble < Thor

  # strategy params for CLI
  STRATEGIES = %w(random move_sum mixed markov nbayes)

  desc "opponents", "fetches a list of opponent names and slugs"
  def opponents
    opponents = JSON.parse(RestClient.get(ENV['BASE_URI'] + '/opponents/'))
    p opponents
  end

  desc "training_game", "plays a game or set of games using the training endpoint and saves all of the game data to a YAML file in /data"
  option :count
  option :strat
  def training_game
    count, strategy = validate_opts(options)
    i = 1

    count.times do
      puts "playing game #{i} of #{count}"
      game = Game.new(strategy)
      game.play
      game.save_data
      i += 1
    end
  end

  private

  def validate_opts(opts)
    count = if opts[:count]
      raise OptsError, 'Count must be greater than 0' if opts[:count].to_i < 1
      opts[:count].to_i
    else
      1
    end

    strategy = if opts[:strat]
      raise OptsError, 'Invalid strategy type' unless STRATEGIES.include?(opts[:strat])
      opts[:strat].to_sym
    else
      :random
    end

    [count, strategy]
  end


end
