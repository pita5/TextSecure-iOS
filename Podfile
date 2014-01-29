platform :ios, '7.0'

link_with ['TextSecureiOS', 'TextSecureiOS Tests']

pod 'RNCryptor',			'~> 2.1'
pod 'FMDB', 				'~> 2.1'
pod 'HockeySDK', 			'~> 3.5.0rc2'
pod 'libPhoneNumber-iOS',		'~> 0.6'
pod 'AFNetworking', 			'~> 2.1.0'
pod 'PonyDebugger', 			'~> 0.3.0'
pod 'SQLCipher', 			'~> 3.0.1'
pod 'GoogleProtobuf', 			'~> 2.5.0'
pod 'TITokenField', 			'~> 0.9.5'
pod 'SWTableViewCell',       '~> 0.2.1'
pod 'curve25519-donna',       '~> 1.2.1'
pod 'UIImage-Categories',     '~> 0.0.1'

#pod 'OpenSSL',            '~> 1.0.1'
link_with ['TextSecureiOS', 'TextSecureiOS Tests']
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

