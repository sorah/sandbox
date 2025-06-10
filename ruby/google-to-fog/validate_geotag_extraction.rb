#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'minitar', path: '~/git/github.com/halostatue/minitar'
end

require 'json'
require 'zlib'
require 'minitar'

class GeotagExtractionValidator
  ValidationResult = Data.define(:tarball, :total_images, :last_tarball_file, :last_jsonl_file, :status)
  
  def initialize(fast_mode: false)
    @image_extensions = %w[.jpg .jpeg .tif .tiff .heic .heif .dng .cr2 .nef .arw .png].freeze
    @fast_mode = fast_mode
  end
  
  def validate(jsonl_file, tarball_paths)
    results = []
    
    # Parse JSONL to get last processed file per tarball
    puts "Parsing JSONL file: #{jsonl_file}"
    last_processed_files = parse_jsonl_for_last_files(jsonl_file)
    puts "Found records for #{last_processed_files.keys.length} tarballs in JSONL"
    puts
    
    tarball_paths.each_with_index do |tarball_path, index|
      puts "Validating tarball #{index + 1}/#{tarball_paths.length}: #{File.basename(tarball_path)}"
      
      begin
        result = validate_tarball(tarball_path, last_processed_files)
        results << result
        display_single_result(result)
      rescue => e
        error_result = ValidationResult.new(
          tarball: File.basename(tarball_path),
          total_images: 0,
          last_tarball_file: nil,
          last_jsonl_file: last_processed_files[File.basename(tarball_path)],
          status: 'ERROR'
        )
        results << error_result
        display_single_result(error_result, error: e)
      end
      
      puts
    end
    
    display_summary(results)
    results
  end
  
  private
  
  def validate_tarball(tarball_path, last_processed_files)
    tarball_basename = File.basename(tarball_path)
    # Remove .tgz extension when looking up in JSONL data
    tarball_key = tarball_basename.sub(/\.tgz$/, '')
    
    # Get last image file from tarball (alphabetically sorted)
    last_tarball_file, total_images = scan_tarball_for_last_file(tarball_path)
    
    # Get last processed file for this tarball from JSONL
    last_jsonl_file = last_processed_files[tarball_key]
    
    # Determine status by comparing last files
    status = case
    when last_tarball_file.nil?
      'NO_IMAGES'
    when last_jsonl_file.nil?
      'NOT_PROCESSED'
    when last_tarball_file == last_jsonl_file
      'COMPLETE'
    else
      'INCOMPLETE'
    end
    
    ValidationResult.new(
      tarball: tarball_basename,
      total_images: total_images,
      last_tarball_file: last_tarball_file,
      last_jsonl_file: last_jsonl_file,
      status: status
    )
  end
  
  def scan_tarball_for_last_file(tarball_path)
    last_image_file = nil
    total_images = 0
    recent_images = []  # Keep a buffer of recent image files
    buffer_size = 100   # Keep last 100 image filenames in memory
    
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
          
          if image_file?(entry.full_name)
            total_images += 1
            
            # Keep a rolling buffer of recent image files
            recent_images << entry.full_name
            recent_images.shift if recent_images.length > buffer_size
          end
        end
      end
    end
    
    # The last image is the last one in our buffer
    last_image_file = recent_images.last
    
    [last_image_file, total_images]
  rescue => e
    $stderr.puts "Error scanning #{tarball_path}: #{e.message}"
    raise e
  end
  
  def parse_jsonl_for_last_files(jsonl_file)
    last_processed_files = {}
    
    File.open(jsonl_file, 'r') do |file|
      file.each_line do |line|
        next if line.strip.empty?
        
        begin
          data = JSON.parse(line)
          
          # Extract filename and tarball from any record type (geotag, error, warning)
          if data['filename'] && data['tarball']
            # Remove .tgz extension from tarball field for consistent lookup
            tarball_key = data['tarball'].sub(/\.tgz$/, '')
            # Keep updating to get the last processed file per tarball
            last_processed_files[tarball_key] = data['filename']
          end
        rescue JSON::ParserError => e
          $stderr.puts "Warning: Failed to parse JSONL line: #{e.message}"
        end
      end
    end
    
    last_processed_files
  rescue => e
    $stderr.puts "Error reading JSONL file #{jsonl_file}: #{e.message}"
    {}
  end
  
  def image_file?(filename)
    ext = File.extname(filename).downcase
    @image_extensions.include?(ext)
  end
  
  def display_single_result(result, error: nil)
    puts "Status: #{result.status}"
    puts "Total images: #{result.total_images > 0 ? result.total_images : 'N/A'}"
    puts "Last file in tarball: #{result.last_tarball_file || 'N/A'}"
    puts "Last file in JSONL: #{result.last_jsonl_file || 'N/A'}"
    
    case result.status
    when 'COMPLETE'
      puts "✓ Tarball processing complete (last file matches)"
    when 'NO_IMAGES'
      puts "⚠ No image files found in tarball"
    when 'NOT_PROCESSED'
      puts "✗ Tarball not processed (no records found in JSONL)"
    when 'INCOMPLETE'
      puts "✗ Tarball processing incomplete (last file mismatch)"
    when 'ERROR'
      puts "✗ Error occurred while scanning tarball"
      puts "Error: #{error.class.name}: #{error.message}" if error
    end
  end
  
  def display_summary(results)
    puts "=" * 60
    puts "VALIDATION SUMMARY"
    puts "=" * 60
    
    total_tarballs = results.length
    complete_tarballs = results.count { |r| r.status == 'COMPLETE' }
    error_tarballs = results.count { |r| r.status == 'ERROR' }
    total_images = results.sum(&:total_images)
    
    puts "Total tarballs: #{total_tarballs}"
    puts "Complete: #{complete_tarballs}"
    puts "Incomplete: #{total_tarballs - complete_tarballs - error_tarballs}"
    puts "Errors: #{error_tarballs}"
    puts "Total images scanned: #{total_images}"
    puts
    
    if complete_tarballs == total_tarballs
      puts "✓ All tarballs validated successfully"
    elsif error_tarballs > 0
      puts "✗ #{error_tarballs} tarballs had scanning errors"
    else
      puts "✗ #{total_tarballs - complete_tarballs} tarballs have processing issues"
    end
    
    # Show error tarballs
    error_results = results.select { |r| r.status == 'ERROR' }
    if error_results.any?
      puts
      puts "Tarballs with errors:"
      error_results.each { |r| puts "  - #{r.tarball}" }
    end
    
    # Show incomplete tarballs
    incomplete_results = results.select { |r| ['INCOMPLETE', 'NOT_PROCESSED'].include?(r.status) }
    if incomplete_results.any?
      puts
      puts "Tarballs needing processing:"
      incomplete_results.each { |r| puts "  - #{r.tarball} (#{r.status})" }
    end
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.length < 2
    $stderr.puts "Usage: #{$0} <output.jsonl> <tarball1.tgz> [tarball2.tgz ...]"
    $stderr.puts "       #{$0} photos_geotags.jsonl takeout-*.tgz"
    $stderr.puts ""
    $stderr.puts "Validates that all image files in the tarballs were processed in the JSONL output."
    $stderr.puts "Expects JSONL to contain DEBUG=1 output with error/warning records for files without geotags."
    exit 1
  end
  
  jsonl_file = ARGV[0]
  tarball_paths = ARGV[1..-1]
  
  # Check if JSONL file exists
  unless File.exist?(jsonl_file)
    $stderr.puts "Error: JSONL file '#{jsonl_file}' not found"
    exit 1
  end
  
  # Check if all tarball files exist
  missing_files = tarball_paths.reject { |f| File.exist?(f) }
  unless missing_files.empty?
    $stderr.puts "Error: Tarball files not found: #{missing_files.join(', ')}"
    exit 1
  end
  
  fast_mode = ENV['FAST_MODE'] == '1'
  validator = GeotagExtractionValidator.new(fast_mode: fast_mode)
  results = validator.validate(jsonl_file, tarball_paths)
  
  # Exit with error code if any validation failed
  exit_code = results.all? { |r| r.status == 'COMPLETE' } ? 0 : 1
  exit exit_code
end
