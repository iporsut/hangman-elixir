defmodule Hangman do

  @min_word_length 5

  @max_word_length 9

  def all_words do
    String.split File.read!("/usr/share/dict/words"), "\n", trim: true
  end

  def get_words do
    Enum.filter all_words(), fn w ->
      l = String.length(w)
      l > @min_word_length && l < @max_word_length
    end
  end

  def random_word do
    ws = get_words()
    Enum.at(ws, :rand.uniform(length(ws)) - 1)
  end

  def show({_, discovered, guessed}) do
    (discovered
     |> Enum.map(fn
       nil -> "_"
       ch  -> ch
     end)
     |> Enum.join(" ")) <> " Guessed so far: #{guessed}"
  end

  def fresh_puzzle(str) do
    discovered = Enum.take Stream.repeatedly(fn -> nil end), String.length(str)
    {str, discovered, ""}
  end

  def char_in_word?({str, _, _}, ch) do
    String.contains?(str, ch)
  end

  def already_guessed?({_, _, guessed}, ch) do
    String.contains?(guessed, ch)
  end

  def fill_in_character({word, filled_in_so_far, s}, ch) do
    new_filled_in_so_far =
      word
      |> String.split("", trim: true)
      |> Enum.zip(filled_in_so_far)
      |> Enum.map(fn
        {^ch, _} -> ch
        {_, f} -> f
      end)

    {word, new_filled_in_so_far, ch <> s}
  end

  def handle_guess(puzzle, guess) do
    IO.puts("Your guess was: #{guess}")
    case {char_in_word?(puzzle, guess), already_guessed?(puzzle, guess)} do
      {_, true} ->
        IO.puts "You already guessed that character, pick something else!"
        puzzle
      {true, _} ->
        IO.puts "This character was in the word, filling in the word accordingly"
        fill_in_character puzzle, guess
      {false, _} ->
        IO.puts "This character wasn't in the word, try again."
        fill_in_character puzzle, guess
    end
  end

  def game_over({word_to_guess, _, guessed}) do
    if String.length(guessed) > 30 do
      IO.puts "You lose!"
      IO.puts "The word was: #{word_to_guess}"
      System.halt()
    end
  end

  def game_win({word_to_guess, filled_in_so_far, _}) do
    if Enum.all?(filled_in_so_far) do
      IO.puts "You win!"
      IO.puts "The word was: #{word_to_guess}"
      System.halt()
    end
  end

  def run_game(puzzle) do
    game_over(puzzle)
    game_win(puzzle)
    IO.puts "Current puzzle is: #{show(puzzle)}"
    guess = String.trim(IO.gets "Guess a letter: ")
    cond do
      String.length(guess) == 1 ->
        run_game(handle_guess(puzzle, guess))
      true ->
        IO.puts "Your guess must be a single character"
        run_game(puzzle)
    end
  end

  def main(_args) do
    word = random_word()
    puzzle = fresh_puzzle(String.downcase(word))
    run_game(puzzle)
  end
end
