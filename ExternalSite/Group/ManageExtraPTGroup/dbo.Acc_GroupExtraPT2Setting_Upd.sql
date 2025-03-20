/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" isFunction="0" isNested="1"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Acc_GroupExtraPT2Setting_Upd]
(
	@Custid INT,
	@GroupId INT,
	@GroupName VARCHAR(50),
	@EffectiveDate	DATETIME = NULL,
	@Today DATETIME,
	@EndDate DATETIME
)	
AS
/*
	Creator: Sol
	Date: 20200716
	Task: Change Primary, Remove CustID from Extra PT Group
	DB: DBCUST.CustDB

	Revisions:
		- 20200708@Sol: Add/modify setting for new table - Extra PT - Redmine: [#136320]
		- 20210301@Percy: Change BC to real Extra PT Group [RedmineID: #146710]
		- 20250114@Lewis: Apply Rep-Inhouse [RedmineID: #215883]
		
	Param's Explanation:
		- @EffectiveDate
			+ IS NULL: remove @CustID from @GroupName
			+ NOT NULL: change @GroupName is Primary Extra PT Group of @CustID
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Setting TABLE (ID INT
							, SuperId INT
							, GroupId INT
							, ProductId TINYINT NOT NULL
							, Sporttype SMALLINT NOT NULL
							, SubProduct VARCHAR(500) NOT NULL
							, FromDate DATETIME NOT NULL
							, ToDate DATETIME
							, RepUpdateTime DATETIME2(7))

	IF @EffectiveDate IS NOT NULL -- change @GroupName is Primary Extra PT Group of @CustID
	BEGIN
		
		DELETE dbo.Acc_GroupExtraPT2Setting WITH(ROWLOCK, UPDLOCK)
			OUTPUT deleted.ID, [dbo].[f_GetDateTime2]()
			INTO Acc_GroupExtraPT2Setting_Del_InHouse (ID, RepUpdateTime)
		WHERE SuperId = @CustID AND FromDate >= @EffectiveDate
			AND ToDate >= @today

		UPDATE dbo.Acc_GroupExtraPT2Setting WITH(ROWLOCK, UPDLOCK)
		SET ToDate = DATEADD(DAY, -1, @EffectiveDate), RepUpdateTime = [dbo].[f_GetDateTime2]()
		WHERE SuperId = @CustID AND FromDate < @EffectiveDate
			AND ToDate >= @today

		IF @GroupName <> 'No Extra PT'
		BEGIN
			INSERT INTO dbo.Acc_GroupExtraPT2Setting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate, RepUpdateTime)
			SELECT @CustId, @GroupId, @GroupName, ProductID, Sporttype, SubProduct, ExtraPT,
				CASE WHEN @EffectiveDate < FromDate THEN FromDate ELSE @EffectiveDate END AS FromDate,
				CASE WHEN @EndDate < ToDate THEN @EndDate ELSE ToDate END AS ToDate
				, [dbo].[f_GetDateTime2]()
			FROM dbo.Acc_GroupExtraPT2_Product WITH(NOLOCK)
			WHERE GroupId = @GroupId
				AND @EffectiveDate <= ToDate
		END

	END
	ELSE -- remove @CustID from @GroupName
	BEGIN

		IF EXISTS (
			SELECT TOP 1 1 FROM dbo.Acc_GroupExtraPT2Setting WITH(NOLOCK)
			WHERE SuperId = @CustID AND GroupId = @GroupId AND FromDate > @today
		) -- To be Is Primary Extra PT Group
		BEGIN
			
			DELETE dbo.Acc_GroupExtraPT2Setting WITH(ROWLOCK, UPDLOCK)
				OUTPUT deleted.ID, [dbo].[f_GetDateTime2]()
				INTO Acc_GroupExtraPT2Setting_Del_InHouse (ID, RepUpdateTime)
			WHERE SuperId = @CustID AND GroupId = @GroupId AND FromDate > @today

			IF EXISTS (
				SELECT TOP 1 1 FROM dbo.Acc_GroupExtraPT2Setting WITH(NOLOCK)
				WHERE SuperId = @CustID AND @today BETWEEN FromDate AND ToDate
			)
			BEGIN
				DELETE dbo.Acc_GroupExtraPT2Setting WITH(ROWLOCK, UPDLOCK)
					OUTPUT deleted.ID, deleted.SuperId, deleted.GroupId, deleted.ProductId, deleted.Sporttype, deleted.SubProduct, deleted.FromDate, deleted.ToDate, [dbo].[f_GetDateTime2]()
					INTO @Setting (ID, SuperId, GroupId, ProductId, Sporttype, SubProduct, FromDate, ToDate, RepUpdateTime)
				WHERE SuperId = @CustID AND ToDate > @today

				INSERT INTO Acc_GroupExtraPT2Setting_Del_InHouse (ID, RepUpdateTime)
				SELECT ID, [dbo].[f_GetDateTime2]()
				FROM @Setting

				INSERT INTO dbo.Acc_GroupExtraPT2Setting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate, RepUpdateTime)
				SELECT @CustId, g.GroupId, g.GroupName, g.ProductID, g.Sporttype, g.SubProduct, g.ExtraPT,
					CASE WHEN s.FromDate < @today THEN s.FromDate ELSE g.FromDate END AS FromDate, g.ToDate
					, [dbo].[f_GetDateTime2]()
				FROM dbo.Acc_GroupExtraPT2_Product g WITH(NOLOCK)
					INNER JOIN @Setting s ON g.GroupId = s.GroupId
				WHERE @today >= g.ToDate
			END

		END

	END
END
GO