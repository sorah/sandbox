#!/usr/bin/env ruby
require 'time'
require 'optparse'
require 'io/console'

module LTSV
  def self.parse(line)
    Hash[
      line.chomp.split(/\t/).map { |_|
        l, v = _.split(/:/, 2)
        l && v && !l.empty? && !v.empty? ? [l.to_sym, v] : nil
      }.compact
    ]
  end
end

# not thread safe
class CycleArray
  def initialize(size)
    @array = []
    @limit_size = size
  end

  attr_reader :array

  def push(o)
    @array << o
    if @limit_size < @array.size
      @array.shift(@array.size-@limit_size)
    end
  end
end

class SpaceAllocator
  class Field
    def initialize(label:, min_space: 1, max_space: nil, fit: false)
      @label = label
      @min_space = min_space
      @max_space = max_space
      @fit = fit
      @length_history = CycleArray.new(100)
    end

    def fit?; @fit; end

    def label_size
      @label_size ||= label.to_s.size
    end

    def record_length(len)
      length_history.push len
      self
    end

    def average_length
      (length_history.array.inject(&:+) || 0) / length_history.array.size
    end

    attr_accessor :space
    attr_reader :label, :min_space, :max_space, :length_history
  end

  def initialize(fields, width, populate_interval)
    @fields = fields.map do |x|
      Field.new(**x)
    end

    @width = width

    @populate_interval = populate_interval
    @populate_count = 0
  end

  attr_reader :fields

  attr_reader :width

  def width=(o)
    @populate_count = 0
    @width = o
  end

  def record_length(column, len)
    @fields[column].record_length len
  end

  def spaces
    populate_if_necessary!
    @fields.map { |f| [f.label, f.space] }.to_h
  end

  def populate_if_necessary!
    populate! if @populate_count.zero?
    @populate_count = @populate_count.succ % @populate_interval
  end

    # Allocate width for each element (label:value pair).
    # space for "#{label}:" part and at least 1 width padding is guaranteed.
    # element.space is reserved width for stringified value.
    #
    # Purpose of allocating space is to fit elements in one line, and to have enough space as possible on each elements.

  def populate!
    # Remaining space
    space = @width

    # for debug purpose
    dump_space = proc do
      p fields.map {|f| [f.label, f.label_size.succ + f.space] }.to_h
      puts fields.map {|elem| "#{elem.label}:#{'X' * elem.space}" }.join(?|)
    end

    # "labelA:labelB:labelC:".size
    label_and_colons_width = fields.map { |_| _.label_size.succ }.inject(0, :+)
    space -= label_and_colons_width

    # padding between elements
    space -= fields.size - 1

    # Guarantee min_space
    fields.each do |field|
      space -= field.min_space
      field.space = field.min_space
    end

    prev_space = nil
    while 0 < space && prev_space != space
      prev_space = space

      fields.each do |field|
        allocated = space / fields.size
        space += field.space

        case
        when field.fit? && field.space < field.average_length
          # grow existing allocated space, using newly allocated space
          field.space = field.space + allocated
        when field.space < field.average_length
          # grow slowly until element reachs its value width
          field.space = [field.average_length, field.space + (allocated / 2)].min
        end

        field.space = field.max_space if field.max_space && field.space > field.max_space

        space -= field.space
        break unless 0 < space
      end
    end

    if space > 0
      # When space is still remaining, allocate to fit=true elements
      fit_fields = fields.select(&:fit?)

      unless fit_fields.empty?
        if space % fit_fields.size == 0
          allocated = space / fit_fields.size
          fit_fields.each do |field|
            field.space += allocated
            space -= allocated
          end
        else
          while space > 0
            fit_fields.reverse_each do |field|
              field.space += 1
              space -= 1
              break if space <= 0
            end
          end
        end
      end
    end
  end
end

module Renderers
  class Base
    BG_COLORS = {
      black:   40,
      red:     41,
      green:   42,
      yellow:  43,
      blue:    44,
      magenta: 45,
      cyan:    46,
      white:   47,
      bright_black:    100,
      bright_red:      101,
      bright_green:    102,
      bright_yellow:   103,
      bright_blue:     104,
      bright_magenta:  105,
      bright_cyan:     106,
      bright_white:    107,
    }

    FG_COLORS = {
      black:   30,
      red:     31,
      green:   32,
      yellow:  33,
      blue:    34,
      magenta: 35,
      cyan:    36,
      white:   37,
      bright_black:    90,
      bright_red:      91,
      bright_green:    92,
      bright_yellow:   93,
      bright_blue:     94,
      bright_magenta:  95,
      bright_cyan:     96,
      bright_white:    97,
    }

    RESET = "\e[0m"
    BOLD = "\e[1m"
    UNDERLINE = "\e[4m"
    BLINK = "\e[5m"

    PADDING = ' '.freeze

    def initialize(color, space_allocator, log)
      @color = !!color
      @space_allocator = space_allocator
      @log = log
    end

    attr_reader :color, :log

    # Returns array of Hash. each Hash represents an element.
    # TODO: Classify elements
    #
    # Current schema of element is:
    #   label: label
    #   value: value
    #   width: value width
    #   min_space: minimum width for value that guaranteed for display.
    #   max_space: maximum width for value to display.
    #   fg: foreground color name or ANSI code
    #   bg: background color name or ANSI code
    #   bold: show value with bold or not (boolean)
    #   underline: show value with underline or not (boolean)
    #   blink: show value with blinked or not (boolean)
    #   space: reserved width to show value
    def elements
      @elements ||= @space_allocator.fields.map do |f|
        v = log[f.label]
        next unless v

        meth = "render_#{f.label}"
        elem = respond_to?(meth) ? __send__(meth, v) : default(f.label, v)

        elem[:label] = f.label
        elem[:value] = elem[:value].to_s
        elem[:width] = elem[:value].size

        f.record_length elem[:value].size

        elem
      end.compact
    end

    def spaces
      @spaces ||= @space_allocator.spaces
    end

    def render
      components = elements.map do |elem|
        value, padding = put_value_in_space(elem, spaces[elem[:label]])

        if @color
          bg = elem[:bg] ? "\e[#{BG_COLORS[elem[:bg]] || elem[:bg]}m" : nil
          fg = elem[:fg] ? "\e[#{FG_COLORS[elem[:fg]] || elem[:fg]}m" : nil
          bold = elem[:bold] ? BOLD : nil
          underline = elem[:underline] ? UNDERLINE : nil
          blink = elem[:blink] ? BLINK : nil

          "#{bg}#{BOLD}#{elem[:label]}:#{RESET}#{bg}#{fg}#{bold}#{underline}#{blink}#{value}#{padding}"
        else
          "#{elem[:label]}:#{value}#{padding}"
        end
      end

      components.join("#{@space_allocator.width ? PADDING : ?\t}#{@color ? RESET : nil}")
    end

    def default(l, v)
      {
        bg: nil,
        fg: nil,
        bold: false,
        dark: false,
        underline: false,
        blink: false,
        label: l,
        value: v,
      }
    end

    private

    # Put element's value in its space.
    # if allocated space remains, this method returns additional padding string.
    # if allocated space is smallar than value width, this method returns sliced value string and no padding.
    def put_value_in_space(elem, space)
      if space
        padding_size = space - elem[:width]
        if padding_size < 0
          [elem[:value][0, space], nil]
        else
          [elem[:value], PADDING * padding_size]
        end
      else
        [elem[:value], nil]
      end
    end
  end

  class Nginx < Base
    def self.field_time
      {
        min_space: '%m/%d %H:%M:%S'.size,
        max_space: '%m/%d %H:%M:%S'.size,
      }
    end

    def render_time(v)
      t = Time.parse(v).strftime('%m/%d %H:%M:%S') rescue nil
      {
        label: :time,
        value: t || v,
        fg: :bright_black,
      }
    end

    def self.field_method
      {
        min_space: 5,
      }
    end

    def render_method(v)
      {
        label: :method,
        value: v,
        fg: v != 'GET' ? :magenta : nil,
      }
    end

    def self.field_elapsed_times
      {
        min_space: 5,
        max_space: 5,

      }
    end

    def render_elapsed_times(l, v)
      f = v.to_f
      fg = case
           when f > 1
             :red
           when f > 0.6
             :yellow
           else
             nil
           end
      bold = f > 1.5
      {
        label: l,
        value: v,
        bold: bold,
        fg: fg,
      }
    end

    def self.field_reqtime; field_elapsed_times; end
    def self.field_runtime; field_elapsed_times; end
    def self.field_apptime; field_elapsed_times; end

    def render_reqtime(v)
      render_elapsed_times :reqtime, v
    end

    def render_runtime(v)
      render_elapsed_times :runtime, v
    end

    def render_apptime(v)
      render_elapsed_times :apptime, v
    end

    def self.field_status
      {
        min_space: 3,
        max_space: 3,
      }
    end

    def render_status(v)
      bg = case v[0]
      when '2'
        nil
      when '3'
        nil
      when '4'
        v == '499'.freeze ? :red : :magenta
      when '5'
        :red
      else
        nil
      end

      {
        label: :status,
        value: v,
        bg: bg,
      }
    end

    def self.field_uri
      {
        min_space: 30,
      }
    end

    def render_uri(v)
      {
        label: :uri,
        value: v,
        fit: true,
      }
    end

    def self.field_host
      {
        min_space: 15,
        max_space: 15,
      }
    end


    def render_host(v)
      {
        label: :host,
        value: v,
      }
    end

    def self.field_forwardedfor
      {
        min_space: 15,
        max_space: 15,
      }
    end

    def render_forwardedfor(v)
      {
        label: :forwardedfor,
        value: v,
      }
    end

    def self.field_ua
      {
        fit: true,
        min_space: 10,
      }
    end

    def render_ua(v)
      {
        label: :ua,
        value: v,
      }
    end
  end
end

class CLI
  MODES = {
    nginx_short: %i(time status reqtime method uri),
    nginx_normal: %i(time status reqtime method uri forwardedfor),
    nginx_long: %i(time status reqtime runtime method uri host forwardedfor),
    nginx_longer: %i(time status reqtime runtime method uri host server_name ua),
  }

  def initialize
    @options = {
      width: $stdout.tty? ? $stdout.winsize[1] : nil,
      color: $stdout.tty?,
      fields: MODES[:nginx_normal],
      renderer: 'nginx',
      sigwinch: true,
    }
    parse_options!
  end

  attr_reader :options

  def parse_options!
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.on("-c", "--[no-]color", "Run verbosely") do |v|
        options[:color] = v
      end

      opts.on("-r RENDERER", "--renderer RENDERER", "Set renderer (default=nginx; #{Renderers.constants(false).inspect}") do |v|
        options[:renderer] = v
      end


      opts.on("-m MODE", "--mode MODE", "Show predefined fields set (default=nginx_normal; #{MODES.keys.map(&:to_s).join(?,)})") do |v|
        options[:fields] = (MODES[v.to_sym] || MODES[:"#{options[:renderer]}_#{v}"]) or raise "unknown predefiend fields"
      end

      opts.on("-f FIELDS", "--fields FIELDS", "Fields (separated by comma); overrides --mode") do |v|
        options[:fields] = v.split(/,\s*|\s+/).map(&:to_sym)
      end

      opts.on("-w WIDTH", "--width WIDTH", "specify width, 0 to disable") do |v|
        options[:width] = v.to_i
        if options[:width].zero?
          options[:width] = nil
          options[:sigwinch] = false
        end
      end

      opts.on("--no-width", "disable -w, --width") do |v|
        options[:width] = nil
      end

      opts.on("--sigwinch", "--[no-]sigwinch", "Use terminal winsize for width and response to sigwinch (default: enabled)") do |v|
        options[:sigwinch] = v
      end
    end.parse!
  end

  def renderer
    @renderer ||= Renderers.const_get(options[:renderer].gsub(/(?:\A|_)./) { |_| _[-1].upcase })
  end

  def fields
    @fields ||= options[:fields].map do |f|
      meth = :"field_#{f}"
      renderer.respond_to?(meth) ? renderer.__send__(meth).merge(label: f) : {label: f}
    end
  end
  def space_allocator
    @space_allocator ||= SpaceAllocator.new(fields, options[:width], 10)
  end

  def run
    if options[:sigwinch] && $stdout.tty?
      trap(:WINCH) do
        space_allocator.width = $stdout.winsize[1]
      end
    end

    while line = ARGF.gets
      log = LTSV.parse(line)

      puts renderer.new(options[:color], space_allocator, log).render #.gsub(/\e\[\d+?m/,'')
    end
  end

  if ENV['STACKPROF']
    require 'stackprof'
    alias run_orig run
    def run
      StackProf.run(mode: :cpu, out: '/tmp/ltsv-view.stackprof', &method(:run_orig))
    ensure
      StackProf.results('/tmp/ltsv-view.stackprof')
    end
  end
end

Dir['/usr/share/ltsv-view/plugins/*.rb'].each do |x|
  require x
end

CLI.new.run
