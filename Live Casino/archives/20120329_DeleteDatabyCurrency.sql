/*
	Created by: Jamie 
	Date: 2012-03-20 
	Task: DELTE ALL ACCOUNTS UNDER particular currency 
	DB: DBTRANS.bodb02 


*/

--1. 

	/*
	ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@currency INT 
	AS

	BEGIN	
		SET NOCOUNT ON	

		IF (SELECT COUNT(1) FROM sys.objects WHERE NAME IN ('CustSettingGame','CustoverrideGame','custinfo') AND TYPE = 'u') <> 3
			RETURN

		WHILE 1 = 1 
		BEGIN
			DELETE TOP(10000) CustSettingGame WITH(ROWLOCK,UPDLOCK)
			WHERE CustID IN (	SELECT	CustID 
								FROM	custInfo WITH (NOLOCK) 
								WHERE	currency = @currency 
						)
			IF @@ROWCOUNT <> 10000
				BREAK
		END

		WHILE 1 = 1 
		BEGIN
			DELETE TOP(10000) CustoverrideGame WITH(ROWLOCK,UPDLOCK)
			WHERE CustID IN (	SELECT	CustID 
								FROM	custInfo WITH (NOLOCK) 
								WHERE	currency = @currency 
						)
			IF @@ROWCOUNT <> 10000
				BREAK
		END
		
	END

	*/


-- Run Script 1 - Acc_ExecRep_09  first 

DECLARE @currency INT 
SELECT	@currency = XXX 

EXEC dbo.Acc_ExecRep_09 @currency = @currency


