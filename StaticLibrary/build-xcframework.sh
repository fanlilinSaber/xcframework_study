#!/bin/sh -e

# 使用前先修改文件权限 chmod 777 build-xcframework.sh
# ./build-xcframework.sh运行脚本

# ================== 动态参数 ==================

# 📢* * begin 以下参数默认会自动获取，如果工程结构比较复杂的可以手动设置

# 需要build的工程名
PROJECT_NAME=''
# scheme名，默认情况下和工程名一样，如果不一样手动设置即可（需要把工程里对应的scheme勾选出来）
SCHEME_NAME=''
# 项目组织形式，分为 xcodeproj 和 xcworkspace 的方式
PROJEC_FORM=''
# 打包出来的 xcframework 名字；默认 = PROJECT_NAME名
FRAMEWORK_NAME=''

# 📢* * end

# ================== 固定参数 ==================

# 模拟器打包环境预设
BUILD_SIMULATOR_INTER_VARIABLES="VALIDATE_WORKSPACE=NO MACH_O_TYPE=staticlib ONLY_ACTIVE_ARCH=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= DEBUG_INFORMATION_FORMAT=dwarf SKIP_INSTALL=NO EXCLUDED_ARCHS=arm64"

# 真机打包环境预设
BUILD_IPHONEOS_INTER_VARIABLES="VALIDATE_WORKSPACE=NO ONLY_ACTIVE_ARCH=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= SKIP_INSTALL=NO GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=NO CLANG_ENABLE_CODE_COVERAGE=NO STRIP_INSTALLED_PRODUCT=NO MACH_O_TYPE=staticlib DEBUG_INFORMATION_FORMAT=dwarf"

# 真机和模拟器xcarchive路径
ARCHIVE_PATH="XCFramework/XCArchive"

# 编译过程产生的缓存文件路径
DERIVEDDAT_PATH="XCFramework/Build"

# ================== 临时变量 ==================

# 工程扩展名
PROJEC_EXTENSION=''

        
# ================== 公共方法 ==================

# 错误信息的打印并退出
 function logExit(){
    echo "\033[31mError：** ${1} ** ❌\033[0m"
    exit ${2}
}

# 有警告信息的打印
function logWarning(){
    echo "\033[33mWarning：** ${1} ** ⚠️\033[0m"
}

# 绿色信息的打印
function logGreen(){
    echo
    echo "\033[32m** ${1} ** \033[0m"
    echo
}

# 高亮信息的打印
function logHigh(){
    echo "\033[35m====> ${1} \033[0m"
}

# 正常信息的打印
function log(){
    echo "====> ${1}"
}

function preBuildCheck() {
    log "开始检测工程的编译参数信息"
    flag="0"
    
    # 检查build的参数是否设置了，如果没有设置自动获取
    if [ ! "${PROJECT_NAME}"] || [ ! "${SCHEME_NAME}" ] || [ ! "${PROJEC_FORM}" ]; then
        flag="0"
    else
        flag="1"
    fi
    
    # 以.xcworkspace形式查找
    if [ $flag = "0" ]; then
        log "自动获取以'xcworkspace'形式编译的工程名"
        # 获取当前目录下.xcworkspace的文件
         for file in $(find "." -maxdepth 1 -name '*.xcworkspace'); do
            log "遍历到的文件名 ${file}"
            
            PROJEC_FORM='workspace'
            PROJECT_NAME=$(basename "$file" .xcworkspace)
            flag="1"
         done
    fi
    
    # 以.xcodeproj形式查找
    if [ $flag = "0" ]; then
        log "自动获取以'xcodeproj'形式编译的工程名"
        for file in $(find "." -maxdepth 1 -name '*.xcodeproj'); do
            log "遍历到的文件名 ${file}"
            
            PROJEC_FORM='project'
            PROJECT_NAME=$(basename "$file" .xcodeproj)
            flag="1"
        done
    fi
    
    if [ $flag = "0" ]; then
        logExit "编译的参数异常，请排查"
        exit
    fi
    
    # 否手动设置了scheme的名字
    if [ ! "${SCHEME_NAME}"]; then
        SCHEME_NAME=${PROJECT_NAME}
    fi
    
    # 否手动设置了xcframework的名字
    if [ ! "${FRAMEWORK_NAME}"]; then
        FRAMEWORK_NAME=${PROJECT_NAME}
    fi
    
    if [ $PROJEC_FORM = "project" ]; then
        PROJEC_EXTENSION='xcodeproj'
    else
        PROJEC_EXTENSION='xcworkspace'
    fi
    
    logHigh "工程名：${PROJECT_NAME}  项目形式为：${PROJEC_FORM}"
    echo
}

function removeBuild() {
    echo '====> 清理编译数据'
    echo '====> Command line invocation:'
    log "rm -rf ${ARCHIVE_PATH} and ${DERIVEDDAT_PATH}"
    # 删除编译文件夹
    rm -rf $ARCHIVE_PATH
    rm -rf $DERIVEDDAT_PATH
    logHigh "编译数据清理完成"
    echo
    echo '====> Clean编译环境'
    # clean一下Release编译环境
    xcrun xcodebuild clean -$PROJEC_FORM $PROJECT_NAME.$PROJEC_EXTENSION -scheme $PROJECT_NAME -configuration Release
    logHigh "编译环境Clean完成"
    echo
}

function startBuild() {
    # 同时编译模拟器和真机的Release环境
    # 指定编译后的framework为静态包
    # 输出目录为 XCFramework/Build/Simulator
    # 输出目录为 XCFramework/Build/Device
    echo '====> 开始编译模拟器和真机Release'
    xcrun xcodebuild archive $BUILD_SIMULATOR_INTER_VARIABLES \
            -$PROJEC_FORM $PROJECT_NAME.$PROJEC_EXTENSION \
            -scheme $SCHEME_NAME \
            -configuration Release \
            -destination 'generic/platform=iOS Simulator' \
            -sdk iphonesimulator \
            -derivedDataPath $DERIVEDDAT_PATH/Simulator \
            -archivePath $ARCHIVE_PATH/simulator.xcarchive \
            -destination-timeout 3 \
            -quiet \
            & \
    xcrun xcodebuild archive $BUILD_IPHONEOS_INTER_VARIABLES \
            -$PROJEC_FORM $PROJECT_NAME.$PROJEC_EXTENSION \
            -scheme $SCHEME_NAME \
            -configuration Release \
            -destination 'generic/platform=iOS' \
            -sdk iphoneos \
            -derivedDataPath $DERIVEDDAT_PATH/Device \
            -archivePath $ARCHIVE_PATH/iOS.xcarchive \
            -quiet
    logHigh "编译模拟器和真机Release完成"
    echo
}

function createXCFramework() {
    echo '====> 开始移除旧的xcframework包'
    echo '====> Command line invocation:'
    echo "====> rm -rf XCFramework/${FRAMEWORK_NAME}.xcframework"
    
    # 移除原来的xcframework包
    rm -rf XCFramework/${FRAMEWORK_NAME}.xcframework
    logHigh '旧的xcframework包移除完成'
    echo
    
    # 判断产物是.framework还是.a的打包形式
    productType=""
    if [ -e "${ARCHIVE_PATH}/iOS.xcarchive/Products/Library/Frameworks/${PROJECT_NAME}.framework" ]; then
        productType="framework"
        logHigh "编译产物是.framework形式"
    elif [ -e "${ARCHIVE_PATH}/iOS.xcarchive/Products/usr/local/lib/lib${PROJECT_NAME}.a" ]; then
        productType="a"
        logHigh "编译产物是.a形式"
    else
        logExit "编译产物不存在，请排查"
    fi
    
    # 合并Release的模拟器和真机framework
    echo '====> 开始合并xcframework'
    if [ $productType = "a" ]; then
        xcrun xcodebuild -create-xcframework \
            -allow-internal-distribution \
            -library ${ARCHIVE_PATH}/simulator.xcarchive/Products/usr/local/lib/lib${PROJECT_NAME}.a -headers XCFramework/Build/Simulator/Build/Intermediates.noindex/ArchiveIntermediates/$PROJECT_NAME/BuildProductsPath/Release-iphonesimulator/include/$PROJECT_NAME \
            -library ${ARCHIVE_PATH}/iOS.xcarchive/Products/usr/local/lib/lib${PROJECT_NAME}.a -headers XCFramework/Build/Device/Build/Intermediates.noindex/ArchiveIntermediates/$PROJECT_NAME/BuildProductsPath/Release-iphoneos/include/$PROJECT_NAME \
            -output XCFramework/${FRAMEWORK_NAME}.xcframework
            
        # .a库需要额外做工作
        libraryOutput
    else
        xcrun xcodebuild -create-xcframework \
            -allow-internal-distribution \
            -framework ${ARCHIVE_PATH}/simulator.xcarchive/Products/Library/Frameworks/${PROJECT_NAME}.framework \
            -framework ${ARCHIVE_PATH}/iOS.xcarchive/Products/Library/Frameworks/${PROJECT_NAME}.framework \
            -output XCFramework/${FRAMEWORK_NAME}.xcframework
    fi
    
    logHigh "xcframework合并完成"
    echo
}

function dealBuildFile() {
    echo '====> 合并完成后清理编译数据'
    echo '====> Command line invocation:'
    log "rm -rf ${ARCHIVE_PATH} and ${DERIVEDDAT_PATH}"
    # 删除编译文件夹
    rm -rf $ARCHIVE_PATH
    rm -rf $DERIVEDDAT_PATH
    logHigh "编译数据清理完成"
}

function openXCFramework() {
   open ./XCFramework
   exit 0
}

function libraryOutput() {
    # 删除旧的Headers文件夹并创建新的
    echo '====> 移除旧的Headers文件'
#    rm -rf "XCFramework/Headers"
#    rm -rf "XCFramework/$PROJECT_NAME.swiftmodule"
#    mkdir -p "XCFramework/Headers"
#    mkdir -p "XCFramework/$PROJECT_NAME.swiftmodule"
#    log '旧的Headers文件移除完成'
    
#    log "开始Copy Header文件（为了暴露xx -> Build Phases -> Copy Files的文件）"
#    # copy暴露的头文件
#    source_include="XCFramework/Build/Device/Build/Intermediates.noindex/ArchiveIntermediates/$PROJECT_NAME/BuildProductsPath/Release-iphoneos/include/$PROJECT_NAME"
#
#    if [ -e "${source_include}" ]; then
#        cp -r "${source_include}/"* "XCFramework/Headers"
#        log "Copy Header文件完成"
#    fi
    
    # swift文件产生的，给Swift代码调用时需要用到（模拟器和真机分别都需要）
    source_simulator_swiftmodule="XCFramework/Build/Simulator/Build/Intermediates.noindex/ArchiveIntermediates/$PROJECT_NAME/BuildProductsPath/Release-iphonesimulator/$PROJECT_NAME.swiftmodule"
    source_ios_swiftmodule="XCFramework/Build/Device/Build/Intermediates.noindex/ArchiveIntermediates/$PROJECT_NAME/BuildProductsPath/Release-iphoneos/$PROJECT_NAME.swiftmodule"
    
    # 编译产生的隐藏文件
    source_simulator_derivedSources="XCFramework/Build/Simulator/Build/Intermediates.noindex/ArchiveIntermediates/$PROJECT_NAME/IntermediateBuildFilesPath/$PROJECT_NAME.build/Release-iphonesimulator/$PROJECT_NAME.build/DerivedSources"
    source_ios_derivedSources="XCFramework/Build/Device/Build/Intermediates.noindex/ArchiveIntermediates/$PROJECT_NAME/IntermediateBuildFilesPath/$PROJECT_NAME.build/Release-iphoneos/$PROJECT_NAME.build/DerivedSources"
    
    if [ -e "${source_simulator_swiftmodule}" ]; then
        mkdir -p "XCFramework/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/$PROJECT_NAME.swiftmodule"
        cp -r "${source_simulator_swiftmodule}/"* "XCFramework/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/$PROJECT_NAME.swiftmodule"
        log "Copy simulator.swiftmodule文件完成"
    fi
    
    if [ -e "${source_ios_swiftmodule}" ]; then
        mkdir -p "XCFramework/${FRAMEWORK_NAME}.xcframework/ios-arm64/$PROJECT_NAME.swiftmodule"
        cp -r "${source_ios_swiftmodule}/"* "XCFramework/${FRAMEWORK_NAME}.xcframework/ios-arm64/$PROJECT_NAME.swiftmodule"
        log "Copy ios.swiftmodule文件完成"
    fi
    
    mkdir -p "XCFramework/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/Swift Compatibility Header"
    mkdir -p "XCFramework/${FRAMEWORK_NAME}.xcframework/ios-arm64/Swift Compatibility Header"
    for file in $(find "$source_simulator_derivedSources" -name '*-Swift.h'); do
       log "遍历到的隐藏文件 ${file}"
       cp -f "$file" "XCFramework/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/Swift Compatibility Header"
       log 'Copy simulator -Swift.h文件成功'
    done
    
    for file in $(find "$source_ios_derivedSources" -name '*-Swift.h'); do
       log "遍历到的隐藏文件 ${file}"
       cp -f "$file" "XCFramework/${FRAMEWORK_NAME}.xcframework/ios-arm64/Swift Compatibility Header"
       log 'Copy ios -Swift.h文件成功'
    done
#
#    echo
#
#    rm -rf XCFramework/${FRAMEWORK_NAME}.xcframework/Modules
#    for file in $(find "$source_swiftmodule" -name "${PROJECT_NAME}.swiftmodule"); do
#       log "遍历到的swiftmodule文件 ${file}"
#       cp -r "$file" "XCFramework/${FRAMEWORK_NAME}.xcframework"
#       log 'Copy 文件成功'
#    done

   createUmbrella
   
   createModulemap
}

function createUmbrella() {
    # 指定文件名和路径
    simulator_umbrella_file="XCFramework/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/${PROJECT_NAME}-umbrella.h"
    ios_umbrella_file="XCFramework/${FRAMEWORK_NAME}.xcframework/ios-arm64/${PROJECT_NAME}-umbrella.h"
    
# 模拟器-创建头文件并写入内容（这里不能缩进代码）
cat > "$simulator_umbrella_file" << EOF
#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

EOF

    # 暴露模拟器头文件
    for file in $(find "XCFramework/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator//Headers" -name '*.h'); do
        # 过滤xxx-Swift.文件
        if [[ $file == *"-Swift.h"* ]]; then
            continue
        fi

        filename="#import \"$(basename "$file")\""
        log "暴露的文件名 ${filename}"
# 写入头文件
cat <<EOF >> "$simulator_umbrella_file"
${filename}
EOF
    done

# simulator_umbrella_file
cat <<EOF >> "$simulator_umbrella_file"

FOUNDATION_EXPORT double ${PROJECT_NAME}VersionNumber;
FOUNDATION_EXPORT const unsigned char ${PROJECT_NAME}VersionString[];
EOF


# 真机-创建头文件并写入内容（这里不能缩进代码）
cat > "$ios_umbrella_file" << EOF
#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

EOF

    # 暴露真机头文件
    for file in $(find "XCFramework/${FRAMEWORK_NAME}.xcframework/ios-arm64/Headers" -name '*.h'); do
        # 过滤xxx-Swift.文件
        if [[ $file == *"-Swift.h"* ]]; then
            continue
        fi

        filename="#import \"$(basename "$file")\""
        log "暴露的文件名 ${filename}"
# 写入头文件
cat <<EOF >> "$ios_umbrella_file"
${filename}
EOF
    done
# ios_umbrella_file
cat <<EOF >> "$ios_umbrella_file"

FOUNDATION_EXPORT double ${PROJECT_NAME}VersionNumber;
FOUNDATION_EXPORT const unsigned char ${PROJECT_NAME}VersionString[];
EOF
    echo
}

function createModulemap() {
    # 模块名称和目标文件路径
    module_name="${PROJECT_NAME}"
    module_swift_name="${PROJECT_NAME}.Swift"
    modulemap_file="XCFramework/${PROJECT_NAME}.modulemap"
    
    simulator_modulemap_file="XCFramework/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/${PROJECT_NAME}.modulemap"
    ios_modulemap_file="XCFramework/${FRAMEWORK_NAME}.xcframework/ios-arm64/${PROJECT_NAME}.modulemap"

# 创建模块映射文件并写入内容（这里不能缩进代码）
# 模拟器
cat << EOF > "$simulator_modulemap_file"
module $module_name {
  umbrella header "${PROJECT_NAME}-umbrella.h"
  
  export *
  module * { export * }
}
EOF

# 真机
cat << EOF > "$ios_modulemap_file"
module $module_name {
  umbrella header "${PROJECT_NAME}-umbrella.h"
  
  export *
  module * { export * }
}
EOF

    # 模拟器环境 是否有swift文件
    if [ -e "XCFramework/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/Swift Compatibility Header/${PROJECT_NAME}-Swift.h" ]; then
    
cat <<EOF >> "$simulator_modulemap_file"


module $module_swift_name {
 header "Swift Compatibility Header/${PROJECT_NAME}-Swift.h"
 requires objc
}
EOF
    fi
    
    # 真机环境 是否有swift文件
    if [ -e "XCFramework/${FRAMEWORK_NAME}.xcframework/ios-arm64/Swift Compatibility Header/${PROJECT_NAME}-Swift.h" ]; then
    
cat <<EOF >> "$ios_modulemap_file"


module $module_swift_name {
 header "Swift Compatibility Header/${PROJECT_NAME}-Swift.h"
 requires objc
}
EOF
    fi
}

# ================== begin 脚本执行区域 ==================

logGreen "开始运行脚本🏃🏻‍♀️"

START_SHELL_TIME=`date +%s`

preBuildCheck

removeBuild

startBuild

createXCFramework

#dealBuildFile

openXCFramework

END_SHELL_TIME=`date +%s`

SHEL_RUN_TIME=$((END_SHELL_TIME-START_SHELL_TIME))

logGreen "脚本运行时间为：$SHEL_RUN_TIME 秒"

# ================== end 脚本执行区域 ==================


# ================== 打包参数作用学习和分享 ==================

# 1.VALIDATE_WORKSPACE：如果开启了，那么将在构建版本的过程中对工作区域配置进行验证检查

# 2.MACH_O_TYPE（Mach-O Type）：二进制文件格式；①`mh_executable`(Executable binary)；②`mh_bundle`(Bundle binary)；③`mh_object`(Relocatable object file)；④`mh_dylib`(Dynamic library binary)；⑤`staticlib`(Static library binary)；打包framework我们主要用`动态库`和`静态库`

# 3.ONLY_ACTIVE_ARCH（Build Active Architecture Only）：·YES：只包含当前机型的代码适配，·NO：包含所有机型的代码适配

# 4.CODE_SIGNING_REQUIRED：是否需要签名，这里我们只打包成静态库不需要签名

# 5.CODE_SIGN_IDENTITY（Code Signing Identity）：证书签名信息

# 5.DEBUG_INFORMATION_FORMAT（Debug Information Format）：存储二进制文件的代码调试的信息；①`dwarf`(DWARF)：生成dwarf格式，主要用于源码级调试，打包快；②`dwarf-with-dsym`(DWARF with dSYM File)：会多生成一个dSYM符号表文件，符号对应着类、函数、变量等，这个符号表文件是内存与符号如函数名，文件名，行号等的映射等，影响打包速度。静态库不会生成dSYM文件

# 6.SKIP_INSTALL（Skip Install）：影响生成的产物位置，YES：产物放在 x/xx/UninstalledProducts目录下的（不在xx.xcarchive目录下），NO：产物放在xx/Products（跟生成的xx.xcarchive在同一级目录）;archive 必须设置 NO

# 7.BUILD_LIBRARY_FOR_DISTRIBUTION（Build Libraries for Distribution）：构建是兼容的framework，比如：我这里有一个通过Swift5.2.4编译出来的Framework。并且我的项目中Swift版本为5.5.2中使用这个Framework，此时就通过.swiftinterface来保证Framework能够正常的在5.5.2下使用，当开启时，Framework中的代码逻辑会推到运行时确定

# 8.-destination：架构类型

# 9.-archivePath：archive生成的产物存放路径

# 10.-derivedDataPath：编译过程产生的缓存文件存放路径，单独设置一下用于解决多个打包因为编译缓存的问题

# 11.-allow-internal-distribution：用于合成后的xcframework能生成xx.swiftmodule


# ================== 终端调试命令 ==================

# 1.如果工程是以 xcworkspace的形式，`xcodebuild -workspace 工程名.xcworkspace -list
# 1.如果工程是以 xcodeproj的形式，`xcodebuild -list


# ================== 踩坑 ==================

# 1.使用`.a`静态库打包编译相对`.framework`形式要麻烦许多，其中生成的xx.modulemap、xx.swiftmodule都是要单独去使用的工程中配置的，
#   HEADER_SEARCH_PATHS = $(inherited) "xxA/xxA.xcframework/Headers" "xxB/xxB.framework/Headers"
#   OTHER_CFLAGS="-fmodule-map-file=${SRCROOT}/SwiftC/SwiftA.framework/module.modulemap" "-fmodule-map-file=${SRCROOT}/SwiftC/SwiftB.framework/module.modulemap"（传递给 用来编译C或者OC的编译器，当前就是clang）
#   OTHER_SWIFT_FLAGS=$(inherited) -Xcc "-fmodule-map-file="${PODS_CONFIGURATION_BUILD_DIR}/SnapKit/SnapKit.modulemap" -Xcc "-fmodule-map-file="${PODS_CONFIGURATION_BUILD_DIR}/ZJKGoods/ZJKGoods.modulemap" "
#   SWIFT_INCLUDE_PATHS="${SRCROOT}/SwiftC/SwiftA.framework" "${SRCROOT}/SwiftC/SwiftB.framework"（传递给SwiftC编译器，告诉它去下面的路径查找module.file）


# ================== 有价值参考学习文档 ==================

# 1.https://developer.apple.com/library/archive/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html
# 2.https://www.cnblogs.com/drewgg/p/15785467.html
# 3.https://devpress.csdn.net/opensource/62f3a22ec6770329307f8b19.html
# 4.https://www.jianshu.com/p/9f73575ad78d
# 5.https://pemg9lxm13.feishu.cn/docx/RimLdsAnjozLBaxklu9c0eUVn1f
# 6.https://blog.csdn.net/Deft_MKJing/article/details/106979989?spm=1001.2014.3001.5502

