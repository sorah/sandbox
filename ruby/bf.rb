class BF
  def initialize(bf_code = nil)
    raise ArgumentError, "bf_code should a kind of String" unless    bf_code.kind_of?(String) 
                                                   || bf_code.nil?
    @code = bf_code || ""
    @parsed_code = []
  end 

  def <<(c)
    raise ArgumentError, "c should a kind of String" unless    c.kind_of?(String) 
                                             || c.nil?
    @code << c
  end

  def run(opt_by_client={})
    opts = {
           }.merge(opt_by_client)

    parse if @parsed_code.empty?
    @parsed_code.each do |c|
    end
  end

  private

  def parse
    @parsed_code = @code.chars.map do |t|
      case t
      when '+'
        :plus
      when '-'
        :minus
      when '<'
        :back
      when '>'
        :next
      when '['
        :start_loop
      when ']'
        :end_loop
      when '.'
        :put
      when ','
        :get
      end
    end
  end

  class Buffer < Array
    def [](i)
      if self[i].nil?
        self[i] = 0
      else
        super(i)
      end
    end

    def []=(i, x)
      if x.kind_of?(String)
        j = i
        x.chars.each do |c|
          self[j] = c.ord
          i += 1
        end
      elsif x.kind_of?(Integer)
        super(i, x)
      else
        raise ArgumentError, "Buffer can store Integer and String only."
      end
    end

  end
end
