UPDATE MsgError WITH(UPDLOCK,ROWLOCK) 
SET MsgNameVI = N'Không thể kích hoạt nhân đôi hoa hồng cho những ticket bị thua của tài khoản này bởi vì tài khoản cấp trên chưa được kích hoạt tính năng đó.', 
	MsgNameTH = N'Cannot update double commission status for this customer because the upline is not enabled.',
	MsgNameKO = N'Cannot update double commission status for this customer because the upline is not enabled.',
	MsgNameJP = N'Cannot update double commission status for this customer because the upline is not enabled.',
	MsgNameCS = N'Cannot update double commission status for this customer because the upline is not enabled.',
	MsgNameCT = N'Cannot update double commission status for this customer because the upline is not enabled.',
	MsgNameEN = N'Cannot update double commission status for this customer because the upline is not enabled.'	 
WHERE MsgID = 60021

UPDATE MsgError WITH(UPDLOCK,ROWLOCK) 
SET MsgNameVI = N'Không thể mở chức năng Live Casino vì những thiết lập cho Live Casino chưa được thực hiện ở tài khoản này.', 
	MsgNameJP = N'Cannot enable live casino for this account due to lack of settings.',
	MsgNameEN = N'Cannot enable live casino for this account due to lack of settings.'	 
WHERE MsgID = 60022	

UPDATE MsgError WITH(UPDLOCK,ROWLOCK) 
SET MsgNameVI = N'Không thể mở chức năng Live Casino vì tài khoản cấp trên chưa được kích hoạt tính năng này hoặc thiết lập cho Live Casino chưa được thực hiện.', 
	MsgNameJP = N' Cannot enable Live Casino because the upline either has Live Casino disaled or does not have any settings.'	,
	MsgNameEN = N' Cannot enable Live Casino because the upline either has Live Casino disaled or does not have any settings.'
WHERE MsgID = 60023	

UPDATE MsgError WITH(UPDLOCK,ROWLOCK) 
SET MsgNameVI = N'Không thể mở chức năng Bingo vì thiết lập cho Bingo chưa được thực hiện ở tài khoản này.', 
	MsgNameKO = N'Cannot enable Bingo for this account due to lack of settings.',
	MsgNameJP = N'Cannot enable Bingo for this account due to lack of settings.',
	MsgNameEN = N'Cannot enable Bingo for this account due to lack of settings.'
WHERE MsgID = 60024

UPDATE MsgError WITH(UPDLOCK,ROWLOCK) 
SET MsgNameVI = N'Không thể mở chức năng Bingo vì tài khoản cấp trên chưa được kích hoạt tính năng này hoặc thiết lập cho Bingo chưa được thực hiện.', 
	MsgNameKO = N'Cannot enable Bingo because the upline either has Bingo disaled or does not have any settings.',
	MsgNameJP = N'Cannot enable Bingo because the upline either has Bingo disaled or does not have any settings.',
	MsgNameEN = N'Cannot enable Bingo because the upline either has Bingo disaled or does not have any settings.'	 
WHERE MsgID = 60025	

UPDATE MsgError WITH(UPDLOCK,ROWLOCK) 
SET MsgNameVI = N'Không thể mở chức năng Casino vì thiết lập cho Casino  chưa được thực hiện ở tài khoản này.', 
	MsgNameKO = N'Cannot enable Casino for this account due to lack of settings.',	 
	MsgNameJP = N'Cannot enable Casino for this account due to lack of settings.',
	MsgNameEN = N'Cannot enable Casino for this account due to lack of settings.'
WHERE MsgID = 60026	

UPDATE MsgError WITH(UPDLOCK,ROWLOCK) 
SET MsgNameVI = N'Không thể mở chức năng  Casino vì tài khoản cấp trên chưa được kích hoạt tính năng này hoặc thiết lập cho Casino chưa được thực hiện.', 
	MsgNameKO = N'Cannot enable Casino because the upline either has Casino disaled or does not have any settings.',	 
	MsgNameJP = N'Cannot enable Casino because the upline either has Casino disaled or does not have any settings.',
	MsgNameEN = N'Cannot enable Casino because the upline either has Casino disaled or does not have any settings.'
WHERE MsgID = 60027	

UPDATE MsgError WITH(UPDLOCK,ROWLOCK) 
SET MsgNameVI = N'Không thể đồng bộ hóa Live Casino bởi vì tài khoản cấp trên chưa được đồng bộ hóa.'
WHERE MsgID = 60028