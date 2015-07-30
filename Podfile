platform :ios, '7.0'

link_with ['TextSecureiOS', 'TextSecureiOS Tests']

pod 'RNCryptor',                 '~> 2.1'
pod 'FMDB',                      '~> 2.3'
pod 'HockeySDK',                 '~> 3.5.5'
pod 'libPhoneNumber-iOS',        '~> 0.7.3'
pod 'AFNetworking',              '~> 2.3.1'
pod 'SQLCipher', 		 '~> 3.1.0'
pod 'GoogleProtobuf', 		 '~> 2.5.0'
pod 'SWTableViewCell',       	 '~> 0.3.0'
pod 'curve25519-donna',          '~> 1.2.1'
pod 'UIImage-Categories',        '~> 0.0.1'
pod 'JSMessagesViewController',  '~> 3.4.4'
pod 'LBGIFImage',		            '~> 0.0.1'
pod 'Emoticonizer',		          '~> 1.0.0'
pod 'InAppSettingsKit',		      '~> 2.1'
pod 'HKDFKit',                   '~> 0.0.1'
pod 'RMStepsController',         '~> 1.0.1'
pod 'Navajo',                    '~> 0.0.1'
pod 'SocketRocket', :podspec => "Podspecs/SocketRocket.podspec"

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
