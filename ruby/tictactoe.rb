module TicTacToe
  class Game
    def initialize(o,x)
      @o, @x = o, x
      @map = [[nil,nil,nil]]*3
    end

    def on_game_set(&block)
      @on_game_set = &block
    end

    def [](y,x)
      @map[y][x]
    end

    def start
      loop do
        x.ask(@map.dup)
        o.ask(@map.dup)
      end
    end


    def each
      @map.each_with_index do |y,i|
        y.each_with_index do |x,j|
          yield x,[i,j]
        end
      end
    end

    attr_accessor :o, :x

    private

    def check_game_set
      won = nil
      a = 2.downto(0) {|i| self[-(i-2),i] }.uniq
      won = :x if a.size == 1 && a[0] == :x
      won = :o if a.size == 1 && a[0] == :o
      a = 2.downto(0) {|i| [i,i] }.uniq
      won = :x if a.size == 1 && a[0] == :x
      won = :o if a.size == 1 && a[0] == :o

    end
  end

  class Player
    def initialize(game)
    end

    def ask(map)
    end

    def on_game_set
    end
  end

  module Players
    class Human < TicTacToe::Player
    end

    class Robot < TicTacToe::Player
    end
  end
end
