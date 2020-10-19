
module BazaarAdmin
	class TransactionAdminController < BazaarAdmin::EcomAdminController
		require 'csv'

		def create
			@transaction = BazaarCore::Transaction.new( get_transaction_attributes )

			if @transaction.save
				set_flash "Transaction created"
				if params[:success_redirect_path]
					redirect_to params[:success_redirect_path]
				else
					redirect_back fallback_location: '/admin'
				end
			else
				set_flash "Unable to create transaction", :danger, @transaction
				if params[:failure_redirect_path]
					redirect_to params[:failure_redirect_path]
				else
					redirect_back fallback_location: '/admin'
				end
			end

		end

		def destroy
			@transaction = BazaarCore::Transaction.find params[:id]

			if @transaction.destroy
				set_flash "Transaction deleted"
			else
				set_flash "Unable to delete transaction", :danger, @transaction
			end
			redirect_back fallback_location: '/admin'
		end

		def edit
			@transaction = BazaarCore::Transaction.find( params[:id] )
		end

		def index
			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'

			@providers = BazaarCore::Transaction.where.not( provider: nil ).pluck( :provider ).uniq

			@transactions = BazaarCore::Transaction.order( "#{sort_by} #{sort_dir}" )

			start_date = params[:start_date]
			end_date = params[:end_date] || Time.now.end_of_day

			@transactions = @transactions.where( created_at: start_date..end_date ) if start_date.present? && end_date.present?

			amount = params[:amount].gsub( /\D/, '' ) if params[:amount].present?
			@transactions = @transactions.where( amount: amount ) if amount.present?

			@transactions = @transactions.where( status: params[:status] ) if params[:status].present?

			@transactions = @transactions.where( transaction_type: params[:transaction_type] ) if params[:transaction_type].present?

			@transactions = @transactions.where( provider: params[:provider] ) if params[:provider].present?

			@transactions = @transactions.where( credit_card_ending_in: params[:credit_card_ending_in] ) if params[:credit_card_ending_in].present?

			@transactions = @transactions.where( "reference_code like :code", code: "%#{params[:reference_code]}%" ) if params[:reference_code].present?

			@total_amount = @transactions.sum( :amount )

			if request.format.to_s == 'text/csv'
				attributes = %w{ provider reference_code amount type last4 created_at status }
				@csv = CSV.generate( headers: true ) do |csv|
					csv << attributes
					@transactions.each do |transaction|
						csv << [ transaction.provider, transaction.reference_code, transaction.amount_formatted, transaction.transaction_type, transaction.properties['credit_card_ending_in'], transaction.created_at, transaction.status ]
					end
				end
			end

			@transactions = @transactions.page( params[:page] )

			respond_to do |format|
				format.html
				format.csv { send_data @csv, filename: "transactions-#{Date.today}.csv" }
			end

		end

		def new
			@transaction = BazaarCore::Transaction.new( get_transaction_attributes )
		end

		protected

		def get_transaction_attributes
			attributes = params.require(:transaction).permit(
				:parent_obj_type,
				:parent_obj_id,
				:transaction_type,
				:provider,
				:reference_code,
				:customer_profile_reference,
				:customer_payment_profile_reference,
				:amount,
				:amount_as_money,
				:currency,
				:status,
				:message,
				:credit_card_ending_in,
				:credit_card_brand,
				:billing_address_id,
			)
			attributes
		end

	end
end
