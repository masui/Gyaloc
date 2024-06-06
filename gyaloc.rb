require 'gyazo'

gyazo_url = `pbpaste`
gyazo_id = nil
if gyazo_url =~ /gyazo.com\/([a-f0-9]{32})$/
  gyazo_id = $1
else
  STDERR.puts "クリップボードにGyazoのURLがありません"
  exit
end

STDERR.puts "GyazoのURLは#{gyazo_url}"

system "/bin/rm -f /tmp/__raw /tmp/__map.jpg /tmp/__map.png"

# rawデータを取得
system "wget -O /tmp/__raw https://gyazo.com/#{gyazo_id}/raw"

# JPEGかPNGなのでJPEGに変換
if `file /tmp/__raw`.match(/PNG image data/)
  system "/bin/mv /tmp/__raw /tmp/__map.png"
  system "/usr/local/bin/convert /tmp/__map.png /tmp/__map.jpg"
else
  system "/bin/mv /tmp/__raw /tmp/__map.jpg"
end

gyazo = Gyazo::Client.new(:access_token => ENV['GYAZO_TOKEN'])

gyazodata = gyazo.image image_id: gyazo_id

mapurl = gyazodata[:metadata][:url]

match = (mapurl =~ /google.com.*maps.*\/@((\d+\.\d+)),((\d+\.\d+)),/)
unless match
  STDERR.puts "緯度経度が定義されていません"
  exit
end
lat = $1
long = $3

# テンプレート写真ファイルを取得
system "wget https://s3-ap-northeast-1.amazonaws.com/masui.org/1/b/1b7b5977b1ee7e3fb73c495332f70547.jpg -O /tmp/template.jpg"

system "exiftool -all= /tmp/__map.jpg"
system "exiftool -TagsFromFile /tmp/template.jpg -all:all /tmp/__map.jpg"
system "exiftool -GPSLatitude=#{lat} -GPSLongitude=#{long} /tmp/__map.jpg"

res = gyazo.upload imagefile: "/tmp/__map.jpg"

sleep 1
url = res[:permalink_url]

system "open #{url}"
