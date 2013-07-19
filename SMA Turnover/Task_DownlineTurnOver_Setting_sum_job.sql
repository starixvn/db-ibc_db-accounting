

ALTER PROCEDURE [dbo].[Task_DownlineTurnOver_Setting_sum_job]
AS
/*
	Created: Joe
	Task: 
	DB: DBAGE/BODB02
	
	Revision
*/
BEGIN
	TRUNCATE TABLE dbo.DownlineTurnOver_Trigger_tmp
	
	Declare @rc1 int, @rc2 int
	
	DELETE D
	OUTPUT deleted.srecommend, deleted.matchid, deleted.sumstake
	INTO DownlineTurnOver_Trigger_tmp (srecommend, matchid, sumstake)
	FROM dbo.DownlineTurnOver_Trigger D
	
	SET @rc1 = @@ROWCOUNT
	
	;WITH src AS (SELECT srecommend, matchid, SUM(sumstake) sumstake FROM dbo.DownlineTurnOver_Trigger_tmp GROUP BY srecommend, matchid)
	UPDATE T
	SET totalturnOver = totalturnover + src.sumstake
	FROM dbo.DownlineTurnOver_Setting T
		INNER JOIN src ON T.custid = src.srecommend AND T.matchid = src.matchid

	SET @rc2 = @@ROWCOUNT
	
	PRINT '=== Delete ' + CAST(@rc1 as varchar(20)) + ' row(s), Update ' + CAST(@rc2 as varchar(20)) + ' row(s) ==='
END
	