module BazaarCore
  module ApplicationHelper
		def humanize_first
			return lambda { |e| e.first.humanize.titleize }
		end
  end
end
