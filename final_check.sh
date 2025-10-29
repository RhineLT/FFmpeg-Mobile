#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  最终代码验证"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

checks_passed=0
checks_total=0

check() {
    checks_total=$((checks_total + 1))
    if eval "$2"; then
        echo -e "${GREEN}✓${NC} $1"
        checks_passed=$((checks_passed + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $1"
        return 1
    fi
}

echo "检查关键修复..."
echo ""

check "StorageService 初始化已添加" "grep -q 'await storageService.init()' lib/main.dart"
check "PermissionService 逐个请求权限" "grep -q 'Permission.videos.request()' lib/services/permission_service.dart"
check "TaskManager 详细日志已添加" "grep -q 'Loading saved tasks' lib/providers/task_manager.dart"
check "权限诊断页面已创建" "test -f lib/screens/permission_diagnostic_screen.dart"
check "HomeScreen 添加诊断入口" "grep -q 'PermissionDiagnosticScreen' lib/screens/home_screen.dart"
check "错误捕获已添加到 main.dart" "grep -q 'catch (e, stackTrace)' lib/main.dart"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $checks_passed -eq $checks_total ]; then
    echo -e "${GREEN}所有检查通过！($checks_passed/$checks_total)${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "可以开始测试了："
    echo "  flutter clean && flutter pub get"
    echo "  flutter build apk --debug"
    exit 0
else
    echo -e "${RED}有 $((checks_total - checks_passed)) 个检查失败${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi
