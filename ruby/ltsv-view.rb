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

    def initialize(color, width, fields, log)
      @color = !!color
      @width = width
      @fields = fields
      @log = log
    end

    attr_reader :color, :width, :fields, :log

    # Returns array of Hash. each Hash represents an element.
    # TODO: Classify elements
    #
    # Current schema of element is:
    #   label: label
    #   value: value
    #   width: value width
    #   min_width: minimum width for value that guaranteed for display.
    #   max_width: maximum width for value to display.
    #   fg: foreground color name or ANSI code
    #   bg: background color name or ANSI code
    #   bold: show value with bold or not (boolean)
    #   underline: show value with underline or not (boolean)
    #   blink: show value with blinked or not (boolean)
    #   space: reserved width to show value
    def elements
      @elements ||= @fields.map do |l|
        v = log[l]
        next unless v

        meth = "render_#{l}"
        elem = respond_to?(meth) ? __send__(meth, v) : default(l, v)

        elem[:value] = elem[:value].to_s
        elem[:width] = elem[:value].size
        elem[:min_width] ||= 1

        elem
      end.compact
    end

    # Allocate width for each element (label:value pair).
    # space for "#{label}:" part and at least 1 width padding is guaranteed.
    # element.space is reserved width for stringified value.
    #
    # Purpose of allocating space is to fit elements in one line, and to have enough space as possible on each elements.
    def allocate_spaces
      return unless @width

      # Remaining space
      space = @width

      # for debug purpose
      dump_elements_space = proc do
        p Hash[elements.map {|elem| [elem[:label], elem[:label].to_s.size.succ + elem[:space]] }]
        puts elements.map {|elem| "#{elem[:label]}:#{'X' * elem[:space]}" }.join(?|)
      end

      # "labelA:labelB:labelC:".size
      label_and_colons_width = elements.map { |_| _[:label].to_s.size.succ }.inject(0, :+)
      space -= label_and_colons_width

      # padding between elements
      space -= elements.size - 1

      # Guarantee min_width
      elements.each do |elem|
        space -= elem[:min_width]
        elem[:space] = elem[:min_width]
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
          when elem[:max_width] && allocated > elem[:max_width]
            # stop growing if reached to max_width
            elem[:space] = elem[:max_width]
          when elem[:space] < elem[:width]
            # Grow slowly until element reachs its value width
            elem[:space] = [elem[:width], elem[:space] + (allocated / 2)].min
          end

          space -= elem[:space]
          break unless 0 < space
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
        value, padding = make_padding(elem)

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

      components.join("#{@width ? PADDING : ?\t}#{@color ? RESET : nil}")
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

    def make_padding(elem)
      if elem[:space]
        padding_size = elem[:space] - elem[:width]
        if padding_size < 0
          [elem[:value][0, elem[:space]], nil]
        else
          [elem[:value], PADDING * padding_size]
        end
      else
        [elem[:value], nil]
      end
    end
  end

  class Nginx < Base
    def render_time(v)
      t = Time.parse(v).strftime('%m/%d %H:%M:%S') rescue nil
      {
        label: :time,
        value: t || v,
        min_width: (t || v).size,
        max_width: (t || v).size,
        fg: :bright_black,
      }
    end

    def render_method(v)
      {
        label: :method,
        value: v,
        min_width: 5,
        fg: v != 'GET' ? :magenta : nil,
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
        min_width: 4,
        max_width: 4,
        bold: bold,
        fg: fg,
      }
    end

    def render_reqtime(v)
      render_elapsed_times :reqtime, v
    end

    def render_runtime(v)
      render_elapsed_times :runtime, v
    end

    def render_apptime(v)
      render_elapsed_times :apptime, v
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
        min_width: 3,
        max_width: 3,
      }
    end

    def render_uri(v)
      {
        label: :uri,
        value: v,
        min_width: 30,
        fit: true,
      }
    end

    def render_host(v)
      {
        label: :host,
        value: v,
        min_width: 15,
        max_width: 15,
      }
    end

    def render_forwardedfor(v)
      {
        label: :forwardedfor,
        value: v,
        min_width: 15,
        max_width: 15,
      }
    end

    def render_ua(v)
      {
        label: :ua,
        value: v,
        fit: true,
        min_width: 10,
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
        options[:fields] = v.split(/,\s+|\s+/)
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

  def run
    if options[:sigwinch] && $stdout.tty?
      trap(:WINCH) do
        options[:width] = $stdout.winsize[1]
      end
    end
    while line = ARGF.gets
      log = LTSV.parse(line)

      puts renderer.new(options[:color], options[:width], options[:fields], log).render #.gsub(/\e\[\d+?m/,'')
    end
  end
end

Dir['/usr/share/ltsv-view/plugins/*.rb'].each do |x|
  require x
end

CLI.new.run
