require 'byebug'
require 'io/console'
require 'yaml'
require 'colorize'

class Minesweeper
  def initialize
    @board = Board.new
  end

  def inspect
  end

  def run
    until @board.won? || @board.lost?
      system('clear')
      display
      move
    end
    @board.reveal_bombs if @board.lost?
    display
    message(@board.won?)
    replay
  end

  def save_game
    File.open("minesweeper_save.yml", 'w') do |f|
      f.puts @board.to_yaml
    end
  end

  def load_game
    @board = YAML::load(File.open("minesweeper_save.yml"))
  end

  def replay
    puts 'Play again (y/N)?'
    input = gets.chomp
    if input == 'y'
      @board = Board.new
      run
    else
      puts "Goodbye"
    end
  end

  def message(won)
    puts won ? "You win!" : "You lose!"
  end

  def display
    @board.display
  end

  def move
    puts "Use the arrow keys to select a coordinate. Hit r to reveal, f to flag"
    puts "Enter 's' to save or 'l' to load"
    input = read_char
    case input
    when "\e[A" #up
      @board.cursor_move(:up)
    when "\e[B" #down
      @board.cursor_move(:down)
    when "\e[C" #right
      @board.cursor_move(:right)
    when "\e[D" #left
      @board.cursor_move(:left)
    when 'f'
      @board.flag
    when 'r'
      @board.reveal
    when 's'
      save_game
      exit 0
    when 'q'
      exit 0
    when 'l'
      load_game
    when "\u0003"
      exit 0
    else
      puts 'invalid action'
    end
  end

  def read_char
    begin
      STDIN.echo = false
      STDIN.raw!

      input = STDIN.getc.chr
      if input == "\e"
        input << STDIN.read_nonblock(3) rescue nil
        input << STDIN.read_nonblock(2) rescue nil
      end
    ensure
      STDIN.echo = true
      STDIN.cooked!

      return input
    end
  end
end

class Board
  def initialize(size = 9)
    @size = size
    @cursor = [0, 0]
    non_bombs = (@size**2) - num_bombs
    marks = ([:bomb] * num_bombs + [:no_bomb] * non_bombs).shuffle
    @tiles = Array.new(@size) { Array.new(@size) { Tile.new(marks.pop) } }
    compute_neighbors
  end

  def compute_neighbors
    move_indices = [-1,0,1].permutation(2).to_a - [[0,0]] + [[1,1], [-1,-1]]
    @tiles.each_with_index do |row, row_index|
      row.each_with_index do |tile, col_index|
        move_indices.each do |move|
          potential_move = [row_index + move[0], col_index + move[1]]
          tile.neighbors << self[potential_move] if valid?(potential_move)
          tile.compute_bombs
        end
      end
    end
    nil
  end

  def [](pos)
    return @tiles[pos[0]][pos[1]]
  end

  def valid?(move)
    move[0].between?(0, @size-1) && move[1].between?(0, @size-1)
  end

  def num_bombs
    @size
  end

  def flag
    self[@cursor].flagged
  end

  def lost?
    @tiles.any? do |row|
      row.any? do |tile|
        tile.mark == :bomb && tile.revealed == true
      end
    end
  end

  def reveal_bombs
    @tiles.each do |rows|
      rows.each do |tile|
        finalize(tile)
      end
    end
  end

  def finalize(tile)
    if tile.is_bomb?
      if tile.revealed
        tile.killing_bomb
      else
        tile.reveal
      end
    else
      if tile.is_flagged?
        tile.bad_flag
      end
    end
  end

  def won?
    @tiles.all? do |row|
      row.all? do |tile|
        (!tile.is_bomb? && tile.revealed) || tile.is_bomb?
      end
    end
  end

  def reveal
    self[@cursor].reveal
  end

  def display
    @tiles.each_with_index do |row, row_i|
      row.each_with_index do |tile, col_i|
        if !is_cursor?([row_i, col_i])
          print tile.display + ' '
        elsif won? || lost?
          print tile.display + ' '
        else
          print " ".colorize(background: :white) + ' '
        end
      end
      print "\n"
    end
  end

  def is_cursor?(pos)
    @cursor == pos
  end

  def cursor_move(direction)
    case direction
    when :right
      @cursor[1] += 1 unless @cursor[1] == @size - 1
    when :left
      @cursor[1] -= 1 unless @cursor[1] < 1
    when :up
      @cursor[0] -= 1 unless @cursor[0] < 1
    when :down
      @cursor[0] += 1 unless @cursor[0] == @size - 1
    else
    end
  end
end

class Tile
  attr_accessor :neighbors
  attr_reader :mark, :revealed, :bad_flag, :killing_bomb

  def initialize(mark)
    @mark = mark
    @neighbors = []
    @flagged = false
    @revealed = false
    @bad_flag = false
    @killing_bomb = false
  end

  def reveal
    if !@flagged && !@revealed
      @revealed = true
      if @num_bombs == 0
        @neighbors.each do |neighbor|
          neighbor.reveal unless (neighbor.revealed || is_bomb?)
        end
      end
    elsif @revealed
      if neighbors.count { |neighbor| neighbor.is_flagged? } == @num_bombs
        neighbors.each { |neighbor| neighbor.reveal unless neighbor.revealed }
      end
    end
  end

  def flagged
    @flagged = !@flagged
  end

  def is_flagged?
    @flagged
  end

  def compute_bombs
    @num_bombs = neighbors.count do |neighbor|
      neighbor.is_bomb?
    end
  end

  def is_bomb?
    (@mark == :bomb)
  end

  def number_colors
    [:light_blue, :green, :light_red, :light_magenta, :cyan, :blue, :light_cyan,
      :magenta][@num_bombs - 1]
  end

  def killing_bomb
    @killing_bomb = true
  end

  def bad_flag
    @bad_flag = true
  end

  def display
    case @revealed
    when true
      case is_bomb?
      when true
        if @killing_bomb
          'X'.colorize(color: :red, background: :white)
        else
          'B'.colorize(:red)
        end
      else
        @num_bombs == 0 ? "*".colorize(:white) : "#{@num_bombs}".colorize(number_colors)
      end
    else
      if @flagged && !@bad_flag
        'F'.colorize(:red)
      elsif @bad_flag
        'B'.colorize(color: :red, background: :white)
      else
        '#'.colorize(:yellow)
      end
    end
  end
end


# if __FILE__ == $PROGRAM_NAME
#   game = Minesweeper.new
#   input = ""
#   while input != 'q'
#
#   end
# end
