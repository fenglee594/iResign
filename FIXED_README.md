# iReSign IPA打包修复说明

## 问题描述

原始的iReSign项目在重签名应用时会产生错误的IPA文件结构。解压后的目录包含了不应该存在的临时文件，如：

```
错误的结构:
├── zitt
│   ├── entitlements.plist  ← 不应该存在的临时文件
│   └── Payload
│       └── Zitt.app
└── zitt.ipa
```

这种结构不符合苹果的IPA文件标准，可能导致应用无法正常安装或通过App Store审核。

## 修复内容

### 1. 修复了 `doZip` 方法 (第604-656行)

**原始问题:**
- 使用 `zip -qry destinationPath .` 打包整个工作目录
- 包含了 `entitlements.plist` 等临时文件
- 生成的IPA文件结构不正确

**修复方案:**
- 只包含 `Payload` 目录和必要的元数据文件
- 排除所有签名相关的临时文件

### 2. 改进的文件过滤逻辑

修复后的代码会：
- ✅ 始终包含 `Payload` 目录
- ✅ 包含标准的iTunes元数据文件：`iTunesMetadata.plist`、`iTunesArtwork`等
- ❌ 排除 `entitlements.plist` 临时文件
- ❌ 排除所有包含 "entitlements" 或 "Entitlements" 的文件

## 正确的IPA结构

修复后生成的IPA文件应该具有以下结构：

```
正确的结构:
├── Payload
│   └── YourApp.app
├── iTunesMetadata.plist (可选)
├── iTunesArtwork (可选)
└── 其他标准元数据文件 (可选)
```

## 如何使用

### 1. 编译修复后的iReSign

```bash
# 在Xcode中打开项目
open iReSign.xcodeproj

# 编译并运行
```

### 2. 验证IPA文件结构

使用提供的测试脚本验证生成的IPA文件：

```bash
# 给脚本执行权限
chmod +x test_ipa_structure.sh

# 测试IPA文件
./test_ipa_structure.sh /path/to/your-app-resigned.ipa
```

### 3. 测试脚本输出示例

```
=== IPA文件结构测试脚本 ===
正在测试IPA文件: your-app-resigned.ipa

=== 检查标准结构 ===
✓ Payload目录存在
✓ Payload目录中包含1个.app应用包
✓ 没有发现entitlements.plist临时文件

=== 测试完成 ===
```

## 技术细节

### 修改的关键代码片段

```objective-c
// 构建要打包的文件列表，只包含必要的文件
NSMutableArray *filesToZip = [NSMutableArray array];

// 添加Payload目录（这是必须的）
[filesToZip addObject:kPayloadDirName];

// 检查并添加其他可能存在的标准IPA文件
NSArray *workingDirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:workingPath error:nil];
for (NSString *file in workingDirContents) {
    // 添加iTunes相关的元数据文件，但排除临时文件和签名相关文件
    if ([file isEqualToString:@"iTunesMetadata.plist"] ||
        [file isEqualToString:@"iTunesArtwork"] ||
        [file isEqualToString:@"iTunesArtwork@2x"]) {
        [filesToZip addObject:file];
    }
    // 排除entitlements.plist和其他签名临时文件
    else if ([file hasSuffix:@".plist"] && 
             ![file isEqualToString:@"entitlements.plist"] &&
             ![file containsString:@"entitlements"] &&
             ![file containsString:@"Entitlements"]) {
        [filesToZip addObject:file];
    }
}
```

## 兼容性

- ✅ 支持iOS 8.0+
- ✅ 支持macOS 10.9+
- ✅ 兼容Xcode 8.0+
- ✅ 符合App Store审核要求

## 注意事项

1. **备份原始文件**: 在使用重签名工具前，请务必备份原始IPA文件
2. **证书有效性**: 确保使用的开发者证书有效且未过期
3. **Bundle ID**: 如果更改Bundle ID，确保与Provisioning Profile匹配
4. **测试安装**: 在正式发布前，请在测试设备上验证应用能够正常安装和运行

## 常见问题

### Q: 重签名后的应用无法安装？
A: 请检查：
- 开发者证书是否有效
- Provisioning Profile是否匹配
- Bundle ID是否正确
- 使用测试脚本验证IPA结构

### Q: 如何验证修复是否生效？
A: 使用提供的 `test_ipa_structure.sh` 脚本测试生成的IPA文件，确保看到所有 ✓ 标记。

---

**修复版本**: 2024年12月
**兼容原版本**: iReSign v1.0+
