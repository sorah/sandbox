#!/usr/bin/env ruby
require 'time'
require 'optparse'
require 'io/console'

module LTSV
  def self.parse(line)
    Hash[
      line.chomp.split(/\t/).map { |_|
        k, v = _.split(/:/, 2)
        k && v && !k.empty? && !v.empty? ? [k.to_sym, v] : nil
      }.compact
    ]
  end
end

module Renderers
  class Base
    RESET = "\e[0m"

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

    BOLD = "\e[1m"
    UNDERLINE = "\e[4m"
    BLINK = "\e[5m"

    def initialize(color, width, fields, log)
      @color = !!color
      @width = width
      @fields = fields
      @log = log
    end

    attr_reader :color, :width, :fields, :log

    def elements
      @elements ||= @fields.map do |k|
        v = log[k]
        next unless v

        meth = "render_#{k}"
        elem = respond_to?(meth) ? __send__(meth, v) : default(k, v)

        elem[:value] = elem[:value].to_s
        elem[:width] = elem[:value].size
        elem[:min_width] ||= elem[:width]

        elem
      end.compact
    end

    def allocate_spaces
      return unless @width

      # Remaining space
      space = @width 

      # "keyA:keyB:keyC:".size
      key_and_colons_width = elements.map { |_| _[:key].to_s.size.succ }.inject(:+)
      space -= key_and_colons_width

      # Guarantee min_width + 1 width padding
      elements.each do |elem|
        space -= elem[:min_width].succ
        elem[:space] = elem[:min_width].succ
      end

      prev_space = nil
      while 0 < space && prev_space != space
        prev_space = space

        elements.each do |elem|
          allocated = space / elements.size
          space += elem[:space]

          case
          when elem[:fit]
            # Grow existing allocated space, using newly allocated space
            elem[:space] = elem[:space] + allocated
          when elem[:max_width] == -1
            # Ignores space allocation
            # Grow to value width by one step
            elem[:space] = elem[:width] + allocated
          when elem[:max_width] && allocated > elem[:max_width].succ
            # stop growing if reached to max_width
            elem[:space] = elem[:max_width].succ
          else
            # Use only (allocated space / 2)
            # May shrink at later step
            elem[:space] = elem[:min_width] + (allocated / 2)
          end

          space -= elem[:space]
          break if space <= 0
        end
      end

      if space > 0
        # When space is still remaining, allocate to fit=true elements
        fit_elements = elements.select { |_| _[:fit] }
        unless fit_elements.empty?
          if space % fit_elements.size == 0
            allocated = space / fit_elements.size
            fit_elements.each do |elem|
              elem[:space] += allocated
              space -= allocated
            end
          else
            while space > 0
              fit_elements.reverse_each do |elem|
                elem[:space] += 1
                space -= 1
                break if space <= 0
              end
            end
          end
        end
      end
    end

    def render
      allocate_spaces

      components = elements.map do |elem|
        padding = make_padding(elem)

        if @color
          bg = elem[:bg] ? "\e[#{BG_COLORS[elem[:bg]] || elem[:bg]}m" : nil
          fg = elem[:fg] ? "\e[#{FG_COLORS[elem[:fg]] || elem[:fg]}m" : nil
          bold = elem[:bold] ? BOLD : nil
          underline = elem[:underline] ? UNDERLINE : nil
          blink = elem[:blink] ? BLINK : nil

          "#{bg}#{BOLD}#{elem[:key]}:#{RESET}#{bg}#{fg}#{bold}#{underline}#{blink}#{elem[:value]}#{padding}"
        else
          "#{elem[:key]}:#{elem[:value]}#{padding}"
        end
      end

      components.join("#{@width ? nil : ?\t}#{@color ? RESET : nil}")
    end

    def default(k, v)
      {
        bg: nil,
        fg: nil,
        bold: false,
        dark: false,
        underline: false,
        blink: false,
        key: k,
        value: v,
      }
    end

    private

    PADDING = ' '.freeze

    def make_padding(elem)
      if elem[:space]
        padding_size = elem[:space] - elem[:width]
        if padding_size < 1
          # FIXME: destructive
          elem[:value] = elem[:value][0..padding_size-2]
          PADDING
        else
          PADDING * padding_size
        end
      else
        nil
      end
    end
  end

  class Nginx < Base
    def render_time(v)
      t = Time.parse(v).strftime('%m/%d %H:%M:%S') rescue nil
      {
        key: :time,
        value: t || v,
        min_width: (t || v).size,
        max_width: (t || v).size,
        fg: :bright_black,
      }
    end

    def render_method(v)
      {
        key: :method,
        value: v,
        min_width: 5,
        fg: v != 'GET' ? :magenta : nil,
      }
    end

    def render_reqtime(v)
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
        key: :reqtime,
        value: v,
        min_width: 6,
        bold: bold,
        fg: fg,
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
        key: :status,
        value: v,
        bg: bg,
        min_width: 3,
        max_width: 3,
      }
    end

    def render_uri(v)
      {
        key: :uri,
        value: v,
        min_width: 30,
        fit: true,
      }
    end
  end
end

class CLI
  MODES = {
    short: %i(time status reqtime method uri),
    normal: %i(time status reqtime method uri),
    long: %i(time status reqtime runtime method uri host server_name),
    longer: %i(time status reqtime runtime method uri host server_name ua),
  }

  def initialize
    @options = {
      width: $stdout.tty? ? $stdout.winsize[1] : nil,
      color: $stdout.tty?,
      fields: MODES[:normal],
      renderer_name: 'nginx',
    }
    parse_options!
  end

  attr_reader :options

  def parse_options!
    OptionParser.new do |opts|
      opts.banner = "Usage: format-ltsv-access-log [options]"

      opts.on("-c", "--[no-]color", "Run verbosely") do |v|
        options[:color] = v
      end

      opts.on("-m MODE", "--mode MODE", "Show predefined fields set (short, normal, long; default=normal)") do |v|
        options[:fields] = MODES[v.to_sym] or raise "unknown predefiend fields"
      end

      opts.on("-f FIELDS", "--fields FIELDS", "Fields (separated by comma); overrides --mode") do |v|
        options[:fields] = v.split(/,\s+|\s+/)
      end

      opts.on("-w WIDTH", "--width WIDTH", "specify width, 0 to disable") do |v|
        options[:width] = v.to_i
        options[:width] = nil if options[:width].zero?
      end

      opts.on("--no-width", "disable -w, --width") do |v|
        options[:width] = nil
      end
    end.parse!
  end

  def renderer
    @renderer ||= Renderers.const_get(options[:renderer_name].gsub(/(?:\A|_)./) { |_| _[-1].upcase })
  end

  def run
    ARGF.readlines.each do |line|
      log = LTSV.parse(line)

      puts renderer.new(options[:color], options[:width], options[:fields], log).render #.gsub(/\e\[\d+?m/,'')
    end
  end
end

CLI.new.run
