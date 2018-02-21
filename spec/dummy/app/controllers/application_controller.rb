class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

	helper SwellMedia::Engine.helpers
	include SwellAnalytics::ApplicationHelper if defined?( SwellAnalytics )

	before_action :set_page_meta
end
