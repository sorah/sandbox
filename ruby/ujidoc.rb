module UjiDoc
  def method_missing(name, *args)
    if args[0].kind_of?(Sentence)
      Sentence[name.to_s, args.to_s]
    else
      Sentence[name.to_s]
    end
  end
  class Sentence < Array
    def to_s
      self.join(' ')
    end
#    def inspect
#      to_s
#    end
  end
end

include UjiDoc

p ujihisa termtter
