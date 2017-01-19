# desc "Explaining what the task does"
namespace :swell_ecom do
	task :install do
		puts "installing"

		prefix = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
		source = File.join( Gem.loaded_specs["swell_ecom"].full_gem_path, "lib/tasks/install_files", 'swell_ecom_migration.rb' )

		target = File.join( Rails.root, 'db/migrate', "#{prefix}_swell_ecom_migration.rb" )
		
		FileUtils.cp_r source, target 
		
	end
end
