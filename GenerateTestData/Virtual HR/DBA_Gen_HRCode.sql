 ALTER PROCEDURE DBA_Gen_HRCode		
	@CodeType TINYINT = 11
AS
BEGIN	
	INSERT INTO HRCode (CodeType, VendorID, CodeNameEn, CodeNameCh, CodeNameCs, CodeDesc, IsActive, Creator, CreateDate, Modifier, ModifyDate)
	SELECT top 11 @CodeType, VendorID, CodeNameEn, CodeNameCh, CodeNameCs, CodeDesc, IsActive, 181, getdate(), Modifier, ModifyDate
	FROM HRCode WITH (NOLOCK)
	WHERE CodeType = @CodeType - 10
END	
-- EXEC DBA_Gen_HRCode @CodeType = 11