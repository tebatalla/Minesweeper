class Minesweeper
  def run
    # until won? || lost?
    #   display
    #   move
    #     if move == flagged then flag
    #     if move == revealed then reveal
    #   end
    # end
  end
end

class Board
  def initialize(size = 9)
    @size = size
    non_bombs = (@size ** 2) - num_bombs
    marks = ([:bomb] * num_bombs + [:no_bomb] * non_bombs).shuffle
    @tiles = Array.new(@size) { Array.new(@size) { Tile.new(marks.pop) } }
    compute_neighbors
  end

  def compute_neighbors
    move_indices = [-1,0,1].permutation(2).to_a - [0,0] + [1,1] + [-1,-1]
    @tiles.each_with_index do |row, row_index|
      row.each_with_index do |tile, col_index|
        move_indices.each do |move|
          potential_move = [row_index + move[0], col_index + move[1]]
          tile.neighbors << potential_move if valid?(potential_move)
          # tile.compute_bombs
        end
      end
    end
    nil
  end

  def valid?(move)
    move[0].between?(0, @size-1) && move[1].between?(0, @size-1)
  end

  def num_bombs
    @size * 2
  end
end

class Tile
  attr_accessor :neighbors

  def initialize(mark)
    @mark = mark
    @neighbors = []
    @flagged = false
    @revealed = false
  end

  def reveal

  end

  def is_bombed?
    @mark == :bomb
  end
end
