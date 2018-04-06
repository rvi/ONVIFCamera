#
# Be sure to run `pod lib lint ONVIFCamera.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ONVIFCamera'
  s.version          = '1.1.7'
  s.summary          = 'This library helps to connect to an ONVIFCamera and view its live stream.'

  s.description      = <<-DESC
This library ease the connection to an ONVIF camera. The methods `getDeviceInformation`, `getProfiles` and
`getStreamUri` are implemented. It uses SOAPEngine to connect to the camera and retrieve data. SOAPEngine is not open source,
and a licence is required to be used on an iPhone device (not on the simulator).
                       DESC

  s.homepage         = 'https://github.com/rvi/ONVIFCamera'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rvi' => 'remy@virin.us' }
  s.source           = { :git => 'https://github.com/rvi/ONVIFCamera.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/remyvirin'
  s.screenshot  = 'https://github.com/rvi/ONVIFCamera/blob/master/images/screenshot.png?raw=true'
  s.ios.deployment_target = '9.3'

  s.source_files = 'ONVIFCamera/Classes/**/*', 'ONVIFCamera/SOAPEngine/SOAPEngine64.framework/Headers/*.h'

  s.library = 'xml2'
  s.vendored_frameworks = 'ONVIFCamera/SOAPEngine/SOAPEngine64.framework'
  s.public_header_files = 'ONVIFCamera/SOAPEngine/SOAPEngine64.framework/Headers/*.h'
end
