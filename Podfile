platform :ios, '7.0'
pod 'RNCryptor',			'~> 2.1'
pod 'FMDB', 				'~> 2.1'
pod 'SBJson', 				'~> 3.2'
pod 'HockeySDK', 			'~> 3.5.0rc2'
pod 'libPhoneNumber-iOS',		'~> 0.5.7.1'
pod 'AFNetworking', 			'~> 2.0.1'
pod 'PonyDebugger', 			'~> 0.3.0'
pod 'SQLCipher', 			'~> 2.1.1'
pod 'GoogleProtobuf', 			'~> 2.5.0'
pod 'TITokenField', 			'~> 0.9.5'
post_install do |lib_rep|
  lib_rep.project.targets.each do |target|
    if target.name == 'Pods-FMDB'
      target.build_configurations.each do |config|
        if config.build_settings['OTHER_CFLAGS'].nil?
          config.build_settings['OTHER_CFLAGS'] = Array.new
        end
        puts "Added -DSQLITE_HAS_CODEC CFlag to #{target.name} - #{config.name}"
        config.build_settings['OTHER_CFLAGS'].unshift('-DSQLITE_HAS_CODEC')
      end
    end
  end
end

