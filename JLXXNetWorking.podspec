Pod::Spec.new do |s|
  s.name             = 'JLXXNetWorking'
  s.version          = '1.4.2'
  s.summary          = 'JLXXNetWorking.'
  s.description      = '网络请求类,改编自YTKNetWork.'
  s.homepage         = 'https://github.com/cnsuer/JLXXNetWorking'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'cnsuer' => '842393459@qq.com' }
  s.source           = { :git => 'https://github.com/cnsuer/JLXXNetWorking.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'JLXXNetWorking/Classes/**/*'
  s.dependency 'AFNetworking'
end
