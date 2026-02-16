# CLAUDE.md - Bazaar Engine

## Purpose

Bazaar is a full-featured e-commerce Rails engine providing products, offers, orders, subscriptions, carts, checkout, fulfillment, shipping, tax, and discount functionality. It is the core commerce layer for Neurohacker Collective.

**Version:** See `lib/bazaar/version.rb`

## Key Models

### Products & Offers

- **`Bazaar::Product`** / **`Bazaar::RootProduct`** / **`Bazaar::SubProduct`**
  - `enum status`: `draft: 0`, `active: 1`, `archive: 2`, `trash: 3`
  - `enum availability`: `backorder: -1`, `pre_order: 0`, `open_availability: 1`
  - `enum package_shape`: `no_shape: 0`, `letter: 1`, `box: 2`, `cylinder: 3`
  - `enum listing_offer_mode`: `custom: 0`, `single_plus_subscription: 1`, `subscription_only: 2`, `single_only: 3`
  - Associations: `has_many :offers`, `has_many :product_relationships`, FriendlyId slugs, taggable, ActiveStorage attachments (avatar, gallery, embedded)

- **`Bazaar::ProductVariant`** - Variants with independent inventory. Same enums as Product.

- **`Bazaar::ProductCategory`**
  - `enum status`: `draft: 0`, `active: 1`, `archive: 100`, `trash: -50`
  - `enum availability`: `anyone: 1`, `logged_in_users: 2`, `just_me: 3`

- **`Bazaar::Offer`** - Purchasable offers (one-time or recurring subscription)
  - `enum status`: `draft: 0`, `active: 1`, `archive: 2`, `trash: 3`
  - `enum availability`: `backorder: -1`, `pre_order: 0`, `open_availability: 1`
  - Associations: `belongs_to :product`, `has_many :offer_prices`, `has_many :offer_schedules`, `has_many :offer_skus`
  - Key methods: `price_for_interval()`, `recurring?()`, `initial_price`, `renewal_price`

- **`Bazaar::OfferPrice`** / **`Bazaar::OfferSchedule`** / **`Bazaar::OfferSku`**
  - `enum status`: `trash: -1`, `active: 1`
  - OfferSku `enum apply`: `per_quantity: 1`, `per_order: 2`
  - These use polymorphic `parent_obj` so they can belong to Offer or Subscription

### Orders & Checkout

- **`Bazaar::Order`** (base) / **`Bazaar::CheckoutOrder`** / **`Bazaar::FulfillmentOrder`** / **`Bazaar::WholesaleOrder`**
  - `enum status`: `trash: -99`, `rejected: -5`, `failed: -1`, `draft: 0`, `pre_order: 1`, `active: 2`, `review: 98`, `archived: 99`, `hold_review: 110`
  - `enum payment_status`: `payment_failed: -4`, `payment_canceled: -3`, `declined: -2`, `refunded: -1`, `invoice: 0`, `payment_method_captured: 1`, `paid: 2`
  - `enum fulfillment_status`: `fulfillment_canceled: -3`, `fulfillment_error: -1`, `unfulfilled: 0`, `partially_fulfulled: 1`, `fulfilled: 2`, `delivered: 3`, `return_to_sender: 4`
  - `enum generated_by`: `customer_generated: 1`, `system_generaged: 2`
  - Associations: `belongs_to :user`, `has_many :order_items`, `has_many :order_offers`, `has_many :shipments`, `has_many :transactions`
  - Money attributes: subtotal, tax, shipping, total, discount

- **`Bazaar::OrderItem`**
  - `enum order_item_type`: `prod: 1`, `tax: 2`, `shipping: 3`, `discount: 4`
  - `belongs_to :item` (polymorphic)

- **`Bazaar::OrderOffer`** - Order-offer relationship with subscription tracking
  - `belongs_to :offer`, `belongs_to :subscription`, `has_many :order_offer_discounts`

- **`Bazaar::OrderLog`**
  - `enum log_type`: `critical: -300`, `error: -200`, `warning: -100`, `debug: 0`, `info: 100`, `success: 200`

### Cart

- **`Bazaar::Cart`**
  - `enum status`: `active: 1`, `init_checkout: 2`, `success: 3`
  - `has_many :cart_offers`, `belongs_to :order`, `belongs_to :user`, `belongs_to :discount`

- **`Bazaar::CartOffer`** - Offers in cart (similar to OrderOffer)

### Subscriptions

- **`Bazaar::Subscription`**
  - `enum status`: `trash: -99`, `rejected: -5`, `on_hold: -2`, `canceled: -1`, `failed: 0`, `active: 1`, `review: 98`, `hold_review: 110`
  - Associations: `belongs_to :user`, `belongs_to :offer`, `has_many :subscription_offers`, `has_many :order_offers`, `has_many :subscription_logs`
  - Key methods: `ready_for_next_charge?()`, `next_subscription_interval()`, `price_for_interval()`
  - Timestamps: start_at, current_period_start_at, current_period_end_at, next_charged_at, canceled_at

- **`Bazaar::SubscriptionOffer`**
  - `enum status`: `trash: -200`, `canceled: -100`, `draft: 0`, `active: 100`

- **`Bazaar::SubscriptionPlan`** - Blueprint for subscriptions (like offers but for subscription context)

### Fulfillment & Shipping

- **`Bazaar::Shipment`**
  - `enum status`: `processing_error: -900`, `rejected: -100`, `canceled: -1`, `draft: 0`, `pending: 10`, `processing: 50`, `picking: 100`, `packed: 200`, `shipped: 300`, `delivered: 400`, `lost_in_transit: 450`, `returned: 500`, `review: 900`, `hold_review: 950`
  - Associations: `belongs_to :order`, `belongs_to :warehouse`, `has_many :shipment_skus`, `has_many :shipment_logs`

- **`Bazaar::ShippingOption`** - Available shipping methods
  - `enum status`: `trash: -2`, `inactive: -1`, `draft: 0`, `active: 1`

- **`Bazaar::ShippingCarrierService`** - Carrier + service level combinations
  - `enum status`: `inactive: -1`, `draft: 0`, `active: 1`

### Inventory

- **`Bazaar::Sku`**
  - `enum status`: `trash: -1`, `draft: 0`, `active: 100`
  - `enum country_restriction_type`: `countries_blacklist: -1`, `countries_unrestricted: 0`, `countries_whitelist: 1`
  - `enum state_restriction_type`: `states_blacklist: -1`, `states_unrestricted: 0`, `states_whitelist: 1`
  - `enum shape`: `no_shape: 0`, `letter: 1`, `box: 2`, `cylinder: 3`

- **`Bazaar::Warehouse`** - Fulfillment center with geo restrictions
  - `enum status`: `trash: -1`, `draft: 0`, `active: 100`

- **`Bazaar::WarehouseSku`** - SKU inventory at specific warehouse

### Payments

- **`Bazaar::Transaction`**
  - `enum transaction_type`: `void: -3`, `chargeback: -2`, `refund: -1`, `preauth: 0`, `charge: 1`
  - `enum status`: `declined: -1`, `approved: 1`
  - `belongs_to :parent_obj` (polymorphic: Order or Subscription)
  - Money attributes: amount, signed_amount

### Discounts

- **`Bazaar::Discount`** (base) / **`Bazaar::CouponDiscount`** / **`Bazaar::HouseCouponDiscount`** / **`Bazaar::PartnerCouponDiscount`** / **`Bazaar::PromotionDiscount`**
  - `enum status`: `archived: -1`, `draft: 0`, `active: 1`
  - `enum availability`: `anyone: 1`, `selected_users: 2`
  - `has_many :discount_items`, `has_many :discount_users`

- **`Bazaar::DiscountItem`**
  - `enum order_item_type`: `all_order_item_types: 0`, `prod: 1`, `tax: 2`, `shipping: 3`, `discount: 4`
  - `enum discount_type`: `percent: 1`, `fixed: 2`, `fixed_each: 3`

### Collections & Upsells

- **`Bazaar::Collection`**
  - `enum status`: `trash: -1`, `draft: 0`, `active: 1`, `archived: 2`
  - `enum collection_type`: `list_type: 1`, `query_type: 2`

- **`Bazaar::Upsell`** / **`Bazaar::UpsellOffer`**
  - `enum upsell_type`: `post_sale: 1`, `at_checkout: 2`, `exit_checkout: 3`

### Wholesale

- **`Bazaar::WholesaleProfile`** / **`Bazaar::WholesaleItem`**

## Model Concerns

- **MoneyAttributesConcern** - All monetary fields stored as integers (cents). Provides `*_as_money` and `*_formatted` accessors.
- **UserAddressAttributesConcern** - Nested address attribute handling for billing/shipping
- **MediaConcern** - Media/attachment handling

## Key Services

### Order Processing

- **`Bazaar::OrderService`** - Abstract base for order processing. Orchestrates shipping, discount, tax, and transaction calculations. Injects all dependent services.
- **`Bazaar::CheckoutOrderService`** - Specializes OrderService for checkout flow
- **`Bazaar::WholesaleOrderService`** - B2B order processing

### Subscription Management

- **`Bazaar::SubscriptionService`** - Subscription lifecycle: `subscribe()`, `subscribe_ordered_plans()`, handles pricing intervals and billing cycles

### Discount Calculation

- **`Bazaar::DiscountService`** - Two-phase discount calculation: `calculate_pre_tax()` and `calculate_post_tax()`. Handles validation, minimum purchase requirements, usage limits, subscription eligibility.

### Shipping

- **`Bazaar::ShippingService`** - Rate calculation and assignment with configurable adjustments
- **`Bazaar::ShippingServices::ActiveShippingService`** - Base active_shipping gem integration
- **`Bazaar::ShippingServices::UpsShippingService`** - UPS carrier
- **`Bazaar::ShippingServices::UspsShippingService`** - USPS carrier
- **`Bazaar::ShippingServices::DhlShippingService`** - DHL carrier

### Tax

- **`Bazaar::TaxService`** - Abstract base
- **`Bazaar::TaxServices::TaxJarTaxService`** - TaxJar integration

### Payments

- **`Bazaar::TransactionService`** - Abstract base for payment processing
- **`Bazaar::TransactionServices::StripeTransactionService`** - Stripe (default)
- **`Bazaar::TransactionServices::AuthorizeDotNetTransactionService`** - Authorize.net
- **`Bazaar::TransactionServices::PayPalExpressCheckoutTransactionService`** - PayPal Express
- **`Bazaar::TransactionServices::AmazonPayTransactionService`** - Amazon Pay

### Other Services

- **`Bazaar::FraudService`** - Fraud risk assessment (abstract)
- **`Bazaar::UpsellService`** - Upsell offer presentation and conversion tracking
- **`Bazaar::ProductService`** - Product data retrieval and search
- **`Bazaar::EcomSearchService`** - Elasticsearch integration for product/offer search

## Key Controllers

### Public

- **`CheckoutController`** - Checkout flow: new, create, index, calculate, confirm, state_input
- **`CartOffersController`** - Add/remove offers from cart
- **`CartsController`** - Cart management
- **`OrdersController`** - Customer order view with thank_you

### Customer Account

- **`YourAccountController`** - User account page
- **`YourOrdersController`** - Customer order history
- **`YourSubscriptionsController`** - Subscription management (update, cancel, edit shipping)

### Wholesale

- **`WholesaleCheckoutController`** - B2B checkout

### Admin (extensive)

Product: `ProductAdminController`, `ProductCategoryAdminController`, `ProductRelationshipAdminController`
Offers: `OfferAdminController`, `OfferPriceAdminController`, `OfferScheduleAdminController`, `OfferSkuAdminController`
Orders: `OrderAdminController`, `OrderItemAdminController`, `OrderOfferAdminController`
Subscriptions: `SubscriptionAdminController`, `SubscriptionOfferAdminController`
Shipping: `ShipmentAdminController`, `ShipmentSkuAdminController`, `FulfillmentAdminController`, `ShippingOptionAdminController`, `ShippingCarrierServiceAdminController`
Inventory: `SkuAdminController`, `WarehouseAdminController`, `WarehouseSkuAdminController`
Discounts: `DiscountAdminController`
Collections: `CollectionAdminController`, `CollectionItemAdminController`
Upsells: `UpsellAdminController`, `UpsellOfferAdminController`
Transactions: `TransactionAdminController`

### Controller Concerns

- **CartConcern** - Cart-related helper methods
- **CheckoutConcern** - Checkout flow helpers and validations
- **EcomConcern** - General e-commerce helpers
- **MediaAdminControllerConcern** / **MediaControllerConcern** - Media/attachment handling

## Configuration

All service classes and behavior are configurable via `Bazaar.configure`:

```ruby
Bazaar.configure do |config|
  # Service classes (all swappable)
  config.checkout_order_service_class = "Bazaar::CheckoutOrderService"
  config.discount_service_class = "Bazaar::DiscountService"
  config.fraud_service_class = "Bazaar::FraudService"
  config.shipping_service_class = "Bazaar::ShippingService"
  config.subscription_service_class = "Bazaar::SubscriptionService"
  config.tax_service_class = "Bazaar::TaxService"
  config.transaction_service_class = "Bazaar::TransactionServices::StripeTransactionService"
  config.upsell_service_class = "Bazaar::UpsellService"
  config.product_service_class = "Bazaar::ProductService"
  config.search_service_class = "Bazaar::EcomSearchService"

  # Feature flags
  config.automated_fulfillment = false
  config.create_user_on_checkout = false
  config.enable_checkout_order_mailer = true
  config.enable_wholesale_order_mailer = true

  # Business configuration
  config.store_path = 'store'
  config.origin_address = { ... }
  config.nexus_addresses = [ ... ]

  # Discount types
  config.discount_types = {
    'House Coupon' => 'Bazaar::HouseCouponDiscount',
    'Partner Coupon' => 'Bazaar::PartnerCouponDiscount',
    'Promotion' => 'Bazaar::PromotionDiscount'
  }
end
```

## Key Patterns

1. **Service Injection** - OrderService injects all dependent services (fraud, shipping, tax, transaction, discount). Makes services testable and swappable.
2. **Interval-Based Pricing** - Offers support multiple pricing intervals (initial price vs renewal price for subscriptions).
3. **Money as Integers** - All monetary fields stored in cents via MoneyAttributesConcern.
4. **Cart -> Order -> Subscription Flow** - Cart holds temporary state, Checkout converts to Order, OrderService creates Subscriptions for recurring offers.
5. **Two-Phase Discount** - Discounts calculated pre-tax and post-tax separately.
6. **Polymorphic Associations** - Transaction.parent_obj can be Order or Subscription. OrderItem.item can be any sellable object.

## Dependencies

- `jbuilder` - JSON API response building
- `pulitzer` - Content management engine
- `swell_id` - User identity and authentication engine
- `rest-client` - HTTP client for API calls
- `credit_card_validations` - Credit card validation

## Routes

- Shopping: `/cart`, `/cart_offers`, `/checkout`
- Account: `/your_account`, `/your_orders`, `/your_subscriptions`, `/orders`
- Admin: Standard REST routes for all admin controllers
- Special: `/checkout/calculate` (POST), `/checkout/confirm` (POST/GET)
