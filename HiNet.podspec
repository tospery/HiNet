Pod::Spec.new do |s|
  s.name             = 'HiNet'
  s.version          = '1.0.5'
  s.summary          = 'Net module.'
  s.description      = <<-DESC
						Net module using Swift.
                       DESC
  s.homepage         = 'https://github.com/tospery/HiNet'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'YangJianxiang' => 'tospery@gmail.com' }
  s.source           = { :git => 'https://github.com/tospery/HiNet.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.swift_version = '5.3'
  s.ios.deployment_target = '16.0'
  s.frameworks = 'Foundation'
  
  s.subspec 'Core' do |ss|
    ss.source_files = 'HiNet/Core/**/*'
	ss.dependency 'ObjectMapper', '~> 4.0'
    ss.dependency 'Moya/Core', '~> 15.0'
  end
  
  s.subspec 'RxSwift' do |ss|
    ss.source_files = 'HiNet/RxSwift/**/*'
	ss.dependency 'HiNet/Core'
	ss.dependency 'RxRelay', '~> 6.0'
	ss.dependency 'Moya/RxSwift', '~> 15.0'
  end
  
  s.subspec 'Combine' do |ss|
    ss.source_files = 'HiNet/Combine/**/*'
	ss.dependency 'HiNet/Core'
	ss.dependency 'Moya/Combine', '~> 15.0'
  end
  
end
