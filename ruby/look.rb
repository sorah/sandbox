class LookupDictionary
  def initialize(words)
    @words = words.to_ary
    @dictionary = {}
    update
  end

  def update
    @dictionary = {}
    @words.each do |word|
      search(word)[:word] = true
    end
  end

  def add(word)
    @words << word
    @words.uniq!
    update
  end

  def look(str)
    dic = search(str)
    result = []
    result << str if dic[:word]
    dic[:down].each do |name,down|
      result << look(str+name)
    end
    result.flatten
  end

  alias << add

  private

  def search(str)
    str.chars.inject(0) do |result, char|
      if result == 0
        @dictionary[char] ||= {word: false, down: {}}
      else
        result[:down][char] ||= {word: false, down: {}}
      end
    end
  end
end

dic = LookingDictionary.new(["a","abc","abcd"])

p dic.look("a")
p dic.look("ab")
p dic.look("abcd")
