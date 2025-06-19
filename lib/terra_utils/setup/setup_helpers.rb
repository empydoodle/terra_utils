#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    ## General Thor helpers
    module SetupHelpers
      def say_(message_parts, *style, method: :say, **options)
        style.compact!
        indent = style.shift if style.first.is_a?(Integer)
        %i[leading_br trailing_br].each { |opt| options[opt] = true } if style.delete(:parag)
        options[:tall] = true if style.delete(:tall)

        msg_array = [message_parts].flatten
        with_indent(indent, **options.slice(:leading_br, :trailing_br)) do
          block_say(msg_array, method, style, options)
        end
      end

      def error_(message_parts, *style, **options)
        style.compact!
        indent = style.shift if style.first.is_a?(Integer)
        style  = %i[red bold] if style.empty?
        say_(message_parts, indent, *style, method: :say_error, **options)
      end

      def header_(message_parts, *style, **options)
        style.compact!
        indent = style.shift if style.first.is_a?(Integer)
        style.unshift(%i[black on_green]).flatten!               # DEFAULT: black on green
        style.push(:bold).uniq! unless options[:bold] == false   # DEFAULT: bold (independent from other styling)
        options = default_header_options(options)                # DEFAULT: leading line break, margin: 1, block
        say_(message_parts, *[indent, style].flatten.compact, new_line: true, **options)
      end

      def info_(message_parts, *style, **options)
        style.compact!
        indent = style.shift if style.first.is_a?(Integer)
        style.unshift(%i[black on_cyan]).flatten!                      # DEFAULT: black on cyan
        options[:block]      = true if options.fetch(:block, nil).nil? # DEFAULT: style block (accept false)
        options[:margin]   ||= 1                                       # DEFAULT: margin: 1
        say_(message_parts, *[indent, style].flatten.compact, new_line: true, **options)
      end

      def ask_(prompt, *style, escape: false, **options)
        if escape
          escape = 'X' unless escape.is_a?(String)
          prompt = "#{prompt} ['#{escape}' to escape]"
        end
        result = q_(:ask, "#{prompt}>", style, options)
        result.downcase == escape.downcase ? nil : result
      rescue NoMethodError
        result
      end

      def no_?(prompt, *style, **options)
        q_(:no?, "#{prompt} [y/n]> (y)", style, options)
      end

      def yes_?(prompt, *style, **options)
        q_(:yes?, "#{prompt} [y/n]> (n)", style, options)
      end

      def table_(entries:, **options)
        # axis determines direction of headers
        say('') if options.fetch(:leading_br, true)
        options[:indent] = options.fetch(:indent, 0) * 2
        options[:axis] ||= :y                                      # DEFAULT: y axis
        %i[headers_x headers_y].each { |opt| options[opt] ||= [] } # DEFAULT: empty headers
        table_data = format_table_data(entries, **options.slice(*%i[axis headers_x headers_y]))
        print_table(table_data, **options)
        say('') if options.fetch(:trailing_br, true)
      end

      private

      def with_indent(indent = nil, leading_br: nil, trailing_br: nil)
        say('') if leading_br
        shell.padding = indent || 0
        yield
        shell.padding = 0
        say('') if trailing_br
      end

      def format_message(msg, margin, block_length, center = nil)
        blength = [margin * 2, block_length].reduce(:+)
        if center
          msg.center(blength)
        else
          [' ' * margin, msg.ljust(blength - margin)].join
        end
      end

      def empty_line(margin, block_length, style)
        str = format_message('', margin, block_length, true)
        say(str, style, true)
      end

      def block_say(msg_array, method, style, options)
        block_length = options.fetch(:block, false) ? msg_array.map(&:to_s).max_by(&:length).length : 0
        margin       = options.fetch(:margin, 0)

        empty_line(margin, block_length, style) if options.fetch(:tall, false)
        msg_array.each_with_index do |msg, i|
          center = (i.zero? && options.fetch(:title, false)) || options.fetch(:center, false)
          str    = format_message(msg, margin, block_length, center)
          public_send(method, str, style, options.fetch(:new_line, true)) # DEFAULT: Line break after string
        end
        empty_line(margin, block_length, style) if options.fetch(:tall, false)
      end

      def default_header_options(options)
        options[:leading_br] = true if options.fetch(:leading_br, nil).nil? # DEFAULT: leading line break (accept false)
        options[:block]      = true if options.fetch(:block, nil).nil?      # DEFAULT: style block (accept false)
        options[:margin]   ||= 1                                            # DEFAULT: margin: 1
        options[:title]      = true if options.fetch(:title, nil).nil?      # DEFAULT: Center top line
        options
      end

      def ask_options(options)
        %i[default limited_to echo path].map do |opt|
          val = options.delete(opt)
          next nil if val.nil?

          [opt, val]
        end.compact.to_h
      end

      def q_(method, prompt, style, options)
        style.compact!
        indent = style.shift if style.first.is_a?(Integer)
        style.push(:bold).uniq! unless options.fetch(:bold, false) # bold by default
        opts     = ask_options(options) if method == :ask
        response = nil
        with_indent(indent, **options.slice(:leading_br, :trailing_br)) do
          args     = [method, prompt, style, opts].compact
          response = public_send(*args)
        end
        response
      end

      def apply_table_headers(data, headers_x, headers_y, header_separator: nil)
        return data if [headers_x, headers_y].flatten.empty? # return data if no headers

        unless headers_x.empty?
          data.unshift(headers_x)
          header_separator = ' '
        end
        headers_y.empty? ? headers_y = nil : headers_y.unshift(header_separator).compact!
        data.transpose.unshift(headers_y).compact.transpose
      end

      def format_table_data(entries, headers_x: [], headers_y: [], axis: :x)
        case axis
        when :x
          apply_table_headers(entries.dup, headers_x.dup, headers_y.dup)
        when :y
          apply_table_headers(entries.dup.transpose, headers_x.dup, headers_y.dup)
        end
      end
    end
  end
end
