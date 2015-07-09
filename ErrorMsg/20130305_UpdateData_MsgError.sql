UPDATE MsgError WITH (UPDLOCK,ROWLOCK)
SET MsgNameEN = N'Max bet must be equal to or less than upline max bet',
	MsgNameCT = N'Max bet must be equal to or less than upline max bet',
	MsgNameCS = N'Max bet must be equal to or less than upline max bet',
	MsgNameJP = N'Max bet must be equal to or less than upline max bet',
	MsgNameTH = N'Max bet must be equal to or less than upline max bet',
	MsgNameKO = N'Max bet must be equal to or less than upline max bet',
	MsgNameES = N'Max bet must be equal to or less than upline max bet',
	MsgNameVI = N'Tiền cược lớn nhất của người chơi phải nhỏ hơn hoặc bằng cấp trên.'
WHERE MsgID = 10025

UPDATE MsgError WITH (UPDLOCK,ROWLOCK)
SET MsgNameEN = N'Max Per Match must be equal to or less than Upline Max Per Match',
	MsgNameCT = N'Max Per Match must be equal to or less than Upline Max Per Match',
	MsgNameCS = N'Max Per Match must be equal to or less than Upline Max Per Match',
	MsgNameJP = N'Max Per Match must be equal to or less than Upline Max Per Match',
	MsgNameTH = N'Max Per Match must be equal to or less than Upline Max Per Match',
	MsgNameKO = N'Max Per Match must be equal to or less than Upline Max Per Match',
	MsgNameES = N'Max Per Match must be equal to or less than Upline Max Per Match',
	MsgNameVI = N'Tiền cược lớn nhất cho mỗi trận đấu của người chơi phải nhỏ hơn hoặc bằng cấp trên.'
WHERE MsgID = 10026 