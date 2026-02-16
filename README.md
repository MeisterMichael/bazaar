# Bazaar

A full-featured e-commerce Rails engine providing products, offers, orders, subscriptions, carts, checkout, fulfillment, shipping, tax, and discount functionality.

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation, model enums, and service references.

## Features

- Product catalog with variants, categories, and collections
- Flexible offer system with interval-based pricing (one-time and subscription)
- Full checkout flow with cart management
- Subscription lifecycle management with billing cycles
- Multi-provider payment processing (Stripe, Authorize.net, PayPal, Amazon Pay)
- Multi-carrier shipping calculation (UPS, USPS, DHL)
- Tax calculation via TaxJar
- Discount system with coupons, promotions, and partner discounts
- Multi-warehouse inventory management with geo restrictions
- Shipment tracking with full audit trail
- Upsell system (post-sale, at-checkout, exit-checkout)
- Wholesale/B2B order processing
- Elasticsearch product search integration
- Configurable service classes for all business logic

## Models Overview

| Model | Purpose |
|-------|---------|
| `Product` | Products with variants, categories, and media |
| `Offer` | Purchasable offers (one-time or subscription) with interval pricing |
| `Order` | Customer orders (CheckoutOrder, FulfillmentOrder, WholesaleOrder) |
| `Subscription` | Recurring subscriptions with billing cycle management |
| `Cart` / `CartOffer` | Shopping cart state |
| `Shipment` | Physical shipments from warehouses |
| `Transaction` | Payment transactions (charge, refund, void, chargeback) |
| `Discount` | Coupons, promotions, partner discounts |
| `Sku` / `Warehouse` / `WarehouseSku` | Inventory management |
| `Collection` | Product/offer groupings |
| `Upsell` | Upsell opportunity definitions |

## Configuration

```ruby
Bazaar.configure do |config|
  config.transaction_service_class = "Bazaar::TransactionServices::AuthorizeDotNetTransactionService"
  config.shipping_service_class = "Bazaar::ShippingService"
  config.tax_service_class = "Bazaar::TaxServices::TaxJarTaxService"
  config.origin_address = { street: '...', city: '...', state: '...', zip: '...', country: 'US' }
end
```

## Dependencies

- `swell_id` - User identity and authentication
- `pulitzer` - Content management
- `jbuilder` - JSON API responses
- `rest-client` - HTTP client
- `credit_card_validations` - Credit card validation

## Integration

- **swell_id** - User authentication and address management
- **pulitzer** - CMS content for product pages
- **bunyan** - Event tracking for e-commerce analytics
- **edison** - A/B testing for checkout experiments

## License

MIT
