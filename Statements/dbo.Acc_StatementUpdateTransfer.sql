/*<info serverAlias="DBRPT-bodb_report" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
USE [bodb_report]
GO

ALTER PROCEDURE [dbo].[Acc_StatementUpdateTransfer]
	@custid			INT
	,@Amount		MONEY
	,@winlostdate	SMALLDATETIME
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20141226@Tom
	Task : Update Transfer Amount in rptStatement table before move bet day
	DB: DBRPT.bodb_report
	
	Revisions:
		- 20190718@Percy: Update total opening/closing balance [RedmineID: #109293]
    
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	SELECT  @ErrCode = 0, @ErrMsg = ''

	/* ===== Customer Info ===== */
	BEGIN
		DECLARE @roleId TINYINT, @recommend INT, @mrecommend INT, @srecommend INT
		SELECT  @roleId = roleid, @recommend = recommend, @mrecommend = mrecommend, @srecommend = srecommend
		FROM bodb02.dbo.Customer WITH (NOLOCK)
		WHERE custid = @custid

		IF @recommend IS NULL
			RETURN
	END
	/* ===== End Customer Info ===== */
	
	/* ===== Initialize data in rptStatement ===== */
	BEGIN
		CREATE TABLE #rptStatement
		(
			custid					INT
			,roleid					TINYINT
			,recommend				INT
			,mrecommend				INT
			,srecommend				INT
			,winlostdate			SMALLDATETIME
			,ClosingBalance			MONEY
			,ClosingTotalBalance	MONEY
		)

		IF EXISTS (
			SELECT 1
			FROM (VALUES (@custid, @roleId),(@recommend, 2),(@mrecommend, 3),(@srecommend, 4)) AS c(custid, roleid)
				OUTER APPLY (
					SELECT r.custid
					FROM dbo.rptStatement r WITH (NOLOCK)
					WHERE r.winlostdate = @winlostdate
						AND r.custid = c.custid
				) AS r
			WHERE c.custid <> 0 AND r.custid IS NULL
		)
		BEGIN
			INSERT INTO #rptStatement (custid, roleid, recommend, mrecommend, srecommend)
			SELECT custid, roleid, recommend, mrecommend, srecommend
			FROM bodb02.dbo.Customer c WITH (NOLOCK)
			WHERE srecommend = @srecommend

			UPDATE tmp
			SET tmp.winlostdate = r.winlostdate
			FROM #rptStatement tmp
				CROSS APPLY (
					SELECT TOP 1 r.winlostdate
					FROM dbo.rptStatement r WITH (NOLOCK)
					WHERE r.winlostdate < @winlostdate
						AND r.custid = tmp.custid
					ORDER BY r.winlostdate DESC
				) AS r

			IF EXISTS (SELECT 1 FROM #rptStatement WHERE winlostdate IS NULL)
			BEGIN
				UPDATE tmp
				SET tmp.winlostdate = r.winlostdate
				FROM #rptStatement tmp
					CROSS APPLY (
						SELECT TOP 1 r.winlostdate
						FROM dbo.rptStatement_Old r WITH (NOLOCK)
						WHERE r.winlostdate < @winlostdate
							AND r.custid = tmp.custid
						ORDER BY r.winlostdate DESC
					) AS r
				WHERE tmp.winlostdate IS NULL
			END
		END

		UPDATE tmp
		SET tmp.ClosingBalance = r.ClosingBalance
		FROM #rptStatement tmp
			CROSS APPLY (
				SELECT r.ClosingBalance
				FROM dbo.rptStatement r WITH (NOLOCK) 
				WHERE tmp.winlostdate = r.winlostdate
					AND tmp.custid = r.custid

				UNION ALL
				SELECT r.ClosingBalance
				FROM dbo.rptStatement_Old r WITH (NOLOCK) 
				WHERE tmp.winlostdate = r.winlostdate
					AND tmp.custid = r.custid

				UNION ALL
				SELECT 0 AS ClosingBalance
				WHERE tmp.winlostdate IS NULL
			) AS r

		INSERT INTO dbo.rptStatement
		(
			winlostdate
			,custid
			,openingbalance
			,voidamt
			,turnover
			,netturnover
			,transferamt
			,winlost
			,comm
			,closingbalance
			,OpeningTotalBalance
		)
		SELECT
			@winlostdate
			,custid
			,ClosingBalance AS OpeningBalance
			,NULL AS VoidAmt
			,NULL AS Turnover
			,NULL AS NetTurnover
			,0	  AS TransferAmt
			,NULL AS Winlost
			,NULL AS Comm
			,ClosingBalance AS ClosingBalance
			,ClosingTotalBalance AS OpeningTotalBalance
		FROM
			(
				-- Super
				SELECT
					@srecommend AS custid
					,SUM(CASE WHEN custid = srecommend THEN ClosingBalance ELSE 0 END) AS ClosingBalance
					,SUM(ClosingBalance) AS ClosingTotalBalance
				FROM #rptStatement
				WHERE srecommend = @srecommend
			
				-- Master
				UNION ALL
				SELECT
					@mrecommend AS custid
					,SUM(CASE WHEN custid = mrecommend THEN ClosingBalance ELSE 0 END) AS ClosingBalance
					,SUM(ClosingBalance) AS ClosingTotalBalance
				FROM #rptStatement
				WHERE mrecommend = @mrecommend

				-- Agent
				UNION ALL
				SELECT
					@recommend AS custid
					,SUM(CASE WHEN custid = recommend THEN ClosingBalance ELSE 0 END) AS ClosingBalance
					,SUM(ClosingBalance) AS ClosingTotalBalance
				FROM #rptStatement
				WHERE recommend = @recommend

				-- Member
				UNION ALL
				SELECT
					@custid AS custid
					,SUM(ClosingBalance) AS ClosingBalance
					,SUM(ClosingBalance) AS ClosingTotalBalance
				FROM #rptStatement
				WHERE custid = @custid AND @roleid = 1
			) AS tmp
		WHERE NOT EXISTS (SELECT 1 FROM dbo.rptStatement r WITH (NOLOCK) WHERE tmp.custid = r.custid AND r.winlostdate = @winlostdate)
	END
	/* ===== End Initialize data in rptStatement ===== */

	DROP TABLE #rptStatement

	/* ===== Update Transfer Amount ===== */
	BEGIN
		DECLARE @tblCustId TABLE (custid INT, roleid TINYINT, winlostdate SMALLDATETIME)

		;WITH CTE_winlostdate AS
		(
			SELECT @winlostdate AS winlostdate
			UNION ALL
			SELECT DATEADD(DAY, 1, winlostdate)
			FROM CTE_winlostdate
			WHERE winlostdate < CONVERT(DATE, GETDATE())
		)
		INSERT INTO @tblCustId (custid, winlostdate)
		SELECT DISTINCT c.custid, wld.winlostdate
		FROM (VALUES (@custid),(@recommend),(@mrecommend),(@srecommend)) AS c(custid)
			CROSS APPLY CTE_winlostdate wld
		WHERE c.custid <> 0

		BEGIN TRY
			UPDATE r WITH (ROWLOCK)
			SET	r.openingbalance = r.openingbalance + CASE WHEN r.custid = @custid AND r.winlostdate > @winlostdate THEN @Amount ELSE 0 END
				,r.transferamt = r.transferamt + CASE WHEN r.custid = @custid AND r.winlostdate = @winlostdate THEN @Amount ELSE 0 END
				,r.closingbalance = r.closingbalance + CASE WHEN r.custid = @custid THEN @Amount ELSE 0 END
				,r.OpeningTotalBalance = r.OpeningTotalBalance + CASE WHEN r.winlostdate > @winlostdate THEN @Amount ELSE 0 END
			FROM @tblCustId c
				CROSS APPLY (
					SELECT r.custid, r.winlostdate, r.openingbalance, r.transferamt, r.closingbalance, r.OpeningTotalBalance
					FROM dbo.rptStatement r
					WHERE r.winlostdate = c.winlostdate AND r.custid = c.custid
				) AS r

			UPDATE r WITH (ROWLOCK)
			SET r.openingbalance = r.openingbalance + CASE WHEN r.custid = @custid AND r.winlostdate > @winlostdate THEN @Amount ELSE 0 END
				,r.OpeningTotalBalance = r.OpeningTotalBalance + CASE WHEN r.winlostdate > @winlostdate THEN @Amount ELSE 0 END
			FROM @tblCustId c
				CROSS APPLY (
					SELECT r.custid, r.winlostdate, r.openingbalance, r.OpeningTotalBalance
					FROM dbo.RptTotalBalance_Active r
					WHERE r.winlostdate = c.winlostdate AND r.custid = c.custid
				) AS r
		END TRY
		BEGIN CATCH
			SELECT @ErrCode = 100, @ErrMsg = 'Update process unsucessful'
			RETURN
		END CATCH
	END
END
GO