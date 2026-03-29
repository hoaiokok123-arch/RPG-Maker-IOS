# RPGPlayerClone

Scaffold iOS cho ứng dụng `RPGPlayer Clone`, định hướng chạy game RPG Maker 2000/2003, XP, VX, VX Ace, MV và MZ.

Lưu ý quan trọng:

- Thư mục này ban đầu là thư mục trắng.
- Máy hiện tại không có Xcode/macOS, vì vậy tôi tạo `project.yml` để sinh `RPGPlayerClone.xcodeproj` bằng XcodeGen trên macOS.
- `mkxp-z` hiện không có target iOS sẵn trong repo gốc; phần native bridge trong source là khung tích hợp để bạn gắn framework/bridge sau khi tự port.
- `EasyRPG Player` cũng chưa có target iOS chính thức trong repo gốc; phần tài liệu build là lộ trình porting thực tế, không phải một lệnh chính thức upstream.

## Cấu trúc thư mục

```text
RPGMaker/
├─ Docs/
│  └─ ENGINE_BUILD_GUIDE.vi.md
├─ RPGPlayerClone/
│  ├─ App/
│  │  ├─ AppDelegate.swift
│  │  └─ RPGPlayerCloneApp.swift
│  ├─ Assets.xcassets/
│  │  ├─ AppIcon.appiconset/
│  │  └─ GameCoverPlaceholder.imageset/
│  ├─ Engines/
│  │  ├─ EasyRPGWrapper.swift
│  │  ├─ GameEngineManager.swift
│  │  ├─ MKXPZWrapper.swift
│  │  ├─ NativeEngineBridgeLoader.swift
│  │  └─ WebGameViewController.swift
│  ├─ Models/
│  │  ├─ GameModel.swift
│  │  └─ GameType.swift
│  ├─ Resources/
│  │  └─ VirtualGamepad/
│  │     ├─ README.md
│  │     ├─ control-map.json
│  │     ├─ gamepad.css
│  │     └─ gamepad.js
│  ├─ Services/
│  │  ├─ FileImporter.swift
│  │  ├─ GameControllerMonitor.swift
│  │  ├─ GameInputDispatcher.swift
│  │  └─ GameLibraryStore.swift
│  ├─ Utils/
│  │  ├─ FileManager+Extensions.swift
│  │  ├─ GameDetector.swift
│  │  └─ VirtualGamepadResourceLoader.swift
│  ├─ ViewModels/
│  │  └─ GameLibraryViewModel.swift
│  ├─ Views/
│  │  ├─ GameLibraryView.swift
│  │  ├─ SettingsView.swift
│  │  └─ VirtualGamepadView.swift
│  ├─ Info.plist
│  └─ RPGPlayerClone.entitlements
├─ Scripts/
│  ├─ build_engines.sh
│  └─ copy_virtualgamepad.sh
├─ Podfile
├─ project.yml
├─ README.md
└─ RPGPlayerClone-Bridging-Header.h
```

## Tạo project Xcode trên macOS

1. Cài Xcode, Homebrew, XcodeGen và CocoaPods:

   ```bash
   brew install xcodegen cocoapods
   ```

2. Sinh project:

   ```bash
   xcodegen generate
   ```

3. Cài pods:

   ```bash
   pod install
   ```

4. Mở workspace:

   ```bash
   open RPGPlayerClone.xcworkspace
   ```

## Build Bằng GitHub Actions

Bạn không cần máy Mac cá nhân nếu dùng GitHub-hosted macOS runner.

### Workflow có sẵn

- `.github/workflows/ios-ci.yml`
  - Build app cho `iOS Simulator`
  - Không cần signing
  - Upload artifact `.app` của simulator và log build

- `.github/workflows/ios-signed-archive.yml`
  - Chạy thủ công bằng `workflow_dispatch`
  - Archive và export `.ipa`
  - Cần secret Apple signing

### Secret cần có cho workflow signed archive

- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `BUILD_PROVISION_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`
- `DEVELOPMENT_TEAM`
- `APP_BUNDLE_IDENTIFIER`
- `PROVISIONING_PROFILE_SPECIFIER` (tùy chọn, nên thêm nếu automatic signing chọn sai profile)

### Gem dùng cho CI

- `Gemfile` đã thêm:
  - `cocoapods`
  - `xcpretty`

## Dependency đã chọn

- `SSZipArchive` cho `.zip`
- `UnrarKit` cho `.rar`

## File hướng dẫn

- Tài liệu build engine, checklist và ghi chú kỹ thuật: `Docs/ENGINE_BUILD_GUIDE.vi.md`
