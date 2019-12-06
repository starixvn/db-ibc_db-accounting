USE [CustDB]
GO

ALTER TRIGGER [dbo].[Acc_GroupExtraPTSetting_INSERT] ON [dbo].[Acc_GroupExtraPTSetting]
AFTER INSERT
AS

/*
	Created: 20180831@Sophia
	DB: DBCUST.CUSTDB

	Revisions:
		- 20180831@Sophia: Copy data from Acc_GroupExtraPTSetting to Acc_GroupExtraCommRateSetting for Poker Games [RedmineID: #100168]
		- 20191201@Percy: Remove Poker Games (inactive products), add UplineId (CN88) [RedmineID: #]
*/

BEGIN
	SET NOCOUNT ON
	
	IF EXISTS (SELECT 1 FROM INSERTED WHERE UplineId IS NULL)
	BEGIN
		DECLARE @UplineId INT
		SELECT  @UplineId = s.UplineId
		FROM dbo.CustSuper s WITH (NOLOCK)
			INNER JOIN INSERTED i ON s.custid = i.SuperId
		WHERE s.UplineId IS NOT NULL

		IF @@ROWCOUNT <> 0
		BEGIN
			UPDATE e WITH (ROWLOCK)
			SET e.UplineId = @UplineId
			FROM dbo.Acc_GroupExtraPTSetting e
				INNER JOIN INSERTED i
					ON		e.SuperId		= i.SuperId
						AND e.GroupId		= i.GroupId
						AND e.ProductId		= i.ProductId
						AND e.Sporttype		= i.Sporttype
						AND e.SubProduct	= i.SubProduct
						AND e.FromDate		= i.FromDate
		END
	END
END
GO