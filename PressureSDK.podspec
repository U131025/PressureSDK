#
# Be sure to run `pod lib lint PressureSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PressureSDK'
  s.version          = '0.1.0'
  s.summary          = 'A short description of PressureSDK.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
PressureSDK
                       DESC

  s.homepage         = 'https://github.com/U131025/PressureSDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'PressureSDK' => 'mojingyufly@163.com' }
  s.source           = { :git => 'https://github.com/U131025/PressureSDK.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'PressureSDK/Classes/**/*'
  s.requires_arc = true

  s.dependency 'RxBluetoothKit'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'Then'

  s.frameworks = 'AVFoundation'

end
