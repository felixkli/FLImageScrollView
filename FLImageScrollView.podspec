#
# Be sure to run `pod lib lint FLImageScrollView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = "FLImageScrollView"
s.version          = "0.5.7"
s.summary          = "ScrollView containing list of images."
s.homepage         = "https://github.com/felixkli/FLImageScrollView"
s.license          = 'MIT'
s.author           = { "Felix Li" => "li.felix162@gmail.com" }
s.source           = { :git => "https://github.com/felixkli/FLImageScrollView.git", :tag => s.version.to_s }
s.source_files     = 'FLImageScrollView.swift'
s.dependency "SDWebImage/GIF"
s.platform         = :ios, "9.0"
s.ios.deployment_target = "9.0"

end
