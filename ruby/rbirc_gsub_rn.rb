class Object
  def p_cont
    p self
    self
  end
end

def a(s)
  s.gsub(/$/,"\r\n").p_cont.gsub(/\r+\n+\r\n$/,"\r\n").p_cont
end

p a("") == "\r\n"
p a("\r\n") == "\r\n"
p a("\n") == "\r\n"

#"\r\r\n\n\r\n"
#"\r\n\n\r\n"
#\r+\n+\r\n
