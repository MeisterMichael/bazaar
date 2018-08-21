module SwellEcom
	class ZendeskController < ApplicationController
		before_action :authenticate_zendesk

		def index
			@query_string = request.query_string

			response.headers.delete('X-Frame-Options')
			render layout: false
		end

		def customer
			email = params[:email]
			phone = params[:phone]
			# @todo normalize phone number

			@user = User.find_by( email: email ) if email.present?
			@user = User.where( id: GeoAddress.where( phone: phone ).where.not( user_id: nil ).select('user_id') ).first if phone.present?

			@orders = SwellEcom::Order.where( user: @user ) if @user.present?
			@orders ||= SwellEcom::Order.where( email: email ) if email.present?
			# @orders ||= SwellEcom::Order.where( phone: phone ) if phone.present?
		end

		private
		def authenticate_zendesk
			raise ActionController::RoutingError.new('Not Found') unless ( ENV['ZEND_APP_ORIGIN'].blank? || params[:origin] == ENV['ZEND_APP_ORIGIN'] ) && ( ENV['ZEND_APP_SECRET'].blank? || params[:secret] == ENV['ZEND_APP_SECRET'] )
			raise ActionController::RoutingError.new('Not Found') unless Rails.env.development? || ENV['ZEND_APP_ID'].blank? || params[:app_guid] == ENV['ZEND_APP_ID']
		end
	end
end
