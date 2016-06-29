# Rumblemania

*Note: The project name was modified to be harder to search for on GitHub*

### Overview
This ruby script plays a game by submitting moves to an AI opponent through a REST API.

Using some simple machine learning strategies to generate and consume test data, this script should eventually best each opponent fairly easily.   

### Setup
1. `git clone` the repository and run `bundle install` to setup dependencies

1. Create a `.env` file in the root directory with one environent variable:
`BASE_URI=[base_uri_of_the_api]`

1. Setup the `config.yml` file with player name, email address, and desired opponent *(Note: `opponent`) is the only required field*

1. Generate test data by running `thor rumble:training_game`. This command has an optional `--count` flag you can use to run multiple games in one command. Each game is serialized to YAML and saved in their own file in `/data`.  
