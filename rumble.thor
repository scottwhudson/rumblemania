require 'json'
require 'rest-client'
require 'pry'
require 'dotenv'
require_relative './lib/game'

Dotenv.load

class Rumble < Thor

  desc "opponents", "fetches a list of opponent names and slugs"
  def opponents
    opponents = JSON.parse(RestClient.get(ENV['BASE_URI'] + '/opponents/'))
    p opponents
  end

  desc "training_game", "plays a game or set of games using the training endpoint and saves all of the game data to a YAML file in /data"
  option :count
  def training_game
    count = options[:count].to_i || 1
    i = 1

    count.times do
      puts "playing game #{i} of #{count}"
      game = Game.new
      game.play
      game.save_data
      i += 1
    end
  end

end
