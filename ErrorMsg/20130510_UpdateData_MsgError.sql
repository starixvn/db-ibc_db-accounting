UPDATE MsgError WITH(UPDLOCK,ROWLOCK) 
SET MsgNameJP = N' Cannot enable Live Casino because the upline either has Live Casino disabled or does not have any settings.'	,
	MsgNameEN = N' Cannot enable Live Casino because the upline either has Live Casino disabled or does not have any settings.'
WHERE MsgID = 60023	

UPDATE MsgError WITH(UPDLOCK,ROWLOCK) 
SET MsgNameKO = N'Cannot enable Bingo because the upline either has Bingo disabled or does not have any settings.',
	MsgNameJP = N'Cannot enable Bingo because the upline either has Bingo disabled or does not have any settings.',
	MsgNameEN = N'Cannot enable Bingo because the upline either has Bingo disabled or does not have any settings.'	 
WHERE MsgID = 60025	

UPDATE MsgError WITH(UPDLOCK,ROWLOCK) 
SET MsgNameKO = N'Cannot enable Casino because the upline either has Casino disabled or does not have any settings.',	 
	MsgNameJP = N'Cannot enable Casino because the upline either has Casino disabled or does not have any settings.',
	MsgNameEN = N'Cannot enable Casino because the upline either has Casino disabled or does not have any settings.'
WHERE MsgID = 60027	