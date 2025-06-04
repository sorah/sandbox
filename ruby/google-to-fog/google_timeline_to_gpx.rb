#!/usr/bin/env ruby

require 'json'
require 'time'
require 'rexml/document'

class GoogleTimelineToGPX
  Waypoint = Data.define(:lat, :lon, :time, :name, :desc)
  TrackPoint = Data.define(:lat, :lon, :time, :name)
  Track = Data.define(:name, :points)
  def initialize(input_io = $stdin, output_io = $stdout)
    @input_io = input_io
    @output_io = output_io
    @tracks = []
    @waypoints = []
  end

  def convert
    parse_timeline_data
    filter_tracks
    generate_gpx
  end

  private

  # Calculate distance between two points using Haversine formula (returns meters)
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

  # Filter tracks to remove noise and split at large jumps
  def filter_tracks
    filtered_tracks = []

    @tracks.each do |track|
      # First, remove noise points
      cleaned_points = remove_noise_points(track.points)
      
      # Then split at large jumps
      segments = split_at_jumps(cleaned_points)
      
      # Create new tracks from valid segments
      segments.each_with_index do |segment, idx|
        next if segment.length < 2
        
        filtered_tracks << Track.new(
          name: "#{track.name} (#{idx + 1})",
          points: segment
        )
      end
    end

    @tracks = filtered_tracks
  end

  # Remove points that jump away and back (noise)
  def remove_noise_points(points)
    return points if points.length < 3

    cleaned = [points[0]]
    
    (1...points.length - 1).each do |i|
      prev_point = cleaned.last
      curr_point = points[i]
      next_point = points[i + 1]
      
      # Calculate distances
      dist_to_curr = haversine_distance(
        prev_point.lat, prev_point.lon,
        curr_point.lat, curr_point.lon
      )
      dist_to_next = haversine_distance(
        prev_point.lat, prev_point.lon,
        next_point.lat, next_point.lon
      )
      dist_curr_to_next = haversine_distance(
        curr_point.lat, curr_point.lon,
        next_point.lat, next_point.lon
      )
      
      # If current point jumps > 100m from previous
      # AND next point is closer to previous than current is
      # Then current point is likely noise
      if dist_to_curr > 100 && dist_to_next < dist_to_curr
        # Skip this point (noise)
        next
      end
      
      cleaned << curr_point
    end
    
    cleaned << points.last
    cleaned
  end

  # Split track at jumps larger than 1km
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
        # Start new segment
        segments << current_segment if current_segment.length >= 2
        current_segment = [curr_point]
      else
        current_segment << curr_point
      end
    end
    
    segments << current_segment if current_segment.length >= 2
    segments
  end

  def parse_timeline_data
    @input_io.each_line do |line|
      next if line.strip.empty?

      begin
        data = JSON.parse(line)
        process_entry(data)
      rescue JSON::ParserError => e
        warn "Failed to parse line: #{e.message}"
      end
    end
  end

  def process_entry(data)
    case
    when data.key?('activity')
      process_activity(data)
    when data.key?('visit')
      process_visit(data)
    when data.key?('timelinePath')
      process_timeline_path(data)
    when data.key?('timelineMemory')
      # Skip timelineMemory entries as they don't contain location data
    end
  end

  def process_activity(data)
    activity = data.fetch('activity')
    start_time = parse_time(data.fetch('startTime'))
    end_time = parse_time(data.fetch('endTime'))

    # Extract coordinates from geo: format
    start_coords = parse_geo_coords(activity.fetch('start'))
    end_coords = parse_geo_coords(activity.fetch('end'))

    return unless start_coords && end_coords

    # Create a track segment with start and end points
    track_points = [
      TrackPoint.new(
        lat: start_coords[:lat],
        lon: start_coords[:lon],
        time: start_time,
        name: "Start: #{activity.dig('topCandidate', 'type') || 'Unknown'}"
      ),
      TrackPoint.new(
        lat: end_coords[:lat],
        lon: end_coords[:lon],
        time: end_time,
        name: "End: #{activity.dig('topCandidate', 'type') || 'Unknown'}"
      )
    ]

    @tracks << Track.new(
      name: "#{activity.dig('topCandidate', 'type') || 'Activity'} - #{start_time}",
      points: track_points
    )
  end

  def process_visit(data)
    visit = data.fetch('visit')
    location = visit.dig('topCandidate', 'placeLocation')

    return unless location

    coords = parse_geo_coords(location)
    return unless coords

    @waypoints << Waypoint.new(
      lat: coords[:lat],
      lon: coords[:lon],
      time: parse_time(data.fetch('startTime')),
      name: visit.dig('topCandidate', 'semanticType') || 'Visit',
      desc: "Place ID: #{visit.dig('topCandidate', 'placeID')}"
    )
  end

  def process_timeline_path(data)
    path_points = data.fetch('timelinePath')
    return unless path_points && path_points.is_a?(Array)

    start_time = parse_time(data.fetch('startTime'))
    track_points = []

    path_points.each do |point|
      coords = parse_geo_coords(point.fetch('point'))
      next unless coords

      # Calculate time for this point based on offset
      offset_minutes = point.fetch('durationMinutesOffsetFromStartTime').to_f
      point_time = start_time + (offset_minutes * 60)

      track_points << TrackPoint.new(
        lat: coords[:lat],
        lon: coords[:lon],
        time: point_time,
        name: nil
      )
    end

    unless track_points.empty?
      @tracks << Track.new(
        name: "Path - #{start_time}",
        points: track_points
      )
    end
  end

  def parse_geo_coords(geo_string)
    return nil unless geo_string && geo_string.start_with?('geo:')

    coords = geo_string.sub('geo:', '').split(',')
    return nil unless coords.length == 2

    {
      lat: coords[0].to_f,
      lon: coords[1].to_f
    }
  end

  def parse_time(time_string)
    Time.parse(time_string) rescue Time.now
  end

  def generate_gpx
    doc = REXML::Document.new
    doc.add_element('gpx', {
      'version' => '1.1',
      'creator' => 'Google Timeline to GPX Converter',
      'xmlns' => 'http://www.topografix.com/GPX/1/1',
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      'xsi:schemaLocation' => 'http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd'
    })

    gpx = doc.root

    # Add waypoints
    @waypoints.each do |waypoint|
      wpt = gpx.add_element('wpt', {
        'lat' => waypoint.lat.to_s,
        'lon' => waypoint.lon.to_s
      })
      wpt.add_element('time').text = waypoint.time.iso8601 if waypoint.time
      wpt.add_element('name').text = waypoint.name if waypoint.name
      wpt.add_element('desc').text = waypoint.desc if waypoint.desc
    end
    
    # Add tracks
    unless @tracks.empty?
      trk = gpx.add_element('trk')
      trk.add_element('name').text = 'Google Timeline Track'

      # Sort tracks by time and merge into segments
      @tracks.sort_by { |t| t.points.first.time || Time.now }.each do |track|
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

    # Write to output stream
    doc.write(@output_io, 2)
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.length == 0
    # Read from stdin, write to stdout
    converter = GoogleTimelineToGPX.new($stdin, $stdout)
    converter.convert
  elsif ARGV.length == 2
    # Read from file, write to file
    input_file = ARGV[0]
    output_file = ARGV[1]

    unless File.exist?(input_file)
      $stderr.puts "Error: Input file '#{input_file}' not found"
      exit 1
    end

    File.open(input_file, 'r') do |input|
      File.open(output_file, 'w') do |output|
        converter = GoogleTimelineToGPX.new(input, output)
        converter.convert
      end
    end

    $stderr.puts "Conversion complete! GPX file saved to: #{output_file}"
  else
    $stderr.puts "Usage: #{$0} [<input.jsonl> <output.gpx>]"
    $stderr.puts "       jq -c .[] < input.jsonl | #{$0} > output.gpx"
    exit 1
  end
end
