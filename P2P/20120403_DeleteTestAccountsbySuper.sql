 /*
	Created by: Jamie 
	Date: 2012-04-03 
	Task: P2P -  DELTE ALL ACCOUNTS UNDER particular Super 
	DB: DBTRANS.bodb02 


*/

--1. 

	
	ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@SRecommend INT 
	AS

	BEGIN	
		SET NOCOUNT ON	

		IF (SELECT COUNT(1) FROM sys.objects WHERE NAME IN ('P2PGameSetting','P2PGroupComm','custinfo') AND TYPE = 'u') <> 3
			RETURN

		WHILE 1 = 1 
		BEGIN
			DELETE TOP(10000) P2PGroupComm WITH(ROWLOCK)
			WHERE CustID IN (	SELECT	CustID 
								FROM	custInfo WITH (NOLOCK) 
								WHERE	SRecommend = @SRecommend 
							)
			IF @@ROWCOUNT <> 10000
				BREAK
		END

		WHILE 1 = 1 
		BEGIN
			DELETE TOP(10000) P2PGameSetting WITH(ROWLOCK)
			WHERE CustID IN (	SELECT	CustID 
								FROM	custInfo WITH (NOLOCK) 
								WHERE	SRecommend = @SRecommend
							) 
			IF @@ROWCOUNT <> 10000
				BREAK
		END
		
	END

	


-- Run Script 1 - Acc_ExecRep_09  first 

DECLARE @SRecommend INT 
SELECT	@SRecommend = 615976 -- ACGUUS 615976 ;SA-UUS 20

EXEC dbo.Acc_ExecRep_09 @SRecommend = @SRecommend