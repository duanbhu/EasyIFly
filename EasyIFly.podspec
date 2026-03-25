Pod::Spec.new do |s|
  s.name             = 'EasyIFly'
  s.version          = '1.0.0'
  s.summary          = '基于 iflyMSC.framework 的 Swift 二次封装，提供语音听写能力。'
  s.description      = 'EasyIFly 对科大讯飞 iflyMSC.framework 进行 Swift 封装，简化语音听写集成流程。'
  s.homepage         = 'https://github.com/duanbhu/EasyIFly'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'duanbhu' => '310701836@qq.com' }
  s.source           = { :git => 'https://github.com/duanbhu/EasyIFly.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'
  s.static_framework = true

  s.source_files = 'EasyIFly/Classes/**/*.{swift,h,m}'

  s.resource_bundles = {
    'EasyIFly' => ['EasyIFly/Assets/**/*.{xcassets,png}']
  }

  # 讯飞 framework - 从 GitHub Release 下载
  s.vendored_frameworks = 'iflyMSC.xcframework'
  
  s.prepare_command = <<-CMD
    curl -L https://github.com/duanbhu/EasyIFly/releases/download/1.0.0/iflyMSC.xcframework.zip -o iflyMSC.xcframework.zip
    unzip -o iflyMSC.xcframework.zip
    rm iflyMSC.xcframework.zip
  CMD

  # 系统依赖已在 iflyMSC.xcframework 的 modulemap 中声明
  # 这里仅声明 EasyIFly 自身需要的框架
  s.frameworks = ['UIKit', 'Foundation']

  # 关闭 Bitcode（iflyMSC.framework 不支持）
  s.pod_target_xcconfig = {
    'ENABLE_BITCODE' => 'NO'
  }
end
