albums = <<-EOF.lines.map(&:chomp).reject(&:empty?).inject([]) { |_, i| i.start_with?('  ') ? (_.last.last << i[2..-1].sub(/ ~.+ Ver\.~$/,''); _) : (_ + [[i, []]]) }.to_h
Signalize!/カレンダーガール [Single, Maxi]
  Signalize!
  カレンダーガール

Second Show! [Single, Maxi]
  Growing for a dream
  prism spiral
  Trap of Love

First Live! [Single, Maxi]
  アイドル活動!
  Move on now!
  Angel Snow

Third Action! [Single, Maxi]
  真夜中のスカイハイ
  Thrilling Dream
  硝子ドール

SHINING LINE*/Precious [Single, Maxi]
  SHINING LINE*
  Precious

TVアニメ/データカードダス アイカツ! ベストアルバム Calendar Girls
  Signalize!
  Move on now! ~美月ソロ Ver.~
  アイドル活動!
  Growing for a dream
  prism spiral
  Trap of Love ~蘭ソロ Ver.~
  放課後ポニーテール
  同じ地球のしあわせに
  硝子ドール ~ユリカソロ Ver.~
  Take Me Higher
  ヒラリ/ヒトリ/キラリ
  アリスブルーのキス (BONUS TRACK)
  ダイヤモンドハッピー
  真夜中のスカイハイ
  Thrilling Dream
  G線上のShining Sky
  右回りWonderland
  Angel Snow
  fashion check!
  Wake up my music ~いちご&りんご Ver.~
  Moonlight destiny
  アイドル活動! ~いちごソロ Ver.~
  カレンダーガール

Sexy Style [Single, Maxi]
  Kira・pata・shining
  マジカルタイム
  Dance in the rain

COOL MODE [Single, Maxi]
  アイドル活動! (Ver. Rock)
  新・チョコレート事件
  We wish you a merry Christmas (AIKATSU! Ver.)


KIRA☆Power/オリジナルスター☆彡 [Single, Maxi]
  KIRA☆Power
  オリジナルスター☆彡

FOURTH PARTY
  fashion check!
  Take Me Higher
  放課後ポニーテール
  G線上のShining Sky
  右回りWonderland
  同じ地球のしあわせに
  Wake up my music
  Moonlight destiny

ダイヤモンドハッピー/ヒラリ/ヒトリ/キラリ [Single, Maxi]
  ダイヤモンドハッピー
  ヒラリ/ヒトリ/キラリ
EOF

songs = albums.flat_map { |album, tracks| tracks.map { |track| [track, album] } } \
              .group_by(&:first) \
              .map{ |song, pair| [song, pair.map(&:last)] } \
              .to_h

albums.each do |name, tracks|
  contains_unique = nil
  lines = tracks.map do |track|
    mark = songs[track].size == 1 ? ' **' : ''
    contains_unique = '! ' unless mark.empty?
    "  #{track}#{mark}"
  end.join("\n")
  next unless contains_unique
  puts "#{name}\n#{lines}"
  puts
end
