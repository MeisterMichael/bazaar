# desc "Explaining what the task does"
namespace :swell_ecom do
	task :install do
		puts "installing"

		file_paths = Dir.glob File.join( Gem.loaded_specs["swell_ecom"].full_gem_path, "lib/tasks/install_files/*" )
		prefix = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i

		file_paths.each_with_index do |source,index|

			if source.include? 'migration.rb'
				target_basename = File.basename( source ).gsub(/^[0-9]+_/,"")
				target = File.join( Rails.root, 'db/migrate', "#{prefix+index}_#{target_basename}" )

				puts "#{source}\n-> #{target}\n"
				FileUtils.cp_r source, target
			end

		end

		source = File.join( Gem.loaded_specs["swell_ecom"].full_gem_path, "lib/tasks/install_files", 'swell_ecom.rb' )
		target = File.join( Rails.root, 'config/initializers', "swell_ecom.rb" )
		puts "#{source}\n-> #{target}\n"
		FileUtils.cp_r source, target

	end

end
