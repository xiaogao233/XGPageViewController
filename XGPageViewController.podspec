
Pod::Spec.new do |s|
  s.name         = "XGPageViewController"
  s.version      = "1.0.0"
  s.platform     = :ios, "7.0"
  s.ios.deployment_target = '7.0'
  s.summary      = "A short pageViewController of XGPageViewController."
  s.homepage     = "https://github.com/xiaogao233/XGPageViewController.git"
  s.license      = "MIT"
  s.author             = { "高昇" => "xiaogao233@163.com" }
  s.source       = { :git => "https://github.com/xiaogao233/XGPageViewController.git", :tag => "#{s.version}" }
  s.source_files  = "XGPageViewController/*.{h,m}"
end

