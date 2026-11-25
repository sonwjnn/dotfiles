# Giảm độ trễ khi căn giữa cửa sổ nổi trong AeroSpace

Cấu hình hiện dùng executable `bin/center-app`. Chạy `build.sh` sau khi sửa mã Swift. Phần dưới ghi lại cấu hình trước khi tối ưu và kết quả đo.

## Đường chạy hiện tại

Hai rule phát hiện cửa sổ của Steam helper và Ghostty gọi `layout floating`, rồi chạy `/usr/bin/swift center-app.swift` mỗi lần khớp. Kích thước yêu cầu lần lượt là 1500 × 900 và 1200 × 650. Swift tìm cửa sổ theo bundle ID, ưu tiên cửa sổ đang focus rồi dùng cửa sổ đầu tiên nếu cần. Helper chọn màn hình theo tâm cửa sổ, đặt kích thước, đọc lại kích thước thực tế mà ứng dụng chấp nhận rồi căn giữa theo khung màn hình. Khi một app vừa mở chưa đưa cửa sổ ra Accessibility, helper có tối đa 15 lượt thử. [Hai rule](/Users/sonwin/.config/aerospace/aerospace.toml:266), [mã helper](/Users/sonwin/.config/aerospace/center-app/center-app.swift:65), [callback AeroSpace](https://nikitabobko.github.io/AeroSpace/guide#on-window-detected).

## Phần thời gian có thể bỏ

Chạy một file nguồn bằng `swift` đưa công cụ Swift vào đường mở cửa sổ. Có thể dùng `swiftc -O center-app.swift -o center-app` để tạo executable một lần, sau đó rule gọi trực tiếp executable với cùng tham số. Mỗi lần sửa Swift mới cần biên dịch lại. [Tài liệu trình điều khiển Swift](https://github.com/swiftlang/swift/blob/main/docs/Driver.md).

Trên máy hiện tại, mỗi cách được gọi 5 lần với đối số thiếu để thoát mã 2 ngay trước phần AX. Biên dịch mất 2,261 giây, executable 59.832 byte. Lần chạy đầu tiên đo được 615 ms với script và 539 ms với executable. Trung vị các lần sau là 509 ms và 4 ms. Đây là số đo thời gian khởi động tới kiểm tra tham số, chưa đo độ trễ sắp xếp cửa sổ. Khoảng chờ 50 ms sau khi đặt kích thước và 100 ms sau mỗi lượt thử lỗi vẫn nằm trong helper. [Mã helper](/Users/sonwin/.config/aerospace/center-app/center-app.swift:102).

## Thay thế và điều cần giữ

- **Biên dịch trước là thay đổi ít nhất.** Helper vẫn làm việc qua Accessibility. Apple kiểm tra mức tin cậy của tiến trình, nên cần xác nhận quyền theo đường chạy thực tế từ AeroSpace sau khi đổi sang executable. Số đo khởi động không xác nhận quyền hay hiệu quả AX. [API kiểm tra quyền Accessibility](https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions).
- **CLI AeroSpace hiện tại không thay thế chức năng đặt khung.** Trong 0.21.3, `move` từ chối cửa sổ nổi và `resize` chỉ chọn node có cha dùng tiles. Các lệnh điều khiển focus, màn hình và layout giải quyết những thao tác khác. [MoveCommand](https://github.com/nikitabobko/AeroSpace/blob/d56e1637c3a1ed660d0cadd7534e94fb3218d1c3/Sources/AppBundle/command/impl/MoveCommand.swift#L19-L41), [ResizeCommand](https://github.com/nikitabobko/AeroSpace/blob/d56e1637c3a1ed660d0cadd7534e94fb3218d1c3/Sources/AppBundle/command/impl/ResizeCommand.swift#L7-L24).
- **Hammerspoon** có API đặt khung và căn giữa cửa sổ, cùng sự kiện tạo cửa sổ. Đây là một app chạy nền cần quyền Accessibility. Chỉ đáng cân nhắc nếu đã dùng Hammerspoon hoặc cần đưa nhiều quy tắc quản lý cửa sổ vào chung một chỗ. [hs.window](https://www.hammerspoon.org/docs/hs.window.html), [hs.window.filter](https://www.hammerspoon.org/docs/hs.window.filter.html).

Trường hợp cần xác nhận trước khi đổi cấu hình là mở Ghostty và Steam trên từng màn hình, kiểm tra kích thước sau khi app áp giới hạn riêng, rồi mở hai cửa sổ cùng bundle ID. Callback AeroSpace nhận ID cửa sổ vừa phát hiện, còn helper hiện tìm theo bundle ID và focus. Biên dịch trước giữ nguyên cách chọn đó. [Ngữ cảnh callback](https://nikitabobko.github.io/AeroSpace/guide#environment-variables), [hàm chọn cửa sổ](/Users/sonwin/.config/aerospace/center-app/center-app.swift:65).
