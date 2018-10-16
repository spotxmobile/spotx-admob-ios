# Copyright (c) 2018 spotxchange. All rights reserved.
#
# Be sure to run `pod spec lint' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.version          = '4.1.0'
  s.name             = 'SpotX-AdMob-Plugin'
  s.summary          = 'AdMob plugin for SpotXchange'
  s.authors          = 'SpotX, Inc.'
  s.homepage         = 'https://www.spotx.tv'
  s.source           = { :git => 'https://github.com/spotxmobile/spotx-admob-ios.git', tag: '4.1.0' }
  s.preserve_paths   = [ 'SpotXAdMobPlugin.framework' ]
  s.license          =  'MIT'
  s.platform         = :ios, '9.0'
  s.requires_arc     = true

  s.source_files  = 'Classes/*.{h,m}'

  s.dependency 'SpotX-SDK'
  s.dependency 'Google-Mobile-Ads-SDK'
end
