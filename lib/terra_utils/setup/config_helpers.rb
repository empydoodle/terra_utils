#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    # Helpers to populate config from user input
    module ConfigHelpers
      def user_switch_prompt(prompt_ref: nil, prompt_override: nil, ind: 3, **args)
        prompt = prompt_override || ['Enable feature: ', prompt_ref, '?'].join
        yes_?(prompt, ind, **args)
      end

      def user_option_prompt(prompt_ref: nil, prompt_eg: nil, prompt_override: nil, ind: 3, **args)
        prompt_eg = "(#{prompt_eg})" if prompt_eg
        prompt    = prompt_override || ['Please enter a', prompt_ref, 'config option', prompt_eg].compact.join(' ')
        ask_(prompt, ind, **args)
      end

      def resolve_option_select(selections_arr, options_arr, with_custom: true, ind: 3, **args)
        return [] if selections_arr.empty? || selections_arr.inspect.match?(/\["[xX]"\]/)

        selections_arr.map do |s|
          selection = s.to_i
          next options_arr.fetch(selection) unless selection >= options_arr.size
          raise IndexError.new, "Please select from valid options (-1..#{options_arr.size - 1})" unless with_custom

          user_option_prompt(**args.merge({ prompt_ref: 'custom', prompt_eg: selection, escape: true, ind: ind }))
        end.compact
      end

      def prepare_options_table(options, with_custom: true, custom_entry: {})
        custom_entry = { i: "#{options.size}+", opt: 'Custom [prompt user for option(s)]' } if with_custom
        headers      = options.each_index.to_a.push(custom_entry.fetch(:i, nil)).compact
        entries      = options.dup.push(custom_entry.fetch(:opt, nil)).compact
        {
          headers_y: headers.push('X').map { |h| "#{h})" },
          entries: [entries.push('Exit option selection')]
        }
      end

      def user_option_selections(options, with_custom: true, ind: 2)
        range      = with_custom ? options.size : options.size - 1
        prompt     = [0, range].compact.uniq.join('-')
        ask_("(#{prompt})", ind).split
      end

      def select_from_options(options, with_custom: true, ind: 2, **args)
        return [] unless options.is_a?(Array) && !options.empty? || with_custom

        say_('Please select the options you want to use in a space-separated string (e.g. "0 1 2"):', ind, :bold)
        table_(**prepare_options_table(options, with_custom: with_custom), indent: ind + 1)
        selections = user_option_selections(options, with_custom: with_custom, ind: ind)
        resolve_option_select(selections, options, with_custom: with_custom, ind: ind, **args)
      rescue IndexError => e
        error_(e.message, ind)
        retry
      end

      def prompt_additional_configs(ref:, selected_options: [], list_index: false, ind: 2)
        say_("#{ref.capitalize}s selected:", ind, leading_br: true)
        if selected_options.empty?
          say_('[none]', ind + 1, leading_br: true, trailing_br: true)
        else
          table_headers = list_index ? selected_options.each_index.to_a : []
          table_(entries: [selected_options], headers_y: table_headers, indent: ind + 1, borders: true)
        end
        yes_?("Add more #{ref} options?", ind, trailing_br: true)
      end

      def user_config_options(ref:, selected: [], default: [], with_custom: true, ind: 2, **args)
        say_("Setting up #{ref} options...", ind)
        config = if default && !default.empty?
                   options = default.dup.reject { |o| selected.include?(o) }
                   select_from_options(options, with_custom: with_custom, ind: ind, **args)
                 else
                   user_option_prompt(prompt_ref: ref, ind: ind, **args)
                 end
        selected = [selected, config].flatten.uniq
        return selected unless prompt_additional_configs(ref: ref, selected_options: selected, ind: ind)

        user_config_options(ref: ref, selected: selected, default: default, with_custom: with_custom, ind: ind, **args)
      end
    end
  end
end
