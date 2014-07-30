require 'net/http'
require 'json'
require 'base64'

def call_api(url)
  json = Net::HTTP.get(URI(url))
  decoded = JSON.parse(json)
  return decoded
end

# Get google coordinates about an address.
def get_google_coordinate(address)
  url = 'http://maps.googleapis.com/maps/api/geocode/json?sensor=false&language=zh-CN&address=' + URI::encode(address)
  decoded = call_api(url)

  if decoded['status'] == 'OK' then
    ret = decoded['results'][0]['geometry']['location']
  else
    ret = {}
  end

  return ret
end

# Transfer google coordinates to baidu coordinates.
def convert_google_to_baidu(lng, lat)
  url = 'http://api.map.baidu.com/ag/coord/convert?from=2&to=4&x=' + lng.to_s + '&y=' + lat.to_s
  decoded = call_api(url)
  ret = {}

  if decoded['error'] == 0 then
    ret['lng'] = Base64.decode64(decoded['x'])
    ret['lat'] = Base64.decode64(decoded['y'])
  end

  return ret
end

# Get baidu coordinates.
def get_baidu_coordinates(address, ak, city_name)
  url = 'http://api.map.baidu.com/geocoder?address=' + URI::encode(address) 
  url += '&output=json&key=' + URI::encode(ak) + '&city=' + URI::encode(city_name)
  decoded = call_api(url)
  ret = {}
  p decoded

  if decoded['status'] == 'OK' && decoded['result'].include?('location') then
    ret['lng'] = decoded['result']['location']['lng']
    ret['lat'] = decoded['result']['location']['lat']
  end

  return ret
end