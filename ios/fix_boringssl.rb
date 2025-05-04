#!/usr/bin/env ruby

require 'xcodeproj'

# Path to the Pods.xcodeproj
project_path = 'Pods/Pods.xcodeproj'

# Open the project
project = Xcodeproj::Project.open(project_path)

# Find the BoringSSL-GRPC target
boring_ssl_target = project.targets.find { |target| target.name == 'BoringSSL-GRPC' }

if boring_ssl_target
  puts "Found BoringSSL-GRPC target, updating build settings..."
  
  # Iterate through all build configurations for this target
  boring_ssl_target.build_configurations.each do |config|
    # Get the current 'OTHER_CFLAGS' setting
    current_cflags = config.build_settings['OTHER_CFLAGS']
    
    # Replace -G flag if it exists
    if current_cflags
      if current_cflags.is_a?(Array)
        # If it's an array, remove the '-G' element
        config.build_settings['OTHER_CFLAGS'] = current_cflags.reject { |flag| flag == '-G' }
      elsif current_cflags.is_a?(String)
        # If it's a string, remove '-G' pattern
        config.build_settings['OTHER_CFLAGS'] = current_cflags.gsub(/-G\b/, '')
      end
    end
    
    # Explicitly set flag values we know are safe
    config.build_settings['OTHER_CFLAGS'] = '$(inherited) -fno-omit-frame-pointer -fvisibility=hidden -Os'
    
    puts "Updated build settings for #{config.name} configuration"
  end
  
  # Save the project
  project.save
  puts "Project saved successfully."
else
  puts "BoringSSL-GRPC target not found!"
end 