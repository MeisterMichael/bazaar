module SwellEcom

	module TransactionService

		class AuthorizeDotNetTransactionService < SwellEcom::TransactionService

			def initialize( args = {} )
			end

			def process( order, args = {} )
				self.calculate( order )
				return false if order.errors.present?

				# do something
				# process subscription if order includes a plan

				return false

			end

			def refund( order, amount, args = {} )

			end

		end

	end

end
