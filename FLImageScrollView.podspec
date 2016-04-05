#
# Be sure to run `pod lib lint FLImageScrollView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = "FLImageScrollView"
s.version          = "0.1.3"
s.summary          = "ScrollView containing list of images."
s.homepage         = "https://github.com/felixkli/FLImageScrollView"
s.license          = 'MIT'
s.author           = { "Felix Li" => "li.felix162@gmail.com" }
s.source           = { :git => "https://github.com/felixkli/FLImageScrollView.git", :tag => '0.1.3' }
s.source_files = 'FLImageScrollView.swift'
s.dependency 'SDWebImage', '3.7.5'
s.platform     = :ios, "8.0"
s.ios.deployment_target = "8.0"

end
