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
  s.authors          = 'SpotXchange, Inc.'
  s.homepage         = 'http://www.spotxchange.com'
  s.source           = { :git => 'https://github.com/spotxmobile/spotx-admob-ios.git', tag: '4.1.0' }
  s.license          =  'MIT'
  s.platform         = :ios, '9.0'
  s.requires_arc     = true

  s.source_files  = 'Classes/*.{h,m}'

  s.dependency 'Google-Mobile-Ads-SDK'
  s.dependency 'SpotX-SDK'
end
