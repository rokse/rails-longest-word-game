require 'open-uri'
require 'json'

class LongestwordController < ApplicationController

  def game
    @grid = generate_grid(9)
    @now = Time.now
    @start_time = @now.min * 60 + @now.sec
  end

  def generate_grid(grid_size)
    Array.new(grid_size) { ('A'..'Z').to_a[rand(26)] }
  end

  def score
    @end = Time.now
    @end_time = @end.min * 60 + @end.sec
    @attempt = params[:attempt]
    @grid = params[:grid].split("")
    @start_time = params[:time].to_i
    @translation = get_translation(@attempt)
    @time = @end_time - @start_time
    @score = compute_score(@attempt, @time)
    @result = score_and_message(@attempt, @translation, @grid, @time)
    if session[:games] == nil
      session[:games] = 1
    else
      session[:games] += 1
    end
    if session[:score] == nil
      session[:score] = @score
    else
      session[:score] += @score
    end
    session[:average_score] = session[:score] / session[:games]
  end

  def get_translation(word)
      begin
        response = open("https://api-platform.systran.net/translation/text/translate?source=en&target=fr&key=d752a2f1-95f8-457f-a711-6a9f57783e10&input=#{word}")
        json = JSON.parse(response.read.to_s)
        if json['outputs'] && json['outputs'][0] && json['outputs'][0]['output'] && json['outputs'][0]['output'] != word
          return json['outputs'][0]['output']
        end
      rescue
        if File.read('/usr/share/dict/words').upcase.split("\n").include? word.upcase
          return word
        else
          return nil
        end
      end
  end

  def compute_score(attempt, time_taken)
    (time_taken > 60.0) ? 0 : attempt.size * (1.0 - time_taken / 60.0)
  end

  def included?(guess, grid)
    guess = @attempt.upcase.split("")
    guess.all? { |letter| guess.count(letter) <= grid.count(letter) }
  end

  def score_and_message(attempt, translation, grid, time)
    if included?(attempt.upcase, grid)
      if translation
        score = compute_score(attempt, time)
        [score, "well done"]
      else
        [0, "not an english word"]
      end
    else
      [0, "not in the grid"]
    end
  end
end
