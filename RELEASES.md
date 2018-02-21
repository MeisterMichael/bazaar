
== V2.1.0
* Add item relations in subscription_plans
* add ability for customers to put their subs on hold and re-activate them.
* Migrating
  * update swell_ecom.rb initializer to user nexus_addresses (previously nexus_address)
  * run> rake db:migrate
  * run> rake swell_ecom:migrate_subscription_customizations
