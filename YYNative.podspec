#
# Be sure to run `pod lib lint YYNative.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'YYNative'
  s.version          = '0.1.0'
  s.summary          = 'IOS Native functions for Web.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
      '这是一个向网页提供部分原生功能的框架，包括相机，扫码，图片等功能‘
                      DESC

  s.homepage         = 'https://github.com/jiangyangdadao/YYNative'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'JYY' => '1059791307@qq.com' }
  s.source           = { :git => 'https://github.com/jiangyangdadao/YYNative.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'

  s.source_files = 'YYNative/Classes/**/*'
  s.swift_versions        = ['5.0', '5.1', '5.2']
  # s.resource_bundles = {
  #   'YYNative' => ['YYNative/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'ZLPhotoBrowser'
end
