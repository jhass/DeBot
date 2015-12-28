module IRC
  class Modes
    module Parser
      def self.parse(modes)
        parameters = modes.split(" ")
        modes      = seperate_flags parameters.shift? || ""

        parameters.reverse.each do |parameter|
          modifier, flag = modes.pop

          yield modifier, flag, parameter
        end

        modes.each do |mode|
          modifier, flag = mode

          yield modifier, flag, nil
        end
      end

      private def self.seperate_flags(modes)
        modifier = '+'
        separated = [] of {Char, Char}

        modes.chars.each do |flag|
          case flag
          when '+', '-'
            modifier = flag
          else
            separated << {modifier, flag}
          end
        end

        separated
      end
    end

    record Flag, flag, parameter

    include Enumerable(Flag)

    def initialize(modes="")
      @plain_flags         = Set(Flag).new
      @parameterized_flags = Set(Flag).new
      parse modes
    end

    def parse(modes)
      Parser.parse(modes) do |modifier, flag, parameter|
        if modifier == '+'
          set flag, parameter
        else
          unset flag, parameter
        end
      end
    end

    def get(flag : Char)
      @parameterized_flags.find {|item| item.flag == flag }.try(&.parameter)
    end

    def set(flag : Char, parameter=nil)
      mode = Flag.new(flag, parameter)

      if parameter
        @parameterized_flags << mode
      else
        @plain_flags << mode
      end
    end

    def unset(flag : Char, parameter=nil)
      mode = Flag.new(flag, parameter)

      if parameter
        @parameterized_flags.delete(mode)
      else
        @plain_flags.delete(mode)
      end
    end

    # pass false as parameter to look only at the flag but only in the
    # parameterized flags
    def set?(flag : Char, parameter=nil)
      mode = Flag.new(flag, parameter)

      if parameter
        @parameterized_flags.includes? mode
      elsif parameter == false
        @parameterized_flags.any? &.flag==(flag)
      else
        @plain_flags.includes? mode
      end
    end

    def each
      (@plain_flags | @parameterized_flags).each do |flag|
        yield flag
      end
    end

    def to_s(io)
      io << "+" if any?

      each do |flag|
        io << flag.flag
      end

      @parameterized_flags.each do |flag|
        io << " "
        io << flag.parameter
      end
    end
  end
end
