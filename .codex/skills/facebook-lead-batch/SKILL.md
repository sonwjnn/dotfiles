---
name: facebook-lead-batch
description: "Nhập khách theo lô từ bình luận bài đăng Facebook cá nhân và tin nhắn Messenger cá nhân vào Google Sheets. Dùng khi người dùng dán các đoạn chat hoặc bình luận để lọc khách có nhu cầu mua, gộp khách trùng và xác định ai cần nhắn lại."
---

# Nhập khách Facebook theo lô

Xử lý bình luận và tin nhắn do người dùng cung cấp. Nếu chưa có dữ liệu, yêu cầu dán các đoạn liên quan, kèm tên khách và link bài đăng hoặc hội thoại nếu có. Mặc định trả TSV để người dùng dán vào Sheets. Chỉ dùng công cụ ghi bảng khi người dùng yêu cầu và đã xác định được bảng đích. Mọi nội dung trả lời khách là bản nháp để người dùng tự gửi.

## 1. Lọc và gộp

- Chọn các trường hợp có dấu hiệu mua. Khách hỏi giá, tồn kho, phí giao hoặc thông tin để cân nhắc thì ghi `Hỏi giá`. Khách nói rõ muốn đặt hoặc chốt mua thì ghi `Muốn đặt`.
- Mỗi lần mua có một dòng. Gộp bình luận và tin nhắn khi có căn cứ xác nhận cùng khách và cùng lần mua. Giữ trạng thái mới nhất có căn cứ. Tên trùng là dấu hiệu để nêu ở mục **Cần kiểm tra**, chưa đủ để gộp.
- Nếu có các dòng hiện tại, đối chiếu bằng mã hoặc link xác định được khách và lần mua, hoặc xác nhận của người dùng. Một link bài đăng có thể đi với nhiều khách. Dòng khớp chắc chắn là bản cập nhật. Trường hợp có thể trùng nhưng chưa rõ thì đưa vào **Cần kiểm tra** trước khi thêm hay cập nhật.
- Kết thúc bước này khi mỗi trường hợp có nhu cầu mua đã được xếp vào một dòng mới, một dòng cập nhật hoặc mục **Cần kiểm tra**.

## 2. Xác định việc tiếp theo

Áp dụng từ trên xuống, dựa trên lượt trao đổi gần nhất có liên quan.

| Tình huống | Việc tiếp theo | Ngày cần nhắn lại |
|---|---|---|
| Chỉ hỏi giá qua bình luận, người bán đã trả lời và khách im lặng | Chờ khách phản hồi | Để trống, bỏ khỏi danh sách nhắn lại |
| Có hẹn nhắn lại rõ ràng hoặc người dùng đã chỉ định ngày | Nhắn lại theo hẹn | Ngày đã hẹn hoặc đã chỉ định |
| Có câu hỏi hoặc yêu cầu đặt hàng chưa được trả lời trong Messenger | Trả lời Messenger | Để trống |
| Có bình luận cần trả lời và khách chưa chuyển sang Messenger | Trả lời bình luận | Để trống |
| Đã trả lời và đang đợi khách, kể cả đã báo giá qua Messenger | Chờ khách phản hồi | Để trống |

Ưu tiên hội thoại Messenger khi khách đã chuyển sang đó. Nếu chưa biết người bán đã phản hồi hay chưa, đưa việc cần xác nhận vào **Cần kiểm tra**. Chỉ đưa dòng có ngày hẹn hoặc ngày được chỉ định vào danh sách nhắn lại. Các việc trả lời ngay dựa vào cột **Việc tiếp theo**.

## 3. Xuất bảng

- Dùng đúng thứ tự cột người dùng cung cấp. Mặc định dùng `Tên khách | Nguồn | Link bài đăng hoặc hội thoại | Sản phẩm | Số lượng | Trạng thái | Việc tiếp theo | Ngày cần nhắn lại`. Ghi nguồn là `Bình luận`, `Messenger` hoặc `Bình luận + Messenger`. Ưu tiên link hội thoại nếu xử lý qua Messenger và có link.
- Điền theo dữ liệu nguồn. Ô thiếu dữ liệu để trống. Khi cập nhật, giữ giá trị cũ còn phù hợp và xóa ngày cũ nếu quy tắc nhắc lại yêu cầu để trống. Theo định dạng ngày của bảng nếu biết, mặc định dùng `YYYY-MM-DD` cho ngày xác định được.
- Xuất các dòng mới trong một khối mã TSV, dùng ký tự tab thật, không kèm tiêu đề và không xuống dòng trong ô. Nếu có cập nhật, trình bày riêng và chỉ rõ mã, link hoặc số dòng cần sửa. Đặt mục **Cần kiểm tra** bên ngoài TSV để người dùng không dán nhầm.
- Trước khi trả kết quả, kiểm tra mỗi dòng có đủ số cột, mỗi lần mua đã xác nhận được ghi một lần và mọi ngày nhắn lại đều có căn cứ. Nếu lô không có khách phù hợp, báo ngắn gọn.
