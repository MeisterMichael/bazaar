module SwellEcom

	module TransactionServices

		class AuthorizeDotNetTransactionService < SwellEcom::TransactionService

			def initialize( args = {} )
			end

			def cancel_subscription( subscription )
				# @todo
			end

			def process( order, args = {} )
				self.calculate( order )
				return false if order.errors.present?

				# @todo
				throw Exception.new('@todo AuthorizeDotNetTransactionService#process')
				# process subscription if order includes a plan

				return false

			end

			def refund( args = {} )
				# @todo
				throw Exception.new('@todo AuthorizeDotNetTransactionService#refund')

				begin

					transaction = Transcation.new( args )
					transaction.transaction_type	= 'refund'
					transaction.provider			= 'Authorize.net'
					transaction.currency			||= transaction.parent.try(:currency)


					# @todo process


					transaction.reference_code		= nil
					transaction.status				= 'approved'

					return transaction

				rescue Exception => e

				end

				return false

			end

			def update_subscription( subscription )
				# @todo
			end

		end

	end

end
