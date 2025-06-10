require 'rexml/document'

module GPXUtils
  Waypoint = Data.define(:lat, :lon, :time, :name, :desc)
  TrackPoint = Data.define(:lat, :lon, :time, :name)
  Track = Data.define(:name, :points)

  module_function

  def haversine_distance(lat1, lon1, lat2, lon2)
    r = 6371000 # Earth's radius in meters
    phi1 = lat1 * Math::PI / 180
    phi2 = lat2 * Math::PI / 180
    delta_phi = (lat2 - lat1) * Math::PI / 180
    delta_lambda = (lon2 - lon1) * Math::PI / 180

    a = Math.sin(delta_phi / 2) * Math.sin(delta_phi / 2) +
        Math.cos(phi1) * Math.cos(phi2) *
        Math.sin(delta_lambda / 2) * Math.sin(delta_lambda / 2)
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    r * c
  end

  def filter_tracks(tracks)
    filtered_tracks = []

    tracks.each do |track|
      cleaned_points = remove_noise_points(track.points)
      segments = split_at_jumps(cleaned_points)
      
      segments.each_with_index do |segment, idx|
        next if segment.length < 2
        
        filtered_tracks << Track.new(
          name: "#{track.name} (#{idx + 1})",
          points: segment
        )
      end
    end

    filtered_tracks
  end

  def remove_noise_points(points)
    return points if points.length < 3

    cleaned = [points[0]]
    
    (1...points.length - 1).each do |i|
      prev_point = cleaned.last
      curr_point = points[i]
      next_point = points[i + 1]
      
      dist_to_curr = haversine_distance(
        prev_point.lat, prev_point.lon,
        curr_point.lat, curr_point.lon
      )
      dist_to_next = haversine_distance(
        prev_point.lat, prev_point.lon,
        next_point.lat, next_point.lon
      )
      
      if dist_to_curr > 100 && dist_to_next < dist_to_curr
        next
      end
      
      cleaned << curr_point
    end
    
    cleaned << points.last
    cleaned
  end

  def split_at_jumps(points)
    return [points] if points.length < 2

    segments = []
    current_segment = [points[0]]
    
    (1...points.length).each do |i|
      prev_point = points[i - 1]
      curr_point = points[i]
      
      distance = haversine_distance(
        prev_point.lat, prev_point.lon,
        curr_point.lat, curr_point.lon
      )
      
      if distance > 1000 # 1km
        segments << current_segment if current_segment.length >= 2
        current_segment = [curr_point]
      else
        current_segment << curr_point
      end
    end
    
    segments << current_segment if current_segment.length >= 2
    segments
  end

  def generate_gpx(tracks:, waypoints: [], creator: 'GPX Converter', track_name: 'Track', output_io: $stdout)
    doc = REXML::Document.new
    doc.add_element('gpx', {
      'version' => '1.1',
      'creator' => creator,
      'xmlns' => 'http://www.topografix.com/GPX/1/1',
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      'xsi:schemaLocation' => 'http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd'
    })

    gpx = doc.root

    waypoints.each do |waypoint|
      wpt = gpx.add_element('wpt', {
        'lat' => waypoint.lat.to_s,
        'lon' => waypoint.lon.to_s
      })
      wpt.add_element('time').text = waypoint.time.iso8601 if waypoint.time
      wpt.add_element('name').text = waypoint.name if waypoint.name
      wpt.add_element('desc').text = waypoint.desc if waypoint.desc
    end
    
    unless tracks.empty?
      trk = gpx.add_element('trk')
      trk.add_element('name').text = track_name

      tracks.sort_by { |t| t.points.first.time || Time.now }.each do |track|
        trkseg = trk.add_element('trkseg')

        track.points.each do |point|
          trkpt = trkseg.add_element('trkpt', {
            'lat' => point.lat.to_s,
            'lon' => point.lon.to_s
          })
          trkpt.add_element('time').text = point.time.iso8601 if point.time
          trkpt.add_element('name').text = point.name if point.name
        end
      end
    end

    doc.write(output_io, 2)
  end
end