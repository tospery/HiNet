Pod::Spec.new do |s|
  s.name             = 'HiNet'
  s.version          = '1.0.1'
  s.summary          = 'Net function.'
  s.description      = <<-DESC
						Net function using Swift.
                       DESC
  s.homepage         = 'https://github.com/tospery/HiNet'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'YangJianxiang' => 'tospery@gmail.com' }
  s.source           = { :git => 'https://github.com/tospery/HiNet.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.swift_version = '5.3'
  s.ios.deployment_target = '13.0'
  s.frameworks = 'Foundation'
  
  s.source_files = 'HiNet/**/*'
  s.dependency 'ObjectMapper', '~> 4.0'
  s.dependency 'RxRelay', '~> 6.0'
  s.dependency 'Moya/RxSwift', '~> 15.0'
  
end
