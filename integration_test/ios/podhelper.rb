# Integration Test iOS Configuration
def integration_test_ios_pods(installer)
  return unless installer.pods_project.targets.any? { |target| target.name == 'integration_test' }
  
  puts "Configuring integration_test framework headers..."
  
  installer.pods_project.targets.each do |target|
    if target.name == 'integration_test'
      # Make all headers public for integration_test
      target.headers_build_phase.files.each do |file|
        file.settings ||= {}
        file.settings['ATTRIBUTES'] = ['Public']
      end
      
      # Fix umbrella header imports
      umbrella_header_path = "Pods/Target Support Files/integration_test/integration_test-umbrella.h"
      if File.exist?(umbrella_header_path)
        content = File.read(umbrella_header_path)
        fixed_content = content.gsub(/#import\s+"([^"]+)"/, '#import <\1>')
        File.write(umbrella_header_path, fixed_content)
      end
      
      # Update build settings for all configurations
      target.build_configurations.each do |config|
        config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
        config.build_settings['DEFINES_MODULE'] = 'YES'
        config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'NO'
        
        # Fix for Flutter framework path
        config.build_settings['FRAMEWORK_SEARCH_PATHS'] = [
          '$(inherited)',
          '${PODS_ROOT}/../Flutter'
        ]
      end
      
      # Break out of the loop once the target is found and configured
      break
    end
  end
end 