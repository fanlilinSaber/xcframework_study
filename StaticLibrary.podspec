Pod::Spec.new do |s|
    s.name = "StaticLibrary"
    s.version = "1.0.0"
    s.summary = "StaticLibrary"
    s.homepage = "https://github.com/fanlilinSaber/xcframework_study"
    s.license = { type: 'MIT', file: 'LICENSE' }
    s.authors = { "Fan Li Lin" => '824589131.com' }
    s.platform = :ios, "11.0"
    s.swift_versions = ["5.0"]
    s.frameworks = 'Foundation', 'UIKit'
    s.requires_arc = true
    s.source = { :git => 'https://github.com/fanlilinSaber/xcframework_study.git', :tag => "v#{s.version}" }
    s.swift_version = "5.0"
    s.default_subspec = 'XCFramework'
    
    s.subspec "Code" do |code|
        code.public_header_files = "StaticLibrary/StaticLibrary/Pubilc/*.{h}"
        code.source_files = "StaticLibrary/StaticLibrary/**/*.{h,m,swift}"
        code.exclude_files = 'StaticLibrary/StaticLibrary/Private/StaticLibrary-umbrella.h', 'StaticLibrary/StaticLibrary/Private/StaticLibrary.modulemap'
    end
 
    s.subspec "XCFramework" do |xcframework|
        xcframework.vendored_frameworks = ["StaticLibrary/XCFramework/StaticLibrary.xcframework"]
        xcframework.source_files = "StaticLibrary/XCFramework/StaticLibrary.xcframework/ios-arm64/Headers/*"
        xcframework.user_target_xcconfig = {
            'OTHER_CFLAGS' => '$(inherited) -fmodule-map-file="${PODS_XCFRAMEWORKS_BUILD_DIR}/StaticLibrary/XCFramework/StaticLibrary.modulemap"',
            'OTHER_SWIFT_FLAGS' => '-Xcc -fmodule-map-file="${PODS_XCFRAMEWORKS_BUILD_DIR}/StaticLibrary/XCFramework/StaticLibrary.modulemap"',
            'SWIFT_INCLUDE_PATHS' => '"${PODS_XCFRAMEWORKS_BUILD_DIR}/StaticLibrary/XCFramework"',
        }
    end
    
end
