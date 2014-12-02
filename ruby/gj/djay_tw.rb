p :hi
#require 'twitter'
require 'json'
require 'uri'
require 'net/http'
p :ok

ENDPOINT = URI.parse 'http://gj.kosendj-bu.in/gifs'

def send_gifs(gifs, immediate: false)
  return unless gifs
  return if gifs.empty?

  urls = gifs.map do |f|
    "http://sorah-gif:8080/" + File.basename(f.chomp)
  end

  puts(immediate ? "IMMEDIATE SEND:" : "SEND:")
  puts urls
  Net::HTTP.start(ENDPOINT.host, ENDPOINT.port) do |http|
    r = Net::HTTP::Post.new(ENDPOINT.path)
    r['Content-Type'] = 'application/x-www-form-urlencoded'
    payload = "dj=#{immediate ? 'true' : 'false'}"
    payload << (urls.map do |x|
      "&urls[]=#{URI.encode_www_form_component(x)}"

    end.join)
    puts payload
    r.body = payload
    res = http.request(r)
    p res
  end
end

prefix = ARGV[0] || '#kosendj'
prefix << ' ' unless prefix.empty?
#tw = Twitter::REST::Client.new(
#  consumer_key: ENV['TWITTER_CONSUMER_KEY'],
#  consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
#  access_token: ENV['TWITTER_ACCESS_TOKEN'],
#  access_token_secret: ENV['TWITTER_ACCESS_TOKEN_SECRET'],
#)
path = File.expand_path('~/Music/djay/NowPlaying.txt')

dic = {
  'メッセージ' => {comment: '',
  gifs: %w(
imascga-pv-1-2.gif
imascga-pv-2-1.gif
imascga-pv-2-2.gif
imascga-pv-4-1.gif
imascga-pv-4-2.gif
imascga-pv-5-2.gif
imascga-pv-6-1.gif
imascga-pv-6-2.gif
imascga-pv-7-1.gif
imascga-pv-7-2.gif
  )},

  'Kiss(and)' => {comment: '',
  gifs:%w(
73127187321_fa1951a7bf9cbdbe7aa3afcadf7e19eae0ac6570a6f6a05e64ca3cd0423e7034.gif
73128304020_c4342e90095362b4cf97f13b4cdd9e019cf5f08d0ee54e199ead87ed844fffac.gif
73629166165_4bd3b5e83f9121895a45f48c2392370a4d372c259981c3ea5ca21e2ba76100f3.gif
73947465426_9f5b8893c54f0969b109526d9deccb29cc23f878ac47b7426e837a253ffdc6bf.gif
74387024802_7a288019a4048c3e0e15e7f12108fb4cd829dd5a5ddc485156431aa3837fad91.gif
74387024802_9af3e55e1af1029e4cbf0eb5198424e1ea1dca82c1fb7729b9755a3b520a0ad9.gif
74387024802_59a8d4e73334b2bc6003f3504c513b514a8812f6264e3f9cca62997f56df1755.gif
74387024802_82e35c58d5204978d2f8a3b2211f314193f546503c34cb6710c325d76b4fce85.gif
74387024802_c6ab37d0d9d041868e86088ba75fb7f35e632ce9c9dba735d97474c3742bce05.gif
)
  },

  '花ハ' => {comment: '',
  gifs:%w(
91048973077_01343d8571ab18edc06462c395e9c92b803216a08c1db0b9bcce12125264e27a.gif
91586420237_4673d97ea67e201886e996bb2a4c338b430f9a24d778e1da9947a9a08fa504c3.gif
91865533142_0d5eed074465ac945dec4b0588586f8a651ab84de97c1f49cf863b8985e35453.gif
91865533142_70f156067e89b9bd46787ac2bfd0a5d2d4f83559c792c579ef412439bcf12f71.gif
91865533142_410dbf0bb5d83365ffd4a48fb9cde6cabc55614f1aec8d0a0929a3e17a6bf9d6.gif
91865533142_a091bd27de4b53e18038383287c03cab2514cc157bc390a16028a6f1fabda58a.gif
91865533142_f664c94924ee935a06042a6e796f17202ce199628ca40ff68757115316054625.gif
  )
  },

  'Prism Sympathy' => {comment: '[Fate/Kaleid liner プリズマ☆イリヤ ED]',
  gifs: %w(
91866873047_49d6faab488d5c9c2627d7041060974072365920d5060ddfa8fd6f9cabc8b787.gif
59883241062_59c1e931eb9dfe1c1dfcf43997ba2477a091c7597e495064178132b241aebc12.gif
59721691948_bc8c1d5cce228c2a12946cbc084231002e996ed3620f17a8ab3ea3e7287e6013.gif
58158333852_ed4d9e842e33291db06e2420046ea4e6ec6f7cb8bdbf6613d56285f69ef9be8f.gif
91579721802_4c487bb23169bfe5e4410646b9afa1610d9ab91683d22b57bf5a57de63889d6b.gif
93050044177_999fc8741e2fbb1373b4731d27314dcfcd9e8ee1cbc04ed31ce16ed2ccab4882.gif
95094399507_c8699d71b10732742e5bfe12e4c6a4a68cff7b8c0deb1ca6804defc2e1aebf9c.gif
58957025279_2c48a2098bd4a4593036c6ec960e377df0334b83aa986386fd17e7176e61661c.gif
80889343949_edfdcfa96d4d81719ab6224a2c8b9967ad8fb6e3ff3d44219628b66782642a03.gif
  ), immediate: %w(80889343949_edfdcfa96d4d81719ab6224a2c8b9967ad8fb6e3ff3d44219628b66782642a03.gif#10000)},

  '回レ!雪月花' => {comment: '[機巧少女は傷つかないED]',
  gifs: %w(
tumblr_n1ma3jbPZz1scr8d9o1_500.gif
tumblr_n1ma3jbPZz1scr8d9o2_500.gif
tumblr_n1ma3jbPZz1scr8d9o3_500.gif
tumblr_n1ma3jbPZz1scr8d9o4_500.gif
tumblr_n1ma3jbPZz1scr8d9o5_500.gif
tumblr_n1ma3jbPZz1scr8d9o6_500.gif
tumblr_n1ma3jbPZz1scr8d9o7_500.gif
tumblr_n1ma3jbPZz1scr8d9o8_500.gif
  )},

  '季節のシャッター' => {comment: '[あの夏で待ってる 特別編]',
  gifs: %w(
tumblr_lybdqohSpE1qbyxr0o1_500.gif
tumblr_lz63fn0SmE1qmzn3po1_500.gif
tumblr_mys6akFjWG1rjwa86o1_500.gif
  ), immediate: %w(tumblr_mys6akFjWG1rjwa86o1_500.gif#10000)},

  'Next Life' => {comment: '[THE IDOLM@STER]',
  gifs: %w(
68001584737_6af1105c41637d88c3e92da2e29b99bb0394a2bf7bb56cbc020375646bf5a373.gif
58063597045_0d7519d53e2889d28092b5dde337f96137018b40f134cec840f3a162807e78c8.gif
m_cm_live_hibiki.gif
ready_16_hibiki.gif
theidolmaster.gif
jibunrestart3_clap.gif
ready_15_jump.gif
  ), immediate: %w(68001584737_6af1105c41637d88c3e92da2e29b99bb0394a2bf7bb56cbc020375646bf5a373.gif)},

  'ロイヤルストレートフラッシュ' => {comment: '[THE IDOLM@STER ぷちます!]',
  gifs: %w(
theidolmaster.gif
47113501831_12897f8271d319119a4d8ead373efd759e5fac938aebc7058d2ec4f3f96b4f87.gif
62065531618_1dad17d3985c472b6729b67373c0554e9e928fd22f7ed500ea5695e4aa1a69af.gif
100539592347_e5d25b7eb8ecb28c45d49cfe999668990e468fc99c01c6bed90d30f36466006c.gif
87517292562_bc467baa7144212a892464e26dcb71e30470eab163b482eb4ede4f97dd7082dc.gif
iori.gif
ready_14_iori_mami.gif
jibunrestart3_clap.gif
m_cm_live_mami.gif
ppph.gif
  ), immediate: %w(47113501831_12897f8271d319119a4d8ead373efd759e5fac938aebc7058d2ec4f3f96b4f87.gif#10000)},

  'ブルー・フィール' => {comment: '[蒼き鋼のアルペジオ -アルス・ノヴァ- ED]',
  gifs: %w(
tumblr_myemqigZJ11sawtkmo1_400.gif
tumblr_n7s0swkqpW1qbnl0co1_500.gif
tumblr_n75j035xLH1qbnl0co1_500.gif
  ), immediate: %w(tumblr_n7s0swkqpW1qbnl0co1_500.gif#5000)},

  '労働歌' => {comment: '[フリーダムウォーズ]',
  gifs: %w(
tumblr_mn5i5k23UW1qzp9weo1_400.gif
tumblr_mn5i5k23UW1qzp9weo2_400.gif
tumblr_mn5i5k23UW1qzp9weo5_400.gif
tumblr_mn5i5k23UW1qzp9weo6_400.gif
ppr1.gif
ppr2.gif
  ), immediate: %w(ppr1.gif#10000)},

  'STAR RISE' => {comment: '[バンブーブレード ED]',
  gifs: %w(
anko.gif
bb1.gif
bbop1.gif
bbop2.gif
  ), immediate: %w(anko.gif#10000)},

  '胸キュン' => {comment: '[まりあ†ほりっく ED1, カバー]',
  gifs: %w(
tumblr_m8tuquLqGf1r922azo1_r1_500.gif
tumblr_maewlpMHLI1rggqwfo1_500.gif
tumblr_mafcu4Zf6J1r922azo1_500.gif
tumblr_ml2kl3aUyj1s78savo1_500.gif
tumblr_mublhpFXHH1rjf4f5o2_500.gif
tumblr_mublhpFXHH1rjf4f5o3_500.gif
tumblr_n31kk1l0KS1rjwa86o1_400.gif
  ), immediate: %w(tumblr_n31kk1l0KS1rjwa86o1_400.gif#5000)},

  '絶対love' => {comment: '[絶対可憐チルドレン ED]',
  gifs: %w(
tumblr_mlemg0kWzw1rynebso1_500.gif
tumblr_n04lbuLroO1s4qvrdo1_500.gif
  ), immediate: %w(tumblr_mlemg0kWzw1rynebso1_500.gif#15000)},

  '四角い宇宙' => {comment: '[咲-Saki- ED]',
  gifs: %w(
26484633826_60b8a2dc9c67418ef40ffc238d43c56ca2c7529681fe954832562344edf37271.gif
47360160279_8a8764c554ce856cec6d698f4d0452d079cbf99b4a099b02bde2fabd8bce714a.gif
53838291072_9a4f8e40f766d08cbc40b14b871deb9d94fe304d5254897abff5ef69deb3822a.gif
72567540732_42256d2c2c937d5ba5b52eea9e5c19b8403477d04ba8e31a75873efc70b76a84.gif
74065955432_ace56c9e134ee2bf4d0ca2bede1054f0ba964ce8d4442dde7590970c8c380b8c.gif
77706976548_270116c3b089e2a9b52de2e7d9313b7e95e4d9a8f89e3d0707fc5e5d639b9fa8.gif
sakied1.gif
sakied2.gif
  ), immediate: %w(sakied1.gif#15000)},

  'マテリアル' => {comment: '[ネギま! OP]',
  gifs: %w(
tumblr_msa7jzF75B1rynebso1_250.gif
tumblr_msa7jzF75B1rynebso6_250.gif
tumblr_msa7jzF75B1rynebso7_250.gif
tumblr_msa7jzF75B1rynebso8_250.gif
tumblr_msa7jzF75B1rynebso9_250.gif
tumblr_msa7jzF75B1rynebso10_250.gif
tumblr_m7ovr9ktZy1rynebso1_500.gif
tumblr_m7s697NfDc1rynebso1_500.gif
tumblr_mediw18Zm11rynebso1_500.gif
tumblr_mrfrqxK8dA1rw47iyo2_500.gif
  ), immediate: %w(tumblr_msa7jzF75B1rynebso3_250.gif#6000)},

  'Wonderful Wonder World' => {comment: '[ログ・ホライズン ED]',
  gifs: %w(
lh-wonderful1.gif
lh-wonderful2.gif
tumblr_inline_ncequeGZm11rlhjoh.gif
tumblr_n1rg0sP4lB1sft3xeo1_500.gif
tumblr_n3dymfNQmr1qfbz1so2_500.gif
tumblr_mw0n1cGaMW1qgnzw0o1_500.gif
tumblr_mw0n1cGaMW1qgnzw0o2_500.gif
tumblr_mw0n1cGaMW1qgnzw0o3_500.gif
tumblr_mxgj8wxz9I1r0wlweo1_500.gif
tumblr_nbtt1cBism1r3rdh2o1_500.gif
  ), immediate: %w(tumblr_n3dymfNQmr1qfbz1so2_500.gif#6000)},

  'カレンダーガール' => {comment: '[アイカツ! ED]',
  gifs: %w(
54371850284_215bbeca272214baa4f3e75a03b0330c0fea4348b120bcd1ffef3296fb9f6b55.gif
89581293822_16a70b86f7db7bebb0fd65f506213c855c0b0b8b09c682e999de2f48bec68ab4.gif
89581293822_509d9679b15c59340555654a42703941b1ed1a031c43dfc5645f50316d45dc2e.gif
89581293822_e63260be693ed13669ed8a4f4c1bda907ace19876b9e5aeea9cc4058666a0674.gif
89588138542_f4364e9b3acb4398dbc789a98063e3cdc2b5c1b47aeb5bf0c1d98cce75cd0a2c.gif
91581041662_41a03f7fa5e4a0ce85f9a1755d13a26d13b608b9e369abb636029ca7ebc1983d.gif
91581041662_9924eac8563f73f2fb494506cf60bf8a8b130127a59cee9e2a472bb37ff3f370.gif
91581450587_a57eea85cc5d8509f19a713af6c5a4a6ee183e2e569e056c34968d9c3992a8f0.gif
  ), immediate: %w(91581041662_9924eac8563f73f2fb494506cf60bf8a8b130127a59cee9e2a472bb37ff3f370.gif#10000)},
}

index = 0
prev = nil
pret = nil
count = 0
tweet = false
gif_sent = false
t = nil
loop do
  count += 1

  now = File.read(path).each_line.map { |_| _.chomp.split(/: /,2) }.to_h
  if now != prev
    index += 1
    tweet = false
    gif_sent = false
    count = 0
    prev = now
    pret = t
    t = Time.now
  end

  if now
    puts "#{t.to_s}: #{index}. #{now['Title']} (#{t-(pret || Time.now)}) (#{count})"
  end

  attr = dic.find { |k,v| now['Title'].include?(k) }
  attr = attr && attr[1]
  if attr
    comment = attr[:comment]
    gifs = attr[:gifs] || []
  else
    comment = nil
    gifs = []
  end

  text = "#{prefix}DJing: #{now['Title']} (#{now['Artist']}) #{comment}"
  if text.size > 135
    text = "#{prefix}DJing: #{now['Title']} #{comment}"
  end
  if (index > 1) && (count >= 2) && !gif_sent
    gif_sent = true
    send_gifs gifs
  end
  if (index > 1) && (count >= 6) && !tweet
    tweet = true
    #tw.update(text)
    puts "UPDATE: #{text}"
    if attr && attr[:immediate]
      send_gifs attr[:immediate], immediate: true
    end
  end

  sleep 1
end
