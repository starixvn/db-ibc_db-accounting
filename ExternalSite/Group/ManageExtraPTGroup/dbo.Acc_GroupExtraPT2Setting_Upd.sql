/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Acc_GroupExtraPT2Setting_Upd]
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
		
	Param's Explanation:
		- @EffectiveDate
			+ IS NULL: remove @CustID from @GroupName
			+ NOT NULL: change @GroupName is Primary Extra PT Group of @CustID
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Setting TABLE (GroupId INT, FromDate DATETIME)

	IF @EffectiveDate IS NOT NULL -- change @GroupName is Primary Extra PT Group of @CustID
	BEGIN
		
		DELETE dbo.Acc_GroupExtraPT2Setting WITH(ROWLOCK, UPDLOCK)
		WHERE SuperId = @CustID AND FromDate >= @EffectiveDate
			AND ToDate >= @today

		UPDATE dbo.Acc_GroupExtraPT2Setting WITH(ROWLOCK, UPDLOCK)
		SET ToDate = DATEADD(DAY, -1, @EffectiveDate)
		WHERE SuperId = @CustID AND FromDate < @EffectiveDate
			AND ToDate >= @today

		IF @GroupName = 'No Extra PT'
		BEGIN
			INSERT INTO dbo.Acc_GroupExtraPT2Setting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
			VALUES (@CustId, 0, '', 0, 0, '', 0, @EffectiveDate, '9999-12-31')
		END
		ELSE
		BEGIN
			INSERT INTO dbo.Acc_GroupExtraPT2Setting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
			SELECT @CustId, @GroupId, @GroupName, ProductID, Sporttype, SubProduct, ExtraPT,
				CASE WHEN @EffectiveDate < FromDate THEN FromDate ELSE @EffectiveDate END AS FromDate,
				CASE WHEN @EndDate < ToDate THEN @EndDate ELSE ToDate END AS ToDate
			FROM dbo.Acc_GroupExtraPT2_Product WITH(NOLOCK)
			WHERE GroupId = @GroupId
				AND @EffectiveDate <= ToDate

			IF @GroupName IN ('ACCTHAI2','ACCTHAI56','ACCTHAI99')
			BEGIN
				INSERT INTO dbo.Acc_GroupExtraPT2Setting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
				SELECT @CustId, GroupId, GroupName, ProductID, Sporttype, SubProduct, ExtraPT,
					CASE WHEN @EffectiveDate < FromDate THEN FromDate ELSE @EffectiveDate END AS FromDate,
					CASE WHEN @EndDate < ToDate THEN @EndDate ELSE ToDate END AS ToDate
				FROM dbo.Acc_GroupExtraPT2_Product WITH(NOLOCK)
				WHERE GroupName = 'BC'
					AND @EffectiveDate <= ToDate
			END
			
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
			WHERE SuperId = @CustID AND GroupId = @GroupId AND FromDate > @today

			IF @GroupName IN ('ACCTHAI2','ACCTHAI56','ACCTHAI99')
			BEGIN
				DELETE dbo.Acc_GroupExtraPT2Setting WITH(ROWLOCK, UPDLOCK)
				WHERE SuperId = @CustID AND GroupName = 'BC' AND FromDate > @today
			END

			IF EXISTS (
				SELECT TOP 1 1 FROM dbo.Acc_GroupExtraPT2Setting WITH(NOLOCK)
				WHERE SuperId = @CustID AND @today BETWEEN FromDate AND ToDate
			)
			BEGIN
				DELETE dbo.Acc_GroupExtraPT2Setting WITH(ROWLOCK, UPDLOCK)
				OUTPUT DELETED.GroupId, DELETED.FromDate
					INTO @Setting (GroupId, FromDate)
				WHERE SuperId = @CustID AND ToDate > @today

				INSERT INTO dbo.Acc_GroupExtraPT2Setting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
				SELECT @CustId, g.GroupId, g.GroupName, g.ProductID, g.Sporttype, g.SubProduct, g.ExtraPT,
					CASE WHEN s.FromDate < @today THEN s.FromDate ELSE g.FromDate END AS FromDate, g.ToDate
				FROM dbo.Acc_GroupExtraPT2_Product g WITH(NOLOCK)
					INNER JOIN @Setting s ON g.GroupId = s.GroupId
				WHERE @today >= g.ToDate
			END

		END

	END
END
GO