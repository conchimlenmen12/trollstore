# Hướng dẫn: Push code lên GitHub và tự build ra .ipa/.tar

Repo này đã có sẵn 1 pipeline GitHub Actions (`.github/workflows/build.yml`) tự động build:
- **CheatTrollStore** → ra file `TrollStore.tar`
- **CheatiOSVipStallerX** (TrollInstallerX) → ra file `.ipa`, đã tự động nhúng đúng `TrollStore.tar` vừa build ở trên

Bạn không cần máy Mac, không cần cài Xcode/theos gì cả — mọi thứ chạy trên server của GitHub (macOS runner miễn phí).

## 1. Chuẩn bị

- Có sẵn 1 tài khoản GitHub.
- Có sẵn 1 repository (ví dụ: `github.com/<ten-tai-khoan>/trollstore`) — nếu chưa có, vào GitHub bấm **New repository** để tạo (để **Private** nếu không muốn công khai).
- Cài Git trên máy: [git-scm.com/downloads](https://git-scm.com/downloads)

## 2. Đưa code lên GitHub lần đầu

Mở terminal (PowerShell/CMD/Git Bash) tại thư mục project này rồi chạy:

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<ten-tai-khoan>/<ten-repo>.git
git push -u origin main
```

> Nếu repo đã có sẵn (đã từng `git init`/`git remote add` rồi) thì bỏ qua bước này, dùng thẳng mục 3.

## 3. Mỗi lần sửa code xong, đẩy lên để build

```bash
git add .
git commit -m "Mô tả ngắn gọn thay đổi"
git push origin main
```

Chỉ cần `git push` lên nhánh `main` là GitHub Actions **tự động chạy build** — không cần làm gì thêm.

## 4. Cách xem build đang chạy / đã xong chưa

1. Vào trang repo trên GitHub → tab **Actions** (nằm ngang hàng với Code, Issues, Pull requests...).
2. Sẽ thấy danh sách các lần chạy, tên là **"Build TrollStore #<số>"**.
3. Bấm vào lần chạy mới nhất để xem chi tiết:
   - 🟡 **Đang chạy** (vòng tròn vàng xoay) — đợi thêm, thường mất 2-4 phút.
   - ✅ **Success** (dấu tích xanh) — build xong, có thể tải file.
   - ❌ **Failure** (dấu X đỏ) — build lỗi, bấm vào để xem log chi tiết dòng nào báo lỗi.

## 5. Cách build lại mà không cần sửa code gì (trigger thủ công)

Cách 1 — qua giao diện GitHub:
1. Vào tab **Actions** → chọn workflow **"Build TrollStore"** ở cột trái.
2. Bấm nút **"Run workflow"** ở góc phải → chọn nhánh `main` → bấm **"Run workflow"** màu xanh.

Cách 2 — tạo 1 commit rỗng rồi push (không đổi file nào):
```bash
git commit --allow-empty -m "Trigger rebuild"
git push origin main
```

## 6. Tải file build về

1. Vào tab **Actions** → bấm vào lần chạy đã **Success**.
2. Kéo xuống mục **Artifacts** ở cuối trang, sẽ thấy 3 file:
   - **`TrollInstallerX-ipa`** → chứa `TrollInstallerX.ipa` (chính là **CheatiOSVipStallerX**) — dùng để **cài lần đầu** trên máy chưa có TrollStore. Sideload file này bằng công cụ sideload thông thường (AltStore, Sideloadly...), mở app lên bấm cài là ra CheatTrollStore.
   - **`TrollStore-tar`** → chỉ chứa `TrollStore.tar` — dùng khi máy **đã có TrollStore rồi** và muốn **cập nhật** lên bản mới nhất (mở file `.tar` này bằng chính app TrollStore đang có trên máy để tự update).
   - **`TrollStore-build`** → giống `TrollStore-tar` nhưng có thêm file `.deb` (bản TrollStoreLite, dùng cho máy có AppSync Unified — thường không cần dùng tới).
3. Bấm vào tên file để tải file `.zip` về máy, giải nén ra là có file `.ipa`/`.tar` thật.

## 7. Cấu trúc repo (để biết sửa ở đâu)

| Thư mục | Là gì |
|---|---|
| `TrollStore/` | Code app CheatTrollStore (Objective-C, UIKit) |
| `TrollStoreLite/` | Bản Lite (dùng chung code với TrollStore, không cần sửa riêng) |
| `RootHelper/` | Tiến trình chạy quyền root, xử lý cài/gỡ app, dọn rác... |
| `Shared/` | Code dùng chung giữa TrollStore/TrollStoreLite/RootHelper |
| `TrollInstallerX/` | Code app CheatiOSVipStallerX (Swift, SwiftUI) — app cài đặt lần đầu |
| `.github/workflows/build.yml` | File cấu hình pipeline build tự động |

## 8. Nếu build bị lỗi (Failure)

1. Bấm vào lần chạy bị lỗi trong tab Actions.
2. Bấm vào job bị lỗi (`build-trollstore` hoặc `build-trollinstallerx`).
3. Kéo tới bước (step) có dấu ❌, bấm mở rộng để đọc dòng lỗi màu đỏ — thường sẽ ghi rõ file và dòng code gây lỗi (ví dụ `error: use of undeclared identifier...`).
4. Sửa lỗi đó trong code, `git commit` + `git push` lại, workflow tự chạy lại.
