require 'gyazo'
require 'net/http'

gyazo_url = `pbpaste`
gyazo_id = nil
if gyazo_url =~ /gyazo.com\/([a-f0-9]{32})$/
  gyazo_id = $1
else
  STDERR.puts "クリップボードにGyazoのURLがありません"
  exit
end

# STDERR.puts "GyazoのURLは#{gyazo_url}"

def url_exist?(uri)
  begin
    url = URI.parse(uri)
    req = Net::HTTP.new(url.host, url.port)
    req.use_ssl = true if url.scheme == 'https'
    res = req.request_head(url.path)
    return URI(res['location']).exists? if %w(301 302).include?(res.code)
    return res.code == '200'
  rescue
    return false
  end
end

jpg = "#{gyazo_url}.jpg"
png = "#{gyazo_url}.png"

system "/bin/rm -f /tmp/map.jpg /tmp/map.png"

if url_exist?(jpg)
  puts "try jpg"
  puts jpg
  system "wget -O /tmp/map.jpg #{jpg}"
# elsif url_exist?(png)
else
  puts "try png"
  puts png
  system "wget -O /tmp/map.png #{png}"
  system "convert /tmp/map.png /tmp/map.jpg"
end

gyazo = Gyazo::Client.new(:access_token => ENV['GYAZO_TOKEN'])

gyazodata = gyazo.image image_id: gyazo_id

mapurl = gyazodata[:metadata][:url]

puts mapurl
match = (mapurl =~ /google.com.*maps\/@((\d+\.\d+)),((\d+\.\d+)),/)
unless match
  STDERR.puts "緯度経度が定義されていません"
  exit
end
lat = $1
long = $3

system "exiftool -all= /tmp/map.jpg"
system "exiftool -TagsFromFile template.jpg -all:all /tmp/map.jpg"
system "exiftool -GPSLatitude=#{lat} -GPSLongitude=#{long} /tmp/map.jpg"

gyazo.upload imagefile: "/tmp/map.jpg"

res = gyazo.upload imagefile: "/tmp/map.jpg"

sleep 1
url = res[:permalink_url]

system "open #{url}"
