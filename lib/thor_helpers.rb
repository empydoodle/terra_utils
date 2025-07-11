#!/usr/bin/env ruby
# frozen_string_literal: true

## General Thor helpers
module ThorHelpers
  def say_(message_parts, *style, method: :say, **options)
    style.compact!
    indent = style.shift if style.first.is_a?(Integer)
    parse_style_opts(style, options) # Allow options to be passed in *style
    msg_array = [message_parts].flatten
    with_indent(indent, **options.slice(:leading_br, :trailing_br)) do
      block_say(msg_array, method, style.flatten, options)
    end
  end

  def hint_(message_parts, *style, **options)
    style.compact!
    indent = style.shift if style.first.is_a?(Integer)
    style.unshift(:blue)
    say_(message_parts, indent, *style, **options)
  end

  def error_(message_parts, *style, **options)
    style.compact!
    indent = style.shift if style.first.is_a?(Integer)
    style.unshift(%i[red bold]).flatten!
    style.push(:trailing_br) if options.fetch(:trailing_br, nil).nil? # DEFAULT: trailing line break (accept false)
    say_(message_parts, indent, *style.flatten, method: :say_error, **options)
  end

  def warn_(message_parts, *style, **options)
    style.compact!
    indent = style.shift if style.first.is_a?(Integer)
    style.unshift(%i[yellow bold])
    say_(message_parts, indent, *style.flatten, **options)
  end

  def log_(message_parts, *style, tag: :info, log_file: nil, **options)
    log_file ||= @log_file
    msg_array  = [message_parts].flatten
    lib        = options.delete(:lib) || self.class.name
    tag        = tag.to_s.upcase
    log_str    = "[#{Time.now}][#{lib.to_s.upcase}][#{tag}] #{msg_array.shift}"
    msg_array  = [log_str, msg_array].flatten
    append_to_file(log_file) { msg_array.join("\n") } if log_file
    tag == 'ERR' ? error_(msg_array, *style, **options) : say_(msg_array, *style, **options)
  end

  def debug_(message_parts, *style, **options)
    return unless @debug

    log_(message_parts, *style, tag: :info, **options)
  end

  def header_(message_parts, *style, **options)
    style.compact!
    indent = style.shift if style.first.is_a?(Integer)
    style.unshift(%i[black on_green]).flatten!                      # DEFAULT: black on green
    style.push(:bold).uniq! if options.fetch(:bold, true)           # DEFAULT: bold (independent from other styling)
    options = default_header_options(options, [message_parts].flatten.size)
    say_(message_parts, indent, *style.flatten, new_line: true, **options)
  end

  def info_(message_parts, *style, **options)
    style.compact!
    indent = style.shift if style.first.is_a?(Integer)
    style.unshift(%i[black on_cyan]).flatten!                           # DEFAULT: black on cyan
    options[:leading_br] = true if options.fetch(:leading_br, nil).nil? # DEFAULT: leading line break (accept false)
    options[:block]      = true if options.fetch(:block, nil).nil?      # DEFAULT: style block (accept false)
    options[:margin]   ||= 1                                            # DEFAULT: margin: 1
    say_(message_parts, indent, *style.flatten, new_line: true, **options)
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
    say('') if options.fetch(:leading_br, true)
    options[:indent] = options.fetch(:indent, 0) * 2
    options[:axis] ||= :y # DEFAULT: y axis
    table_data = format_table_data(entries, **options)
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

  def parse_style_opts(style_arr, options)
    style_arr.push(:leading_br, :trailing_br) if style_arr.delete(:parag)
    %i[tall center underline leading_br trailing_br].each do |style|
      options[style] = true if style_arr.include?(style) && options.fetch(style, nil).nil?
      style_arr.delete(style)
    end
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

  def decide_center(index, options)
    return true if index.zero? && options.fetch(:title, false)
    return true if index == 1 && options.fetch(:title, false) && options.fetch(:underline, false)
    return true if options.fetch(:center, false)

    false
  end

  def block_say(msg_array, method, style, options)
    block_length = options.fetch(:block, false) ? msg_array.map(&:to_s).max_by(&:length).length : 0
    margin       = options.fetch(:margin, 0)

    empty_line(margin, block_length, style) if options.fetch(:tall, false)
    msg_array.insert(1, '¯' * msg_array.first.size) if options.fetch(:underline, false)
    msg_array.each_with_index do |msg, i|
      str = format_message(msg, margin, block_length, decide_center(i, options))
      public_send(method, str, style, options.fetch(:new_line, true)) # DEFAULT: Line break after string
    end
    empty_line(margin, block_length, style) if options.fetch(:tall, false)
  end

  def default_header_options(options, no_lines)
    # DEFAULT: leading line break unless disabled
    options[:leading_br] = true if options.fetch(:leading_br, nil).nil?
    # DEFAULT: style block unless disabled
    options[:block]      = true if options.fetch(:block, nil).nil?
    # DEFAULT: center top line unless disabled
    options[:title]      = true if options.fetch(:title, nil).nil?
    # DEFAULT: underline top line unless disabled
    options[:underline]  = true if no_lines > 1 && options.fetch(:underline, nil).nil?
    # DEFAULT: single-line headers are tall unless disabled
    options[:tall]       = true if no_lines == 1 && options.fetch(:tall, nil).nil?
    options[:margin]   ||= 1 # DEFAULT: margin: 1
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
    parse_style_opts(style, options)
    opts     = ask_options(options) if method == :ask
    response = nil
    with_indent(indent, **options.slice(:leading_br, :trailing_br)) do
      args     = [method, prompt, style, opts].compact
      response = public_send(*args)
    end
    response
  end

  def construct_table(data, headers_x, headers_y, header_separator: nil)
    return data if [headers_x, headers_y].flatten.empty? # return data if no headers

    unless headers_x.empty?
      data.unshift(headers_x)
      header_separator = ' '
    end
    headers_y.empty? ? headers_y = nil : headers_y.unshift(header_separator).compact!
    data.transpose.unshift(headers_y).compact.transpose
  end

  def dir_tree(entries)
    # accepts paths e.g. [[projects, project1], [projects, project2, dir]]
    results = []
    entries.sort.each do |path_arr|
      path_arr.each_with_index do |dir, i|
        next results.push(dir) if i.zero?

        indent = (i - 1) * 3
        results << [
          (' ' * indent),
          "|_ #{dir}"
        ].join
      end
    end
    [results.uniq].transpose
  end

  def format_table_data(entries, axis: :x, headers_x: [], headers_y: [], **options)
    return dir_tree(entries) if options.fetch(:dir_tree, false)

    data = case axis
           when :x
             entries.dup
           when :y
             entries.dup.transpose
           end
    construct_table(data, headers_x.dup, headers_y.dup)
  end
end
