
== V2.1.11
* Case insensitive discount code
* Catch more active shipping response errors

== V2.1.2
* bug fix to the thank you page token generation.
* set all swell_ecom public controllers to use swell_ecom/application as the default layout

== V2.1.1
* Fix to the discount service code, so it will calculate discounts despite order errors

== V2.1.0
* Add item relations in subscription_plans
* add ability for customers to put their subs on hold and re-activate them.
* Add a renewal failure email
* Fixed rollup calculations on orders
* Migrating
  * update swell_ecom.rb initializer to user nexus_addresses (previously nexus_address)
  * run> rake db:migrate
  * run> rake swell_ecom:migrate_subscription_customizations
  * run> rake swell_ecom:recalculate_order_rollups
