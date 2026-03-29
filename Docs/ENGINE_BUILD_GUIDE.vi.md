# Hướng dẫn build engine và ghi chú kỹ thuật

## 1. Build EasyRPG Player cho iOS

### Thực trạng

- Repo gốc `EasyRPG/Player` không có target iOS chính thức.
- `CMakeLists.txt` hiện build core dưới dạng object library và ghép thành executable ở các platform chính.
- Vì vậy, để dùng trong app iOS, bạn phải tự tạo lớp bridge hoặc framework bọc ngoài.

### Các file quan trọng từ repo EasyRPG Player

- `CMakeLists.txt`: mô tả target, dependency, Apple-specific sources.
- `docs/BUILDING.md`: tài liệu build chính thức.
- `src/`: mã nguồn engine.
- `src/platform/sdl/`: backend SDL hiện tại.
- `src/platform/macos/macos_utils.mm`
- `src/platform/macos/macos_utils.h`
- `src/platform/macos/midiout_device_coreaudio.cpp`
- `src/platform/macos/midiout_device_coreaudio.h`
- `resources/shared/easyrpg.ini`
- `resources/rtp_table/RTP2k.csv`
- `resources/rtp_table/RTP2k3.csv`
- `resources/exfont.png`
- `resources/macos/Info.plist.in`
- `builds/cmake/Modules/*`

### Chuẩn bị máy macOS

1. Cài Homebrew nếu chưa có.
2. Cài toolchain cơ bản:

   ```bash
   brew install cmake ninja pkg-config autoconf automake libtool
   ```

3. Chuẩn bị dependency native:

   ```bash
   brew install sdl2 pixman libpng fmt
   ```

4. Clone repo:

   ```bash
   git clone https://github.com/EasyRPG/Player
   cd Player
   ```

### Hướng build iOS khả thi

Đây là quy trình porting, không phải lệnh chính thức từ upstream:

1. Tạo build thư mục iOS:

   ```bash
   mkdir build-ios
   ```

2. Cấu hình CMake với iOS SDK:

   ```bash
   cmake -S . -B build-ios -G Xcode \
     -DCMAKE_SYSTEM_NAME=iOS \
     -DCMAKE_OSX_SYSROOT=iphoneos \
     -DCMAKE_OSX_ARCHITECTURES=arm64 \
     -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
     -DPLAYER_TARGET_PLATFORM=SDL2 \
     -DPLAYER_BUILD_EXECUTABLE=OFF \
     -DBUILD_SHARED_LIBS=OFF
   ```

3. Build thử:

   ```bash
   cmake --build build-ios --config Release
   ```

### Điểm bạn sẽ phải tự xử lý

- Upstream chưa xuất ra iOS framework sẵn.
- Core hiện là object library, nên bạn sẽ phải:
  - thêm một static library target hoặc framework target bọc lại object files,
  - viết Objective-C/Objective-C++ shim để expose API cho Swift,
  - gắn SDL/iOS event loop và lifecycle phù hợp với `UIViewController`.

### Cách nhúng vào Xcode project

1. Sau khi bạn có `EasyRPGPlayer.xcframework`, kéo vào project hoặc workspace.
2. Đặt vào `Frameworks, Libraries, and Embedded Content`.
3. Tạo bridge native, ví dụ:
  - `ERPCreateViewController(NSString *gamePath)`
  - `ERPSendInput(NSInteger button, BOOL pressed)`
  - `ERPShutdown()`
4. Trong file `EasyRPGWrapper.swift`, gắn bridge thật vào `EasyRPGBridgeRegistry.bridge`.

## 2. Build mkxp-z cho iOS

### Thực trạng

- Repo `mkxp-z/mkxp-z` hiện có thư mục `macos/`, không có thư mục `ios/`.
- `macos/setup.command` chỉ chạy `Dependencies/setup.sh`.
- `Dependencies/setup.sh` sẽ build dependency cho `arm64` và `x86_64`, rồi ghép thành bộ universal cho macOS.
- `macos/Dependencies/make_macuniversal.sh` còn ghi rõ đây là script cho macOS và chưa mở rộng cho iOS.

### Các file quan trọng từ repo mkxp-z

- `README.md`
- `macos/setup.command`
- `macos/Dependencies/setup.sh`
- `macos/Dependencies/Brewfile`
- `macos/Dependencies/make_macuniversal.sh`
- `macos/mkxp-z.xcodeproj`
- `macos/config/mkxp.Universal.xcconfig`
- `macos/config/mkxp.xcconfig`
- `src/`
- `binding/`

### Build đúng theo repo gốc trên macOS

1. Clone repo:

   ```bash
   git clone --branch dev https://github.com/mkxp-z/mkxp-z
   cd mkxp-z/macos
   ```

2. Cài dependency build:

   ```bash
   brew bundle --file=Dependencies/Brewfile
   ```

3. Chạy setup:

   ```bash
   chmod +x setup.command
   ./setup.command
   ```

4. Mở project:

   ```bash
   open mkxp-z.xcodeproj
   ```

5. Trong Xcode, build scheme `Universal`.

### `setup.command` làm gì

- Xác định thư mục chứa script.
- `cd` vào `macos/Dependencies`.
- Chạy `./setup.sh`.

### `setup.sh` làm gì

- Kiểm tra version Xcode.
- Build dependency cho `arm64` nếu Xcode đủ mới.
- Build dependency cho `x86_64`.
- Chạy `make_macuniversal.sh` để ghép binary thành bộ universal macOS.
- Nếu có Steam SDK, script còn patch `libsteam_api.dylib`.

### Cách port sang iOS

Vì repo không có target iOS sẵn, lộ trình thực tế là:

1. Dùng `macos/mkxp-z.xcodeproj` làm mẫu kiến trúc.
2. Tạo target mới kiểu `Framework` hoặc `Static Library` cho iOS.
3. Chuyển toàn bộ phần phụ thuộc Cocoa/AppKit trong `macos/` sang UIKit.
4. Build lại dependency cho `iphoneos` và `iphonesimulator`.
5. Tạo `MKXPZ.xcframework` bằng `xcodebuild -create-xcframework`.

Ví dụ khung lệnh sau khi bạn đã có 2 framework hoặc static lib riêng cho `iphoneos` và `iphonesimulator`:

```bash
xcodebuild -create-xcframework \
  -framework build/Release-iphoneos/MKXPZ.framework \
  -framework build/Release-iphonesimulator/MKXPZ.framework \
  -output MKXPZ.xcframework
```

### Cách nhúng vào Xcode project

1. Kéo `MKXPZ.xcframework` vào project.
2. Đặt ở `Frameworks, Libraries, and Embedded Content`.
3. Expose bridge native, ví dụ:
  - `MKXPZCreateViewController(NSString *gamePath)`
  - `MKXPZSendInput(NSInteger button, BOOL pressed)`
  - `MKXPZShutdown()`
4. Gắn bridge thật vào `MKXPZBridgeRegistry.bridge` trong `MKXPZWrapper.swift`.

## 3. Chuẩn bị assets cho phím ảo từ easyrpg-web

### Các file nên lấy làm mẫu

- `www/index.html`
- `www/pre.js`
- `www/index.js`
- `www/orig.js`
- `www/post.js`
- `www/easyrpg-player.wasm`

### Ý nghĩa từng file

- `index.html`: layout, CSS, vị trí d-pad và action buttons.
- `pre.js`: hook trước khi EasyRPG web runtime khởi tạo.
- `index.js`: runtime web build sẵn.
- `orig.js`: logic touch/input gốc.
- `post.js`: phần save import/export, soundfont, utility UI.
- `easyrpg-player.wasm`: binary WebAssembly.

### Cách nhúng vào project này

1. Tạo thư mục resource riêng:

   ```text
   RPGPlayerClone/Resources/VirtualGamepad/
   ```

2. Copy hoặc tham chiếu cấu hình nút từ `index.html`.
3. Chuyển những phần bạn cần sang:
  - native Swift UI overlay trong `VirtualGamepadView.swift`,
  - hoặc JS injection trong `WebGameViewController.swift`.
4. Nếu bạn muốn chạy EasyRPG web trong `WKWebView`, bạn sẽ còn cần copy đầy đủ `index.js`, `orig.js`, `post.js`, `pre.js`, `easyrpg-player.wasm`.

## 4. Xử lý thách thức kỹ thuật

### Case-sensitive

- iOS dùng APFS, đa số máy chạy dạng case-insensitive, nhưng không nên dựa vào điều đó.
- Ở project scaffold này, `GameDetector` và `FileManager+Extensions` đã có helper dò file theo kiểu lowercased map.
- Khi import game, nên chuẩn hóa:
  - tên file đặc trưng,
  - tên thư mục `Audio`, `Data`, `Graphics`, `Save`, `www`.

### Chuyển đổi engine

- `GameEngineManager.shutdownCurrentEngine()` sẽ phát notification để wrapper giải phóng engine đang chạy.
- Khi đổi từ EasyRPG sang mkxp-z hoặc web engine:
  - dừng render loop,
  - tháo observer,
  - giải phóng audio/session,
  - xóa child view controller hiện tại.

### Xung đột thư viện

- Dùng `XCFramework` cho từng engine để cách ly binary.
- Không link thẳng source engine vào app target chính nếu chưa có namespace/bridge rõ ràng.
- Tạo Objective-C shim mỏng cho từng engine thay vì gọi lẫn lộn từ Swift.

### Phím ảo đồng nhất

- Scaffold này dùng `VirtualGamepadView` + `NotificationCenter`.
- Native wrappers và `WebGameViewController` cùng nghe chung notification:
  - EasyRPG bridge nhận event native,
  - mkxp-z bridge nhận event native,
  - web engine nhận event qua JS injection.

## 5. Checklist phát triển

- [ ] Cài đặt Xcode và Homebrew
- [ ] Chạy `xcodegen generate`
- [ ] Chạy `pod install`
- [ ] Mở `RPGPlayerClone.xcworkspace`
- [ ] Cấu hình `Info.plist` cho phép đọc file từ Documents
- [ ] Bật `UIFileSharingEnabled` và `LSSupportsOpeningDocumentsInPlace`
- [ ] Build và nhúng EasyRPG framework
- [ ] Build và nhúng mkxp-z framework
- [ ] Hoàn thiện Objective-C/Swift bridge cho EasyRPG
- [ ] Hoàn thiện Objective-C/Swift bridge cho mkxp-z
- [ ] Code `GameDetector` và test với game mẫu
- [ ] Code `GameLibraryView`
- [ ] Code `FileImporter`
- [ ] Code `VirtualGamepadView`
- [ ] Code `WebGameViewController`
- [ ] Tích hợp `GameController` framework cho gamepad vật lý
- [ ] Test trên thiết bị thật
- [ ] Tối ưu hiệu năng
- [ ] Chuẩn bị metadata và chính sách cho App Store

## 6. Tóm tắt file tham khảo từ 3 repo

### Từ EasyRPG Player

- `CMakeLists.txt`
- `docs/BUILDING.md`
- `src/`
- `src/platform/sdl/`
- `src/platform/macos/`
- `resources/shared/easyrpg.ini`
- `resources/rtp_table/RTP2k.csv`
- `resources/rtp_table/RTP2k3.csv`
- `resources/exfont.png`
- `resources/macos/Info.plist.in`

### Từ easyrpg-web

- `www/index.html`
- `www/pre.js`
- `www/index.js`
- `www/orig.js`
- `www/post.js`
- `www/easyrpg-player.wasm`

### Từ mkxp-z

- `macos/Dependencies/`
- `macos/config/`
- `macos/mkxp-z.xcodeproj`
- `macos/setup.command`
- `macos/Dependencies/setup.sh`
- `macos/Dependencies/make_macuniversal.sh`
- `src/`
- `binding/`

## 7. Nguồn gốc thông tin

- EasyRPG Player: <https://github.com/EasyRPG/Player>
- EasyRPG BUILDING: <https://github.com/EasyRPG/Player/blob/master/docs/BUILDING.md>
- easyrpg-web: <https://github.com/aidatorajiro/easyrpg-web>
- mkxp-z: <https://github.com/mkxp-z/mkxp-z>
- mkxp-z Compilation Wiki: <https://github.com/mkxp-z/mkxp-z/wiki/Compilation>
