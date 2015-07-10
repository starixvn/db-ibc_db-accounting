UPDATE MsgError SET MsgNameVI = N'Tài khoản không thể tham gia Play for Fun Poker Game. Không thể thay đổi thiết lập của thành viên cấp dưới.',
					MsgNameEN = N'Account disabled Play for Fun Poker Game. Unable to edit downlines.' WHERE MsgID = 60014
					
UPDATE MsgError SET MsgNameVI = N'Tài khoản không thể tham gia Poker Game. Không thể thay đổi thiết lập của thành viên cấp dưới.',
					MsgNameEN = N'Account disabled for Poker Game. Unable to edit downlines.' WHERE MsgID = 60013			
					
UPDATE MsgError SET MsgNameVI = N'Tài khoản này không được phép truy cập ở đây.' WHERE MsgID = 80003									

UPDATE MsgError SET MsgNameVI = N'Tài khoản này không thể tham gia Horse Racing. Không thể thay đổi thiết lập của thành viên cấp dưới.' WHERE MsgID = 60006			

UPDATE MsgError SET MsgNameVI = N'Tồn tại các member có giá trị PT vượt quá trị PT mới được thiết lập cho Agent.' WHERE MsgID = 20017														

UPDATE MsgError SET MsgNameVI = N'Sai giá trị: Tiền cược nhỏ nhất / Tiền cược lớn nhất / Tiền cược lớn nhất của mỗi trận đấu / Tiền cược lớn nhất cho mỗi banh' WHERE MsgID = 10004	

DELETE MsgError WHERE MsgID = 60018
DELETE MsgError WHERE MsgID = 70014

UPDATE MsgError SET MsgNameVI = N'Xin lỗi, việc gia tăng hạn mức tín dụng không thành công. Bạn đã vượt quá hạn mức được cho phép.' WHERE MsgID = 70003

Insert into MsgError (MsgID, MsgGroupID, MsgNameEN, MsgNameCT, MsgNameCS, MsgNameJP, MsgNameTH, MsgNameKO, MsgNameES, MsgNameVI, IsActive) values (80006,9,'Login Failed.', N'Login Failed.', N'Login Failed.', N'Login Failed.', N'Login Failed.', N'Login Failed.', N'Login Failed.', N'Đăng nhập thất bại.',1)