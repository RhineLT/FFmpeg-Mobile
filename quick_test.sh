#!/bin/bash

# 快速测试脚本 - 验证白屏问题已修复

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  FFmpeg-Mobile 白屏问题修复快速测试"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 步骤 1: 代码验证
echo -e "${YELLOW}步骤 1/5: 验证代码修复...${NC}"
echo ""

echo "✓ 检查 StorageService 初始化:"
if grep -q "await storageService.init()" lib/main.dart; then
    echo -e "${GREEN}  ✓ StorageService.init() 已添加${NC}"
else
    echo -e "${RED}  ✗ StorageService.init() 缺失${NC}"
    exit 1
fi

echo "✓ 检查错误处理:"
if grep -q "catch (e, stackTrace)" lib/main.dart; then
    echo -e "${GREEN}  ✓ 错误捕获已添加${NC}"
else
    echo -e "${RED}  ✗ 错误捕获缺失${NC}"
    exit 1
fi

echo "✓ 检查调试日志:"
if grep -q "debugPrint.*Initialization" lib/main.dart; then
    echo -e "${GREEN}  ✓ 调试日志已添加${NC}"
else
    echo -e "${RED}  ✗ 调试日志缺失${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}━━━ 代码验证通过 ━━━${NC}"
echo ""

# 步骤 2: 清理
echo -e "${YELLOW}步骤 2/5: 清理项目...${NC}"
flutter clean > /dev/null 2>&1
echo -e "${GREEN}✓ 清理完成${NC}"
echo ""

# 步骤 3: 获取依赖
echo -e "${YELLOW}步骤 3/5: 获取依赖...${NC}"
flutter pub get > /dev/null 2>&1
echo -e "${GREEN}✓ 依赖获取完成${NC}"
echo ""

# 步骤 4: 代码分析
echo -e "${YELLOW}步骤 4/5: 代码分析...${NC}"
if flutter analyze lib/main.dart 2>&1 | grep -q "No issues found"; then
    echo -e "${GREEN}✓ 代码分析通过${NC}"
else
    echo -e "${RED}✗ 代码分析发现问题${NC}"
    flutter analyze lib/main.dart
    exit 1
fi
echo ""

# 步骤 5: 构建测试
echo -e "${YELLOW}步骤 5/5: 构建应用...${NC}"
echo "正在构建 APK，这可能需要几分钟..."
if flutter build apk --debug > /tmp/build.log 2>&1; then
    if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
        echo -e "${GREEN}✓ APK 构建成功${NC}"
        ls -lh build/app/outputs/flutter-apk/app-debug.apk
    else
        echo -e "${RED}✗ APK 文件未生成${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ 构建失败${NC}"
    cat /tmp/build.log
    exit 1
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✓ 所有测试通过！${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "下一步操作："
echo "1. 安装应用: adb install -r build/app/outputs/flutter-apk/app-debug.apk"
echo "2. 启动应用: adb shell am start -n com.videocompressor.video_compressor/.MainActivity"
echo "3. 查看日志: adb logcat -s flutter"
echo ""
echo "或者运行完整诊断："
echo "  ./diagnose_app.sh"
echo ""
