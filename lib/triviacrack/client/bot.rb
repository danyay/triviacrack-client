require "triviacrack"

require_relative "client"
require_relative "solvers/solver"

# Public: A TriviaCrack Client that automatically solves questions for all of
# the user's games.
module TriviaCrack
  module Client
    class Bot < TriviaCrack::Client::Client

      # Public: Runs the trivia bot, playing all currently available games to
      # completion.
      #
      # solver           - The name of a decision module to use
      # start_new_games  - A Boolean indacting whether or not to start new games
      #
      # Examples
      #
      #   trivia_bot = TriviaCrackBot::Bot.new username, session_id
      #   trivia_bot.play "CorrectAnswer", false
      #
      # Returns nothing.
      def play(solver, start_new_games)
        @solver = TriviaCrack::Client::Solvers.get_solver(solver)

        if !@solver.respond_to? :solve
          puts "Solver does not have a solve method."
          exit
        end

        begin
          puts "Starting to play Trivia Crack as #{@username}."

          loop do
            @user = @client.get_user

            if @user.start_new_game? && start_new_games
              start_new_game
            end

            puts "Fetching games for #{@username}..."

            playable_games = @client.get_games.select { |game| game.playable? }

            playable_games.each { |game| play_game game }

            if playable_games.none?
              puts "No games available to play."
            end

            sleep POLL_TIME
          end
        rescue TriviaCrack::Errors::RequestError => e
          puts "Request to the Trivia Crack API failed with code #{e.code}."
        end
      end

      private

      # Internal: The amount of time to wait before checking for new games.
      POLL_TIME = 60

      # Internal: The maximum amount of time to wait between questions.
      QUESTION_DELAY_MAX = 10

      # Internal: The minimum amount of time to wait between questions.
      QUESTION_DELAY_MIN = 1

      # Internal: Plays the given game to completion.
      #
      # game   - TriviaCrack::Game.
      #
      # Examples
      #
      #   play_game game
      #
      # Returns nothing.
      def play_game(game)

        puts "Playing game #{game.id} against #{game.opponent.username}."

        while game.playable? do
          # Sleep for a random number of seconds, so responses are not all
          # instantaneous and seem more natural.
          sleep_time = Random.rand(QUESTION_DELAY_MIN..QUESTION_DELAY_MAX)
          puts "\nWaiting #{sleep_time} seconds before the next question...\n\n"

          sleep sleep_time

          question = game.questions.first
          answer = @solver.solve @user, game, question

          puts " Category : #{question.category}"
          puts " Question : #{question.text}"
          print "   Answer : #{question.answers[answer]}"

          game, result = @client.answer_question game.id, question, answer

          puts result ? " - Correct!" : " - Incorret!"
        end

        puts "Finished playing game #{game.id}. Status: #{game.game_status}."

      end

    end
  end
end
