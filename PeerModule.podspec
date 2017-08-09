#
# Be sure to run `pod lib lint PeerModule.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PeerModule'
  s.version          = '0.1.0'
  s.summary          = 'A small module to create a peer network.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/ThibaultTourailles/PeerModule'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Thibault Tourailles' => 'thibault.tourailles@applidium.com' }
  s.source           = { :git => 'https://github.com/ThibaultTourailles/PeerModule.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'PeerModule/Classes/**/*'

  s.dependency 'BlueSocket', '~> 0.12'
  
  # s.resource_bundles = {
  #   'PeerModule' => ['PeerModule/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
