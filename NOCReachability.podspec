Pod::Spec.new do |spec|
  spec.name = 'NOCReachability'
  spec.version = '1.0.1'
  spec.summary = 'NOCReachability is a library that provides features for checking network status.'

  spec.homepage = 'https://github.com/a-snail/NOCReachability'
  spec.license = { :type => 'MIT', :file => 'LICENSE' }
  spec.author = { 'Jaeo Bok' => 'snail.bok@gmail.com' }
  spec.social_media_url = 'https://twitter.com/snail_bok'

  spec.platforms = { :ios => '9.0' }
  spec.ios.deployment_target = '9.0'
  spec.requires_arc = true

  spec.source = { :git => 'https://github.com/a-snail/NOCReachability.git', :tag => spec.version.to_s }
  spec.source_files = 'NOCReachability/*.{h,m}'

  spec.dependency 'NOCLog', '~> 1.0'
end
