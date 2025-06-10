#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'ruby-vips'
  gem 'minitar'
end

require 'json'
require 'time'
require 'zlib'
require 'minitar'
require 'vips'

class GooglePhotosExifToJsonl
  GeoTag = Data.define(:lat, :lon, :time, :filename, :tarball, :altitude, :timezone_offset, :timezone_source, :file_size)
  ErrorLog = Data.define(:type, :filename, :tarball, :error, :details, :exif_data, :file_size)
  
  def initialize(output_io = $stdout)
    @output_io = output_io
    @processed_count = 0
    @geotag_count = 0
  end

  def process_tarballs(paths)
    paths.each do |path|
      if File.directory?(path)
        process_directory(path)
      else
        process_tarball(path)
      end
    end
    
    $stderr.puts "Processed #{@processed_count} files, found #{@geotag_count} geotags"
  end

  private

  def format_bytes(bytes)
    return "0 B" if bytes == 0
    
    units = ['B', 'KB', 'MB', 'GB', 'TB']
    exp = (Math.log(bytes) / Math.log(1024)).floor
    exp = [exp, units.length - 1].min
    
    "%.1f %s" % [bytes.to_f / (1024 ** exp), units[exp]]
  end

  def process_tarball(tarball_path)
    file_size = File.size(tarball_path)
    $stderr.puts "Processing: #{tarball_path} (#{format_bytes(file_size)})"
    
    File.open(tarball_path, 'rb') do |file|
      reader = case tarball_path
      when /\.tar\.gz$/, /\.tgz$/
        Zlib::GzipReader.new(file)
      when /\.tar$/
        file
      else
        raise "Unsupported file format: #{tarball_path}"
      end
      
      Minitar::Reader.open(reader) do |tar|
        tar.each do |entry|
          next unless entry.file?
          
          # Show progress for compressed files
          if tarball_path.match(/\.tar\.gz$|\.tgz$/)
            begin
              current_pos = file.pos
              progress_pct = (current_pos.to_f / file_size * 100).round(1)
              $stderr.print "\rProgress: #{progress_pct}% (#{format_bytes(current_pos)}/#{format_bytes(file_size)}) - #{File.basename(entry.full_name)}#{' ' * 20}"
            rescue
              # Some IO objects don't support pos, continue without progress
            end
          end
          
          process_tar_entry(entry, tarball_path, file_size, file)
        end
      end
      
      $stderr.puts "\nCompleted: #{tarball_path}"
    end
  rescue => e
    $stderr.puts "Error processing #{tarball_path}: #{e.message}"
    raise
  end

  def process_directory(dir_path)
    dir_basename = File.basename(dir_path)
    $stderr.puts "Processing directory: #{dir_path}"
    
    # Recursively find all image files
    image_files = Dir.glob(File.join(dir_path, '**', '*')).select do |path|
      File.file?(path) && image_file?(path)
    end
    
    total_files = image_files.length
    $stderr.puts "Found #{total_files} image files"
    
    image_files.each_with_index do |file_path, index|
      # Show progress
      if index % 10 == 0 || index == total_files - 1
        progress_pct = ((index + 1).to_f / total_files * 100).round(1)
        $stderr.print "\rProgress: #{progress_pct}% (#{index + 1}/#{total_files}) - #{File.basename(file_path)}#{' ' * 20}"
      end
      
      process_file(file_path, dir_basename)
    end
    
    $stderr.puts "\nCompleted: #{dir_path}"
  rescue => e
    $stderr.puts "Error processing directory #{dir_path}: #{e.message}"
    raise
  end

  def process_file(file_path, source_name)
    @processed_count += 1
    $stderr.puts "Processing #{file_path}..." if ENV['DEBUG']
    
    # Read file content
    content = File.binread(file_path)
    file_size = content.bytesize
    
    # Process with vips
    begin
      geotag = extract_geotag_from_memory(content, file_path, source_name, file_size)
      if geotag
        @geotag_count += 1
        @output_io.puts geotag.to_h.to_json
        @output_io.flush
      end
    rescue => e
      error_log = ErrorLog.new(
        type: 'error',
        filename: file_path,
        tarball: source_name,
        error: e.class.name,
        details: e.message,
        exif_data: nil,
        file_size: file_size
      )
      @output_io.puts error_log.to_h.to_json
      @output_io.flush
    end
  end

  def process_tar_entry(entry, tarball_path, file_size = nil, file = nil)
    return unless image_file?(entry.full_name)
    
    @processed_count += 1
    $stderr.puts "Processing #{entry.full_name}..." if ENV['DEBUG']
    
    # Read file content into memory
    content = entry.read
    content_size = content.bytesize
    
    # Process with vips
    begin
      geotag = extract_geotag_from_memory(content, entry.full_name, tarball_path, content_size)
      if geotag
        @geotag_count += 1
        @output_io.puts geotag.to_h.to_json
        @output_io.flush
      end
    rescue => e
      error_log = ErrorLog.new(
        type: 'error',
        filename: entry.full_name,
        tarball: File.basename(tarball_path),
        error: e.class.name,
        details: e.message,
        exif_data: nil,
        file_size: content_size
      )
      @output_io.puts error_log.to_h.to_json
      @output_io.flush
    end
  end

  def image_file?(filename)
    case File.extname(filename).downcase
    when '.jpg', '.jpeg', '.tif', '.tiff', '.heic', '.heif', '.dng', '.cr2', '.nef', '.arw', '.png'
      true
    else
      false
    end
  end

  def extract_geotag_from_memory(content, filename, tarball_path, file_size = nil)
    # Load image from memory buffer
    image = Vips::Image.new_from_buffer(content, '')
    
    # Extract GPS data from EXIF (try both ifd2 and ifd3)
    lat_ref = nil
    lon_ref = nil
    lat = nil
    lon = nil
    
    # Try ifd2 first
    begin
      lat_ref = image.get('exif-ifd2-GPSLatitudeRef')
      lon_ref = image.get('exif-ifd2-GPSLongitudeRef')
      lat = extract_gps_coordinate(image, 'exif-ifd2-GPSLatitude', lat_ref)
      lon = extract_gps_coordinate(image, 'exif-ifd2-GPSLongitude', lon_ref)
    rescue Vips::Error
      # Try ifd3
      begin
        lat_ref = image.get('exif-ifd3-GPSLatitudeRef')
        lon_ref = image.get('exif-ifd3-GPSLongitudeRef')
        lat = extract_gps_coordinate(image, 'exif-ifd3-GPSLatitude', lat_ref)
        lon = extract_gps_coordinate(image, 'exif-ifd3-GPSLongitude', lon_ref)
      rescue Vips::Error
        # No GPS data found
      end
    end
    
    # Log parsing errors if we couldn't extract coordinates
    if ENV['DEBUG'] && (!lat || !lon)
      exif_dump = dump_exif_data(image) rescue nil
      error_log = ErrorLog.new(
        type: 'warning',
        filename: filename,
        tarball: File.basename(tarball_path),
        error: 'NoGPSData',
        details: "Could not extract GPS coordinates (lat: #{lat.inspect}, lon: #{lon.inspect})",
        exif_data: exif_dump,
        file_size: file_size
      )
      @output_io.puts error_log.to_h.to_json
      @output_io.flush
    end
    
    return nil unless lat && lon
    
    # Extract timestamps and calculate timezone
    timestamps = extract_timestamps_with_timezone(image, filename)
    
    # Extract altitude if available
    altitude = extract_altitude(image)
    
    # Format time as ISO8601 string
    time_iso8601 = timestamps[:time].iso8601
    
    GeoTag.new(
      lat: lat,
      lon: lon,
      time: time_iso8601,
      filename: filename,
      tarball: File.basename(tarball_path),
      altitude: altitude,
      timezone_offset: timestamps[:timezone_offset],
      timezone_source: timestamps[:timezone_source],
      file_size: file_size
    )
  rescue Vips::Error => e
    # Log vips errors with EXIF dump if debug mode
    if ENV['DEBUG'] && !e.message.include?('exif-ifd')
      exif_dump = dump_exif_data(image) rescue nil
      error_log = ErrorLog.new(
        type: 'error',
        filename: filename,
        tarball: File.basename(tarball_path),
        error: 'VipsError',
        details: e.message,
        exif_data: exif_dump,
        file_size: file_size
      )
      @output_io.puts error_log.to_h.to_json
      @output_io.flush
    end
    nil
  end

  def extract_gps_coordinate(image, coord_tag, ref_tag)
    coord_data = image.get(coord_tag)
    return nil unless coord_data
    
    # GPS coordinates are stored as rational numbers [degrees, minutes, seconds]
    coords = parse_gps_rational_array(coord_data)
    return nil unless coords && coords.length == 3
    
    # Convert to decimal degrees
    decimal = coords[0] + coords[1]/60.0 + coords[2]/3600.0
    
    # Apply reference (N/S for latitude, E/W for longitude)
    # ref_tag is a string like "N (N, ASCII, 2 components, 2 bytes)"
    ref_letter = ref_tag.to_s[0]
    case ref_letter
    when 'S', 'W'
      -decimal
    else
      decimal
    end
  rescue
    nil
  end

  def parse_gps_rational_array(data)
    # EXIF GPS data is stored as rational numbers
    # Format varies by library version, handle different cases
    case data
    when String
      # Parse vips string format like "51/1 34/1 1131/100 (51, 34, 11.31, Rational, 3 components, 24 bytes)"
      # Extract the first part before the parentheses
      rational_part = data.split('(').first.strip
      # Split by spaces and parse each rational
      rationals = rational_part.split(/\s+/)
      rationals.map do |r|
        if r.include?('/')
          num, den = r.split('/')
          num.to_f / den.to_f
        else
          r.to_f
        end
      end
    when Array
      data.map do |item|
        case item
        when Array
          item[0].to_f / item[1].to_f
        when Hash
          item.fetch(:numerator, 0).to_f / item.fetch(:denominator, 1).to_f
        else
          item.to_f
        end
      end
    else
      nil
    end
  end

  def extract_timestamps_with_timezone(image, filename)
    # Extract GPS timestamp (UTC)
    gps_time = extract_gps_timestamp(image)
    
    # Extract EXIF timestamp and offset
    exif_result = extract_exif_timestamp_with_offset(image)
    exif_time = exif_result[:time]
    exif_offset = exif_result[:offset]
    
    # Determine timezone offset and source
    timezone_offset = nil
    timezone_source = nil
    
    # Priority 1: Use EXIF OffsetTime if available
    if exif_time && exif_offset
      timezone_offset = exif_offset
      timezone_source = 'exif_offset'
      # Convert EXIF time to UTC using the offset
      time = exif_time - exif_offset
    # Priority 2: Calculate from GPS and EXIF time difference
    elsif gps_time && exif_time
      # Calculate offset in seconds
      offset_seconds = (exif_time - gps_time).to_i
      # Round to nearest 15 minutes (900 seconds) for cleaner timezone offsets
      timezone_offset = (offset_seconds / 900.0).round * 900
      timezone_source = 'gps_delta'
      time = gps_time
    # Priority 3: Use GPS time (already UTC)
    elsif gps_time
      time = gps_time
      timezone_source = 'gps_only'
    # Priority 4: Use EXIF time (assume UTC)
    elsif exif_time
      time = exif_time
      timezone_source = 'exif_assumed_utc'
    # Priority 5: Use filename
    else
      time = extract_time_from_filename(filename) || Time.now
      timezone_source = 'filename'
    end
    
    {
      time: time,
      timezone_offset: timezone_offset,
      timezone_source: timezone_source
    }
  end

  def extract_gps_timestamp(image)
    # Try ifd2 first
    begin
      date_stamp = image.get('exif-ifd2-GPSDateStamp')
      time_stamp = image.get('exif-ifd2-GPSTimeStamp')
      
      if date_stamp && time_stamp
        time_parts = parse_gps_rational_array(time_stamp)
        if time_parts && time_parts.length == 3
          date_parts = date_stamp.split(':')
          return Time.utc(
            date_parts[0].to_i,
            date_parts[1].to_i,
            date_parts[2].to_i,
            time_parts[0].to_i,
            time_parts[1].to_i,
            time_parts[2].to_i
          )
        end
      end
    rescue
      # Try ifd3
      begin
        date_stamp = image.get('exif-ifd3-GPSDateStamp')
        time_stamp = image.get('exif-ifd3-GPSTimeStamp')
        
        if date_stamp && time_stamp
          time_parts = parse_gps_rational_array(time_stamp)
          if time_parts && time_parts.length == 3
            date_parts = date_stamp.split(':')
            return Time.utc(
              date_parts[0].to_i,
              date_parts[1].to_i,
              date_parts[2].to_i,
              time_parts[0].to_i,
              time_parts[1].to_i,
              time_parts[2].to_i
            )
          end
        end
      rescue
        nil
      end
    end
  end

  def extract_exif_timestamp_with_offset(image)
    # Try to get EXIF DateTime and corresponding OffsetTime
    datetime_str = nil
    offset_str = nil
    
    # Try DateTimeOriginal with OffsetTimeOriginal (preferred)
    begin
      datetime_str = image.get('exif-ifd2-DateTimeOriginal')
      offset_str = image.get('exif-ifd2-OffsetTimeOriginal') rescue nil
    rescue
      # Try ifd0
      begin
        datetime_str = image.get('exif-ifd0-DateTimeOriginal')
        offset_str = image.get('exif-ifd0-OffsetTimeOriginal') rescue nil
      rescue
        # Continue
      end
    end
    
    # Fallback to DateTime with OffsetTime
    if datetime_str.nil?
      begin
        datetime_str = image.get('exif-ifd2-DateTime')
        offset_str = image.get('exif-ifd2-OffsetTime') rescue nil
      rescue
        begin
          datetime_str = image.get('exif-ifd0-DateTime')
          offset_str = image.get('exif-ifd0-OffsetTime') rescue nil
        rescue
          # No EXIF datetime found
        end
      end
    end
    
    return { time: nil, offset: nil } unless datetime_str
    
    # Parse datetime
    time = parse_exif_datetime(datetime_str)
    return { time: nil, offset: nil } unless time
    
    # Parse offset if available
    offset = parse_timezone_offset(offset_str) if offset_str
    
    { time: time, offset: offset }
  end
  
  def parse_timezone_offset(offset_str)
    # Parse offset string like "+01:00" or "-05:30"
    # Extract the clean offset value
    match = offset_str.match(/([+-])(\d{2}):(\d{2})/)
    return nil unless match
    
    sign = match[1] == '+' ? 1 : -1
    hours = match[2].to_i
    minutes = match[3].to_i
    
    # Return offset in seconds
    sign * (hours * 3600 + minutes * 60)
  rescue
    nil
  end

  def parse_exif_datetime(datetime_str)
    # EXIF datetime format: "2021:05:15 12:30:45"
    # This is local time without timezone info - parse as UTC for now
    # The actual timezone will be determined by comparing with GPS time if available
    parts = datetime_str.match(/(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})/)
    return nil unless parts
    
    Time.utc(
      parts[1].to_i, parts[2].to_i, parts[3].to_i,
      parts[4].to_i, parts[5].to_i, parts[6].to_i
    )
  rescue
    nil
  end

  def extract_time_from_filename(filename)
    basename = File.basename(filename, '.*')
    
    # Try various filename patterns
    case basename
    when /(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})/
      # Format: YYYYMMDD_HHMMSS - assume UTC
      Time.utc($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i)
    when /(\d{4})-(\d{2})-(\d{2})[ _](\d{2})[-.](\d{2})[-.](\d{2})/
      # Format: YYYY-MM-DD HH-MM-SS or similar - assume UTC
      Time.utc($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i)
    else
      nil
    end
  rescue
    nil
  end

  def dump_exif_data(image)
    exif_data = {}
    
    # Try to extract all GPS-related EXIF fields
    ['ifd0', 'ifd1', 'ifd2', 'ifd3'].each do |ifd|
      ['GPSLatitude', 'GPSLongitude', 'GPSLatitudeRef', 'GPSLongitudeRef', 
       'GPSAltitude', 'GPSAltitudeRef', 'GPSDateStamp', 'GPSTimeStamp',
       'DateTime', 'DateTimeOriginal', 'DateTimeDigitized'].each do |field|
        begin
          value = image.get("exif-#{ifd}-#{field}")
          exif_data["#{ifd}-#{field}"] = value.to_s
        rescue
          # Field doesn't exist
        end
      end
    end
    
    exif_data.empty? ? nil : exif_data
  rescue
    nil
  end

  def extract_altitude(image)
    altitude_data = nil
    ref = nil
    
    # Try ifd2 first
    begin
      altitude_data = image.get('exif-ifd2-GPSAltitude')
      ref = image.get('exif-ifd2-GPSAltitudeRef') rescue nil
    rescue Vips::Error
      # Try ifd3
      begin
        altitude_data = image.get('exif-ifd3-GPSAltitude')
        ref = image.get('exif-ifd3-GPSAltitudeRef') rescue nil
      rescue Vips::Error
        return nil
      end
    end
    
    return nil unless altitude_data
    
    altitude = case altitude_data
    when Array
      altitude_data[0].to_f / altitude_data[1].to_f
    when String
      matches = altitude_data.match(/\((\d+(?:\.\d+)?),(\d+)\)/)
      matches ? matches[1].to_f / matches[2].to_f : nil
    else
      altitude_data.to_f
    end
    
    # Check altitude reference (0 = above sea level, 1 = below sea level)
    altitude = -altitude if ref == 1
    
    altitude
  rescue
    nil
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.empty?
    $stderr.puts "Usage: #{$0} <tarball1.tgz|directory1> [tarball2.tgz|directory2 ...] > output.jsonl"
    $stderr.puts "       #{$0} takeout-*.tgz > photos_geotags.jsonl"
    $stderr.puts "       #{$0} /path/to/extracted/takeout > photos_geotags.jsonl"
    $stderr.puts ""
    $stderr.puts "Accepts both tarball files (.tgz, .tar.gz, .tar) and directories."
    $stderr.puts "When processing directories, uses directory basename as the 'tarball' field."
    exit 1
  end
  
  # Check if all paths exist
  missing_paths = ARGV.reject { |path| File.exist?(path) }
  unless missing_paths.empty?
    $stderr.puts "Error: Paths not found: #{missing_paths.join(', ')}"
    exit 1
  end
  
  extractor = GooglePhotosExifToJsonl.new($stdout)
  extractor.process_tarballs(ARGV)
end
