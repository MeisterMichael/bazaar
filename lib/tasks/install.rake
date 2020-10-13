# desc "Explaining what the task does"
namespace :bazaar_core do
	task :install do
		puts "installing"

		file_paths = Dir.glob File.join( Gem.loaded_specs["bazaar_core"].full_gem_path, "lib/tasks/install_files/*" )
		prefix = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i

		file_paths.each_with_index do |source,index|

			if source.include? 'migration.rb'
				target_basename = File.basename( source ).gsub(/^[0-9]+_/,"")
				target = File.join( Rails.root, 'db/migrate', "#{prefix+index}_#{target_basename}" )

				puts "#{source}\n-> #{target}\n"
				FileUtils.cp_r source, target
			end

		end

		files = {
			'bazaar_core.rb' => 'config/initializers',
		}

		files.each do |source_file_path,destination_path|
			source_file_name = File.basename(source_file_path)
			source = File.join( Gem.loaded_specs["bazaar_core"].full_gem_path, "lib/tasks/install_files", source_file_path )
			target = File.join( Rails.root, destination_path, source_file_name )

			FileUtils.cp_r source, target

			puts "#{source}\n-> #{target}\n"
		end


		Rake::Task["bazaar_core:swell_ecom_to_bazaar_install"].invoke

	end

end
