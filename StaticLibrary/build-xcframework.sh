#!/bin/sh -e

# 使用前先修改文件权限 chmod 777 build-xcframework.sh
# ./build-xcframework.sh运行脚本

# ================== 动态参数 ==================

# 📢* * begin 以下参数默认会自动获取，如果工程结构比较复杂的可以手动设置

# 工程（YYY.xcworkspace）的根路径；默认 = build-xcframework.sh脚本同级目录
ROOT_PATH='.'
# 需要build的工程名
PROJECT_NAME=''
# 项目组织形式，分为 xcodeproj 和 xcworkspace 的方式
PROJEC_FORM=''
# scheme名，默认情况下和工程名一样，如果不一样手动设置即可（需要把工程里对应的scheme勾选出来）
SCHEME_NAME=''
# 打包出来的 xcframework 名字；默认 = PROJECT_NAME名
FRAMEWORK_NAME=''
# 主podspec文件的路径；默认 = build-xcframework.sh脚本同级目录
PODSPEC_PATH=''
# README.md文件路径；默认 = build-xcframework.sh脚本同级目录
README_PATH=''
# 是否自动上传提交到子仓库
AUTO_PUSH='YES'
# 📢* * end

# ================== 固定参数 ==================

# 模拟器打包环境预设
BUILD_SIMULATOR_INTER_VARIABLES="VALIDATE_WORKSPACE=NO MACH_O_TYPE=staticlib ONLY_ACTIVE_ARCH=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= DEBUG_INFORMATION_FORMAT=dwarf SKIP_INSTALL=NO EXCLUDED_ARCHS=arm64"

# 真机打包环境预设
BUILD_IPHONEOS_INTER_VARIABLES="VALIDATE_WORKSPACE=NO ONLY_ACTIVE_ARCH=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= SKIP_INSTALL=NO GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=NO CLANG_ENABLE_CODE_COVERAGE=NO STRIP_INSTALLED_PRODUCT=NO MACH_O_TYPE=staticlib DEBUG_INFORMATION_FORMAT=dwarf"

# XCFramework根目录
XCF_PATH="XCFramework"
# 真机和模拟器xcarchive路径
ARCHIVE_PATH="$XCF_PATH/XCArchive"
# 编译过程产生的缓存文件路径
DERIVEDDAT_PATH="$XCF_PATH/Build"

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
         for file in $(find $ROOT_PATH -maxdepth 1 -name '*.xcworkspace'); do
            log "遍历到的文件名 ${file}"
            
            PROJEC_FORM='workspace'
            PROJECT_NAME=$(basename "$file" .xcworkspace)
            flag="1"
         done
    fi
    
    # 以.xcodeproj形式查找
    if [ $flag = "0" ]; then
        log "自动获取以'xcodeproj'形式编译的工程名"
        for file in $(find $ROOT_PATH -maxdepth 1 -name '*.xcodeproj'); do
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
    xcrun xcodebuild clean -$PROJEC_FORM $ROOT_PATH/$PROJECT_NAME.$PROJEC_EXTENSION -scheme $PROJECT_NAME -configuration Release
    logHigh "编译环境Clean完成"
    echo
}

function adjustBuiledSh() {
    # Pods-resources.sh路径如果不是这个修改成自己项目的路径
    resources_sh="Pods/Target Support Files/Pods-${SCHEME_NAME}/Pods-${SCHEME_NAME}-resources.sh"
    if [ -e "${resources_sh}" ]; then
        log "检测到有Pods-${SCHEME_NAME}-resources.sh文件需要重新校正脚本；避免写入不必要的资源"
        if grep -q "The MACH_O_TYPE is" "${resources_sh}"; then
            log "文件中已存在校正脚本"
        else
            new_text="echo \"The MACH_O_TYPE is: \$MACH_O_TYPE\"\nif [ \"\$MACH_O_TYPE\" == \"staticlib\" ]; then\n  exit 0\nfi"

            sed -i  "" "1s/^/$new_text\\n/" "${resources_sh}"
        fi
        logHigh "校正${SCHEME_NAME}-resources.sh 完成"
        echo
    fi
}

function startBuild() {
    # 同时编译模拟器和真机的Release环境
    # 指定编译后的framework为静态包
    # 输出目录为 XCFramework/Build/Simulator
    # 输出目录为 XCFramework/Build/Device
    echo '====> 开始编译模拟器和真机Release'
    xcrun xcodebuild archive $BUILD_SIMULATOR_INTER_VARIABLES \
            -$PROJEC_FORM $ROOT_PATH/$PROJECT_NAME.$PROJEC_EXTENSION \
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
            -$PROJEC_FORM $ROOT_PATH/$PROJECT_NAME.$PROJEC_EXTENSION \
            -scheme $SCHEME_NAME \
            -configuration Release \
            -destination 'generic/platform=iOS' \
            -sdk iphoneos \
            -derivedDataPath $DERIVEDDAT_PATH/Device \
            -archivePath $ARCHIVE_PATH/iOS.xcarchive \
            -quiet
    
    wait  # 等待所有后台进程完成
    logHigh "编译模拟器和真机Release完成"
    echo
}

function createXCFramework() {
    echo '====> 开始移除旧的xcframework包'
    echo '====> Command line invocation:'
    echo "====> rm -rf $XCF_PATH/${FRAMEWORK_NAME}.xcframework"
    
    # 移除原来的xcframework包
    rm -rf ${XCF_PATH}/${FRAMEWORK_NAME}.xcframework
    rm -rf ${XCF_PATH}/${FRAMEWORK_NAME}.xcframework.zip
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
            -library ${ARCHIVE_PATH}/simulator.xcarchive/Products/usr/local/lib/lib${PROJECT_NAME}.a -headers ${XCF_PATH}/Build/Simulator/Build/Intermediates.noindex/ArchiveIntermediates/$PROJECT_NAME/BuildProductsPath/Release-iphonesimulator/include/$PROJECT_NAME \
            -library ${ARCHIVE_PATH}/iOS.xcarchive/Products/usr/local/lib/lib${PROJECT_NAME}.a -headers ${XCF_PATH}/Build/Device/Build/Intermediates.noindex/ArchiveIntermediates/$PROJECT_NAME/BuildProductsPath/Release-iphoneos/include/$PROJECT_NAME \
            -output $XCF_PATH/${FRAMEWORK_NAME}.xcframework
            
        # .a库需要额外做工作
        libraryOutput
    else
        xcrun xcodebuild -create-xcframework \
            -allow-internal-distribution \
            -framework ${ARCHIVE_PATH}/simulator.xcarchive/Products/Library/Frameworks/${PROJECT_NAME}.framework \
            -framework ${ARCHIVE_PATH}/iOS.xcarchive/Products/Library/Frameworks/${PROJECT_NAME}.framework \
            -output ${XCF_PATH}/${FRAMEWORK_NAME}.xcframework
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
   open ./${XCF_PATH}
}

function libraryOutput() {
    # 开始配置library的必要文件
    echo
    echo '====> 开始配置library的必要文件'

    # swift文件产生的，给Swift代码调用时需要用到（模拟器和真机分别都需要）
    source_simulator_swiftmodule="${XCF_PATH}/Build/Simulator/Build/Intermediates.noindex/ArchiveIntermediates/$PROJECT_NAME/BuildProductsPath/Release-iphonesimulator/$PROJECT_NAME.swiftmodule"
    source_ios_swiftmodule="${XCF_PATH}/Build/Device/Build/Intermediates.noindex/ArchiveIntermediates/$PROJECT_NAME/BuildProductsPath/Release-iphoneos/$PROJECT_NAME.swiftmodule"
    
    # 编译产生的隐藏文件
    source_simulator_derivedSources="${XCF_PATH}/Build/Simulator/Build/Intermediates.noindex/ArchiveIntermediates/$PROJECT_NAME/IntermediateBuildFilesPath/$PROJECT_NAME.build/Release-iphonesimulator/$PROJECT_NAME.build/DerivedSources"
    source_ios_derivedSources="${XCF_PATH}/Build/Device/Build/Intermediates.noindex/ArchiveIntermediates/$PROJECT_NAME/IntermediateBuildFilesPath/$PROJECT_NAME.build/Release-iphoneos/$PROJECT_NAME.build/DerivedSources"
    
    if [ -e "${source_simulator_swiftmodule}" ]; then
        mkdir -p "${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/$PROJECT_NAME.swiftmodule"
        cp -r "${source_simulator_swiftmodule}/"* "${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/$PROJECT_NAME.swiftmodule"
        log "Copy simulator.swiftmodule文件完成"
    fi
    
    if [ -e "${source_ios_swiftmodule}" ]; then
        mkdir -p "${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-arm64/$PROJECT_NAME.swiftmodule"
        cp -r "${source_ios_swiftmodule}/"* "${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-arm64/$PROJECT_NAME.swiftmodule"
        log "Copy ios.swiftmodule文件完成"
    fi
    
    # 创建 swift 兼容文件夹
    mkdir -p "${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/Swift Compatibility Header"
    mkdir -p "${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-arm64/Swift Compatibility Header"
    for file in $(find "$source_simulator_derivedSources" -name '*-Swift.h'); do
       log "遍历到的隐藏文件 ${file}"
       cp -f "$file" "${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/Swift Compatibility Header"
       log 'Copy simulator -Swift.h文件成功'
    done
    
    for file in $(find "$source_ios_derivedSources" -name '*-Swift.h'); do
       log "遍历到的隐藏文件 ${file}"
       cp -f "$file" "${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-arm64/Swift Compatibility Header"
       log 'Copy ios -Swift.h文件成功'
    done
    
    # xcframework 的 Headers路径
    source_simulator_headers="${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/Headers"
    source_ios_headers="${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-arm64/Headers"
    
    log "检测是否有自定义 Umbrella 和 modulemap文件"
    isUmbrella="0"
    isModulemap="0"
    # 是否有自定义 Umbrella 和 modulemap文件
    for file in $(find "$source_simulator_headers" -name '*-umbrella.h' -o -name '*.modulemap'); do
        if [[ $file == *"-umbrella.h"* ]]; then
            log "simulator 自定义Umbrella文件 ${file}"
            isUmbrella="1"
        elif [[ $file == *"modulemap"* ]]; then
            log "simulator 自定义modulemap文件 ${file}"
            isModulemap="1"
        fi
       mv -f "$file" "${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator"
    done
    
    for file in $(find "$source_ios_headers" -name '*-umbrella.h' -o -name '*.modulemap'); do
        if [[ $file == *"-umbrella.h"* ]]; then
            log "ios 自定义Umbrella文件 ${file}"
            isUmbrella="1"
        elif [[ $file == *"modulemap"* ]]; then
            log "ios 自定义modulemap文件 ${file}"
            isModulemap="1"
        fi
       mv -f "$file" "${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-arm64"
    done
    
    if [ $isUmbrella = "0" ]; then
       # 生成 Umbrella 文件
        createUmbrella
    fi

    if [ $isModulemap = "0" ]; then
        # 生成 Modulemap 文件
        createModulemap
    fi
}

function createUmbrella() {
    echo
    log "开始生成-umbrella.h文件"
    # 指定文件名和路径
    simulator_umbrella_file="${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/${PROJECT_NAME}-umbrella.h"
    ios_umbrella_file="${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-arm64/${PROJECT_NAME}-umbrella.h"
    
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
    for file in $(find "${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/Headers" -name '*.h'); do
        # 过滤xxx-Swift.文件
        if [[ $file == *"-Swift.h"* ]]; then
            continue
        fi

        filename="#import \"$(basename "$file")\""
        log "暴露模拟器头文件 ${filename}"
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
    for file in $(find "${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-arm64/Headers" -name '*.h'); do
        # 过滤xxx-Swift.文件
        if [[ $file == *"-Swift.h"* ]]; then
            continue
        fi

        filename="#import \"$(basename "$file")\""
        log "暴露真机头文件 ${filename}"
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
    logHigh "生成-umbrella.h文件完成"
}

function createModulemap() {
    echo
    log "开始生成modulemap文件"
    # 模块名称和目标文件路径
    module_name="${PROJECT_NAME}"
    module_swift_name="${PROJECT_NAME}.Swift"
    modulemap_file="${XCF_PATH}/${PROJECT_NAME}.modulemap"
    
    simulator_modulemap_file="${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/${PROJECT_NAME}.modulemap"
    ios_modulemap_file="${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-arm64/${PROJECT_NAME}.modulemap"

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
    if [ -e "${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-x86_64-simulator/Swift Compatibility Header/${PROJECT_NAME}-Swift.h" ]; then
    
cat <<EOF >> "$simulator_modulemap_file"


module $module_swift_name {
 header "Swift Compatibility Header/${PROJECT_NAME}-Swift.h"
 requires objc
}
EOF
    fi
    
    # 真机环境 是否有swift文件
    if [ -e "${XCF_PATH}/${FRAMEWORK_NAME}.xcframework/ios-arm64/Swift Compatibility Header/${PROJECT_NAME}-Swift.h" ]; then
    
cat <<EOF >> "$ios_modulemap_file"


module $module_swift_name {
 header "Swift Compatibility Header/${PROJECT_NAME}-Swift.h"
 requires objc
}
EOF
    fi
    logHigh "生成modulemap文件完成"
}

# 如果git自动推送失败可以手动推送
function pushXCFramework() {

    if [ "$AUTO_PUSH" == "YES" ]; then
        userInput="yes"
    else
        # 获取用户输入
        read -p "$(echo "\033[0;31m是否自动上传提交(yes/no)：\033[0m")" userInput
    fi

    # 判断用户输入
    if [ "$userInput" == "yes" ]; then
        # 更新子模块
        log "更新子模块"
        # 此时子模块会有 HEAD 游离的分支在
        git submodule update --init --remote
        
        if [ "$PODSPEC_PATH" == "" ]; then
            PODSPEC_PATH=${PROJECT_NAME}.podspec
        fi
        
        if [ "$README_PATH" == "" ]; then
            README_PATH=README.md
        fi
        
        log "开始同步版本号和README文件"
        # 版本信息
        version=$(cat $PODSPEC_PATH | grep -E "\s*\.version\s*=" | awk -F= '{print $2}' | tr -d " ';\"")
        logHigh "version：$version"

        # 自动同步版本号
        sed -i '' "s/\.version. *=.*/\.version = '$version'/" ${XCF_PATH}/${PROJECT_NAME}.xcframework.podspec
        logHigh "同步版本号完成"

        # 自动同步README.md
        if [ -e "${README_PATH}" ]; then
            cp -r ${README_PATH} "${XCF_PATH}"
            logHigh "同步README.md文件完成"
        fi

        logHigh "开始对${FRAMEWORK_NAME}.xcframework文件压缩成zip"
        cd ${XCF_PATH}

        zip -r "${FRAMEWORK_NAME}.xcframework.zip" "${FRAMEWORK_NAME}.xcframework"
        logHigh "压缩完成 -> 移除原文件${FRAMEWORK_NAME}.xcframework"
        # 启用了自动上传就删除编译文件
        rm -rf ${FRAMEWORK_NAME}.xcframework
        
        echo
        log "开始提交子模块更新"
        git status
        # 获取当前分支名
        current_branch=$(git branch | grep "*")
        echo "current_branch = $current_branch"
        # 判断当前分支是否为master
        if [ "$current_branch" != "master" ]; then
          # 删除本地临时分支保证自动化流程不被中断
          if [[ $(git branch --list temp) ]]; then
              git branch -d temp
          fi
          git checkout -b temp
          git branch
        else
          echo "当前已经在master分支"
        fi

        # 检查是否有待提交的更改
        if [[ $(git status --porcelain) ]]; then
          logHigh "有待提交的更改."
          git add .
          git commit -m "v${version}"
        else
          logHigh "没有待提交的更改."
        fi
        
        # 切换到master分支
        git checkout master
        echo "已切换到master分支"
        # 把temp分支合并过来
        git merge temp
        
        git pull origin master
        # 解决冲突（如果有冲突）
        if [ $? -ne 0 ]; then
          echo "合并有冲突，请手动解决冲突提交"
          exit 1
        fi
        
        # 这一步有可能会因为网络环境失败 失败了 请手动提交
        git push origin master
        git lfs push origin master
        
        # 同步远端tag
        git fetch --tags
        if [[ $(git tag --list v${version}) ]]; then
            echo "有同名的tag"
            # 删除旧tag
            git tag -d "v${version}"
            git push origin :refs/tags/v${version}
        fi
        
        # 推送tag
        git tag "v${version}"
        git push origin "v${version}"
        
        # 删除临时分支
        git branch -d temp
    else
        openXCFramework
    fi
}

# ================== begin 脚本执行区域 ==================

logGreen "开始运行脚本🏃🏻‍♀️"

START_SHELL_TIME=`date +%s`

preBuildCheck

removeBuild

adjustBuiledSh

startBuild

createXCFramework

dealBuildFile

#pushXCFramework

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

# 12.-quiet：只打印必要的进度信息和错误消息，以减少对终端输出的压力，防止脚本卡死


# ================== 终端调试命令 ==================

# 1.如果工程是以 xcworkspace的形式，`xcodebuild -workspace 工程名.xcworkspace -list
# 1.如果工程是以 xcodeproj的形式，`xcodebuild -list


# ================== 踩坑 ==================

# 1.使用`.a`静态库打包编译相对`.framework`形式要麻烦许多，其中生成的xx.modulemap、xx.swiftmodule都是要单独去使用的工程中配置的，举例一份podspec中的配置，如果手动拖参考这个来

   # xcframework.user_target_xcconfig = {'OTHER_CFLAGS' => '$(inherited) -fmodule-map-file="${PODS_XCFRAMEWORKS_BUILD_DIR}/xx/XCFramework/xx.modulemap"', 'OTHER_SWIFT_FLAGS' => '-Xcc -fmodule-map-file="${PODS_XCFRAMEWORKS_BUILD_DIR}/xx/XCFramework/xx.modulemap"', 'SWIFT_INCLUDE_PATHS' => '"${PODS_XCFRAMEWORKS_BUILD_DIR}/xx/XCFramework"'}
    
   # OTHER_CFLAGS：传递给用来编译C或者OC的编译选项
   # OTHER_SWIFT_FLAGS：Swift 编译选项
   # SWIFT_INCLUDE_PATHS：swiftmodule 搜索路径，可用于配置依赖的其他 swiftmodule
   
# 2.为了能开启swift下能直接访问oc文件需要用到 -import-underlying-module
    # OTHER_SWIFT_FLAGS 的标记：-import-underlying-module 该构件标记由 Xcode 隐式创建下层 Module，并隐式引入当前 Module 内所有的 Objective-C 的公开头文件，Swift 可以直接访问。该标记需要配合 USER_HEADER_SEARCH_PATHS 或者 HEADER_SEARCH_PATHS 来搜索当前 module 所需的公开头文件
    # OTHER_SWIFT_FLAGS = $(inherited) -import-underlying-module -Xcc -fmodule-map-file="${SRCROOT}/${MODULEMAP_FILE}"
    
# 3.暴露头文件方法：TARGETS->Build Phases->Copy Files->下添加需要暴露的头文件

# ================== 有价值参考学习文档 ==================

# 1.https://developer.apple.com/library/archive/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html
# 2.https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle
# 3.https://www.cnblogs.com/drewgg/p/15785467.html
# 4.https://devpress.csdn.net/opensource/62f3a22ec6770329307f8b19.html
# 5.https://www.jianshu.com/p/9f73575ad78d
# 6.https://pemg9lxm13.feishu.cn/docx/RimLdsAnjozLBaxklu9c0eUVn1f
# 7.https://blog.csdn.net/Deft_MKJing/article/details/106979989?spm=1001.2014.3001.5502

