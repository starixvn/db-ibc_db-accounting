ALTER PROCEDURE [dbo].[DBA_UpdateTransferNewBettype]
    @winlostdate SMALLDATETIME
AS
/*
Created: 20110302@Thien
Task : update new bettype values for transfer_bk
DB: DB06.bodb_archive
Original:

Revisions:
    - 

Param's Explanation:
    - 

*/
DECLARE @StartTime DATETIME
SET @StartTime = CURRENT_TIMESTAMP

UPDATE transfer_bk WITH (ROWLOCK, UPDLOCK)
    SET bettype = case bettype
						when 99 then 19999
						when 100 then 20000
						when 101 then 21001
						when 102 then 21002
						when 103 then 21003
						when 104 then 21004
						when 105 then 21005
						when 106 then 21006
						when 107 then 22001
						when 108 then 22002
						when 109 then 22003
						when 110 then 22004
						when 111 then 22005
						when 115 then 22006
						when 116 then 22007
						when 112 then 23001
						when 113 then 23002
						when 114 then 23101
						when 117 then 23201
						when 118 then 23202
						else 0
					END
WHERE winlostdate between @winlostdate and DATEADD(mi, 1439, @winlostdate) -- plus '23:59:00'
    and bettype between 98 and 120

PRINT 'DONE: ' + CAST(@winlostdate AS VARCHAR(11)) + + N' (' + CAST(DATEDIFF(SECOND, @StartTime, CURRENT_TIMESTAMP) AS VARCHAR(50)) + ' sec) '
