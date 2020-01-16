== 4.8.1
* Allow multiple discount items to be editable from discount admin

== 4.8.0
* Discount admin tool tips


== 4.4.0
* only sum not_negative_status shipments during order calculation


== 0.7.0 Bazaar
* Updating authorize.net to use the more recent version of their api.


== 2.13.0
* Order refactor


== 2.12.0
* Subscription shipping preferences

== V2.7.0
* Send Order.ip address to authorize.net
* Attach failed transactions to users
* Set email and first name on cart_item post
* Quantity or equals one on cart_item post

== V2.7.0
* Send Order.ip address to authorize.net
* Attach failed transactions to users
* Set email and first name on cart_item post
* Quantity or equals one on cart_item post

== V2.6.7
* add cached_uses to discounts

== V2.6.6
* Add usage stats to discount index view table

== V2.6.5
* Add usage stats to discount edit view

== V2.6.4
* Add a one penny variance when comparing the order total to the paypal payment amount

== V2.1.11
* Case insensitive discount code
* Catch more active shipping response errors

== V2.1.2
* bug fix to the thank you page token generation.
* set all bazaar public controllers to use bazaar/application as the default layout

== V2.1.1
* Fix to the discount service code, so it will calculate discounts despite order errors

== V2.1.0
* Add item relations in subscription_plans
* add ability for customers to put their subs on hold and re-activate them.
* Add a renewal failure email
* Fixed rollup calculations on orders
* Migrating
  * update bazaar.rb initializer to user nexus_addresses (previously nexus_address)
  * run> rake db:migrate
  * run> rake bazaar:migrate_subscription_customizations
  * run> rake bazaar:recalculate_order_rollups
