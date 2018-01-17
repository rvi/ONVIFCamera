#
# Be sure to run `pod lib lint ONVIFCamera.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ONVIFCamera'
  s.version          = '0.1.0'
  s.summary          = 'this library helps to connect to a ONVIFCamera and view its live stream.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/rvi/ONVIFCamera'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rvi' => 'remy@virin.us' }
  s.source           = { :git => 'https://github.com/rvi/ONVIFCamera.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/remyvirin'

  s.ios.deployment_target = '8.0'

  s.source_files = 'ONVIFCamera/Classes/**/*', 'ONVIFCamera/SOAPEngine/SOAPEngine64.framework/Headers/*.h'
  
  # s.resource_bundles = {
  #   'ONVIFCamera' => ['ONVIFCamera/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.library = 'xml2'
  s.vendored_frameworks = 'ONVIFCamera/SOAPEngine/SOAPEngine64.framework'
  s.public_header_files = 'ONVIFCamera/SOAPEngine/SOAPEngine64.framework/Headers/*.h'
end
