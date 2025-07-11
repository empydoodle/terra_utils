#!/usr/bin/env ruby
# frozen_string_literal: true

module TerraUtils
  module Setup
    # Helpers to populate config from user input
    module SetupHelpers
      ESCAPE_STRING = '!X!'

      def user_config_options(ref:, selected: [], options: [], ind: 2, **args)
        say_("Setting up #{ref} options...", ind)
        valid_options = options.dup.reject { |o| selected.include?(o) }
        selected = [selected, prompt_user(valid_options, ref: ref, ind: ind, **args)].flatten.compact.uniq
        raise SetupError, 'Must specify at least 1 option!' if selected.empty? && !args.fetch(:allow_empty, false)

        if prompt_additional_configs(ref: ref, selected_options: selected, ind: ind, **args)
          user_config_options(ref: ref, selected: selected, options: options, is_retry: true, **args, ind: ind)
        else
          args.fetch(:single, false) ? selected.first : selected
        end
      rescue SetupError => e
        error_("Not allowed: #{e.message}", ind)
        retry
      end

      def prompt_user(valid_options, is_retry: false, ind: 2, **args)
        return select_from_options(valid_options, ind: ind, **args) unless valid_options.empty?

        prompt_args = { prompt_ref: args.fetch(:ref, nil), with_escape: is_retry }
        user_option_prompt(**args.merge(prompt_args), ind: ind)
      end

      def select_from_options(options, ind: 2, **args)
        return [] unless options.is_a?(Array) && !options.empty? || args.fetch(:with_custom, true)

        say_(build_option_select_prompt(single: args.fetch(:single, false)), ind, :bold)
        table_(**prepare_options_table(options, **args), indent: ind + 1)
        selections = user_option_selections(options, **args, ind: ind)
        resolve_option_select(selections, options, **args, ind: ind)
      rescue SetupError => e
        error_(e.message, ind)
        retry
      end

      def build_option_select_prompt(single: false)
        [
          "Please select the corresponding number#{'(s)' unless single}",
          "of the option#{'(s)' unless single}",
          'you want to use',
          ('in a space-separated string (e.g. "0 1 2")' unless single)
        ].compact.join(' ') << ':'
      end

      def prepare_options_table(options, with_custom: true, allow_empty: false, with_escape: false, **_)
        additional_options = [
          (["#{options.size}+", 'Custom / Manual Entry [prompt user for option(s)]'] if with_custom),
          ([ESCAPE_STRING, '[Exit option selection]'] if allow_empty || with_escape)
        ].compact.to_h

        {
          headers_y: options.each_index.to_a.map(&:to_s).push(additional_options.keys).flatten.compact,
          entries: [options.dup.push(additional_options.values).flatten.compact]
        }
      end

      def user_option_selections(options, with_custom: true, single: false, ind: 2, **_)
        range      = with_custom ? options.size : options.size - 1
        prompt     = [0, range].compact.uniq.join('-')
        response   = ask_(["(#{prompt})", ('[limit: 1]' if single)].compact.join(' '), ind).split
        raise SetupError, 'Too many options selected! (limit: 1))' if single && response.size > 1

        response
      end

      def resolve_option_select(selections, options, with_custom: true, ind: 3, **args)
        return [] if selections.empty? || selections.first == ESCAPE_STRING

        selections.flatten.map do |s|
          options.fetch(s.to_i)
        rescue IndexError
          raise SetupError, "Please select from valid options (0...#{options.size - 1})" unless with_custom

          user_option_prompt(**args.merge({ prompt_ref: 'custom', with_escape: true, ind: ind }))
        end.compact
      end

      def user_option_prompt(allow_empty: false, with_escape: false, delimiter: nil, ind: 3, **args)
        eg       = "(#{args.delete(:prompt_eg)})" if options.fetch(:prompt_eg, nil)
        prompt   = [args.delete(:prompt_override) || ['Please enter a', args.delete(:prompt_ref), 'config option', eg]]
        prompt  << "(enter \"#{ESCAPE_STRING}\" to cancel)" if allow_empty || with_escape
        response = ask_(prompt.flatten.compact.join(' '), ind, **args)
        return nil if with_escape && response == ESCAPE_STRING || response.empty?

        delimiter ? response.split(delimiter).map(&:strip).reject(&:empty?) : response
      end

      def user_switch_prompt(prompt_ref: nil, prompt_override: nil, method: :yes_?, ind: 3, **args)
        prompt = prompt_override || ['Enable ', prompt_ref, '?'].join
        public_send(method.to_sym, prompt, ind, **args)
      end

      def prompt_additional_configs(ref:, selected_options: [], ind: 2, **args)
        return false if args.fetch(:single, false)

        say_("Selected #{ref} values:", ind, :leading_br)
        if selected_options.empty?
          say_('[none]', ind + 1, :parag)
        else
          headers    = args.fetch(:list_index, false) ? selected_options.each_index.to_a : []
          table_args = { headers_y: headers, borders: true, dir_tree: args.fetch(:dir_tree, false) }
          table_(entries: [selected_options], **table_args, indent: ind + 1)
        end
        yes_?("Add more #{ref} options?", ind, :trailing_br)
      end
    end
  end
end
