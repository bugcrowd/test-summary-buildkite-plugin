# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  class Truncater
    attr_reader :max_size, :max_truncate

    def initialize(max_size:, max_truncate:, &blk)
      @max_size = max_size
      @max_truncate = max_truncate
      @blk = blk
      @_truncations = {}
    end

    def markdown
      requested = with_truncation(nil)
      if requested.empty? || requested.bytesize < max_size
        # we can use it as-is, no need to truncate
        return requested
      end
      puts "Markdown is too large (#{requested.bytesize} B > #{max_size} B), truncating"

      # See http://ruby-doc.org/core/Array.html#method-i-bsearch
      #
      # The block must return false for every value before the result
      # and true for the result and every value after
      best_truncate = (0..max_truncate).to_a.reverse.bsearch do |truncate|
        puts "Test truncating to #{truncate}: bytesize=#{with_truncation(truncate).bytesize}"
        with_truncation(truncate).bytesize <= max_size
      end
      if best_truncate.nil?
        # If we end up here, we failed to find a valid truncation value
        # ASAICT this should never happen but if it does, something is very wrong
        # so ask the user to let us know
        return nil
      end
      puts "Optimal truncation: #{best_truncate}"
      with_truncation(best_truncate)
    end

    private

    def with_truncation(truncate)
      @_truncations[truncate] ||= @blk.call(truncate)
    end
  end
end
