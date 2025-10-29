#!/bin/bash

# 权限修复后的测试脚本

echo "========================================="
echo "权限修复测试脚本"
echo "========================================="
echo ""

# 1. 清理项目
echo "步骤 1: 清理项目..."
flutter clean
cd android && ./gradlew clean && cd ..
echo "✓ 清理完成"
echo ""

# 2. 获取依赖
echo "步骤 2: 获取依赖..."
flutter pub get
echo "✓ 依赖获取完成"
echo ""

# 3. 检查 AndroidManifest.xml 权限
echo "步骤 3: 检查 AndroidManifest.xml 权限..."
echo "当前权限配置："
grep -A 5 "Permissions" android/app/src/main/AndroidManifest.xml
echo ""

# 4. 构建 APK
echo "步骤 4: 构建调试版 APK..."
flutter build apk --debug
echo "✓ APK 构建完成"
echo ""

# 5. 检查输出
echo "步骤 5: 检查构建输出..."
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo "✓ APK 文件生成成功："
    ls -lh build/app/outputs/flutter-apk/app-debug.apk
else
    echo "✗ APK 文件未找到"
    exit 1
fi
echo ""

echo "========================================="
echo "构建完成！"
echo "========================================="
echo ""
echo "下一步："
echo "1. 安装 APK: adb install -r build/app/outputs/flutter-apk/app-debug.apk"
echo "2. 启动应用并测试权限请求"
echo "3. 查看日志: adb logcat -s flutter"
echo ""
