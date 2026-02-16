# ClawNotes Code Quality Scripts

## 代码检查脚本

### 1. 检查 TODO 标记

```bash
# 检查所有 TODO
grep -r "TODO" --include="*.swift" .

# 检查所有 FIXME
grep -r "FIXME" --include="*.swift" .

# 检查所有 BUG
grep -r "BUG" --include="*.swift" .
```

### 2. 检查未使用的代码

```bash
# 检查未使用的 import
grep -r "^import " --include="*.swift" . | sort | uniq -d

# 检查空方法
grep -r "// TODO:" --include="*.swift" .
```

### 3. 代码统计

```bash
# 统计代码行数
find . -name "*.swift" -exec wc -l {} + | sort -rn | head -20

# 统计文件数
find . -name "*.swift" | wc -l
```

## Git Hooks

### pre-commit 钩子

在 `.git/hooks/pre-commit` 中添加:

```bash
#!/bin/bash

# 检查 TODO
if grep -r "TODO\|FIXME\|BUG" --include="*.swift" . | grep -v "TODO: Add test" | grep -v "Binary"; then
    echo "❌ Found TODO/FIXME/BUG in code"
    exit 1
fi

# 检查打印语句
if grep -r "print(" --include="*.swift" . | grep -v "// debug"; then
    echo "⚠️ Found print statement"
    # 不阻止提交，仅警告
fi

echo "✅ Code check passed"
exit 0
```

## CI/CD 配置

### GitHub Actions

在 `.github/workflows/ci.yml` 中:

```yaml
name: CI

on:
  push:
    branches: [master]
  pull_request:
    branches: [master]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
    
    - name: Build
      run: xcodebuild -project ClawNotes.xcodeproj -scheme ClawNotes -configuration Debug build
    
    - name: Run Tests
      run: xcodebuild test -project ClawNotes.xcodeproj -scheme ClawNotes
```

## 代码规范检查

### 1. 命名规范

| 类型 | 规则 | 示例 |
|------|------|------|
| 类/结构体 | PascalCase | `NotebookViewModel` |
| 函数/方法 | camelCase | `createNotebook()` |
| 变量/属性 | camelCase | `notebookTitle` |
| 常量 | camelCase + k前缀 | `maxRetryCount` |
| 枚举 | PascalCase | `.study` |

### 2. 注释规范

```swift
/// 这是一个公开方法的文档注释
/// - Parameter name: 参数说明
/// - Returns: 返回值说明
/// - Note: 注意事项
func example() -> String {
    // 内部注释用 //
    return ""
}
```

### 3. 错误处理

```swift
// 推荐
do {
    try someFunction()
} catch {
    print("错误: \(error)")
    // 处理错误
}

// 避免
try? someFunction()  // 隐藏错误
```
