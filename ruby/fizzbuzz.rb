puts (1..100).map{|i|s=(i%3==0?"Fizz":'')+(i%5==0?"Buzz":'');s==""?i:s}
