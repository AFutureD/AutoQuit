# AutoQuit

## 自动更新

AutoQuit 使用 Sparkle 2。用户可以从菜单栏选择“Check for Updates…”，更新源是 GitHub Releases 中最新版本附带的 `appcast.xml`。

Sparkle 更新公钥保存在 App 的 Info.plist；对应私钥必须只保存在维护者钥匙串和 GitHub Actions Secret `SPARKLE_PRIVATE_ED_KEY` 中，不能提交到仓库。

## GitHub tag 发布

推送格式为 `vMAJOR.MINOR.PATCH` 的 tag 后，[Release workflow](.github/workflows/release.yml) 会：

1. 构建通用 macOS Release，并通过 Xcode 云托管的 `Developer ID Application` 证书签名。
2. 提交 Apple 公证并装订公证票据。
3. 生成经过 Sparkle EdDSA 签名的 ZIP 和 `appcast.xml`。
4. 创建 GitHub Release，上传 ZIP 与 appcast。

在 App Store Connect 创建具有云托管 Developer ID 证书访问权限的 Team API Key，并在仓库 `Settings > Secrets and variables > Actions` 中配置：

- `APP_STORE_CONNECT_API_KEY_P8_BASE64`：Team API Key `.p8` 文件的 Base64 内容。
- `APP_STORE_CONNECT_API_KEY_ID`：App Store Connect 显示的 Key ID。
- `APP_STORE_CONNECT_API_KEY_ISSUER_ID`：App Store Connect 显示的 Issuer ID。
- `SPARKLE_PRIVATE_ED_KEY`：与 App 中 `SUPublicEDKey` 配对的 Sparkle 私钥。

将 `.p8` 转成 Secret 内容：

```sh
base64 -i AuthKey_KEYID.p8 | pbcopy
```

`.p8` 同时用于 Xcode 云签名认证和 Apple 公证认证，不能提交到仓库。Individual API Key 不能用于 `notarytool`，必须使用 Team API Key。

确认代码、版本和文档已经由人工审核后，推送发布 tag：

```sh
git tag v1.1.0
git push origin v1.1.0
```

workflow 使用 tag 的 `1.1.0` 同时作为用户可见版本和 Sparkle 比较用的构建版本。签名、公证或 appcast 生成失败时，发布步骤不会开始；如果发布步骤本身失败，应检查并清理可能残留的不完整 Release。

## 本地发布验证

项目使用 Developer ID 在 Mac App Store 外分发，并保留 Hardened Runtime。本地脚本会依次归档、使用 `Developer ID Application` 导出、提交 Apple 公证、装订公证票据并生成 ZIP。

1. 在钥匙串中安装团队 `8GSN8K4KD9` 的 `Apple Development` 和 `Developer ID Application` 证书及私钥。
2. 保存一次公证凭据：

   ```sh
   xcrun notarytool store-credentials AutoQuit-notary \
     --apple-id "你的 Apple ID" \
     --team-id 8GSN8K4KD9 \
     --password "App 专用密码"
   ```

3. 构建发布包：

   ```sh
   NOTARYTOOL_PROFILE=AutoQuit-notary ./scripts/release.sh
   ```

产物保存在 `build/releases/<时间戳>/`。不设置 `NOTARYTOOL_PROFILE` 时，脚本只生成经过 Developer ID 签名的 `.app`，不会提交公证，也不会生成 Sparkle appcast。

如果导出时报 `errSecInternalComponent`，请先在钥匙串中允许 `/usr/bin/codesign` 访问 Developer ID 私钥，或重新导入包含私钥的 `.p12`，再重试脚本。
