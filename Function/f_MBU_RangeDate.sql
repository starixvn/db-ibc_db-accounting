/*<info serverAlias="DBAGE-bodb02,DBACC-bodb02" selecters="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap" isFunction="1" isNested="0"></info>*/
CREATE FUNCTION [dbo].[f_MBU_RangeDate]
(
    @FromDate SMALLDATETIME,
    @ToDate SMALLDATETIME,
    @BalanceUpDay SMALLDATETIME,
    @MoveBetsDay SMALLDATETIME
)
/*  
	Created: 20241213@Lewis
	Task : Get DateRange for report MBU
	DB: DBAGE/bodb02, DBACC/bodb02  
  
	Revisions:
		- 20241213@Lewis: Initialize [Redmine: #213821]

*/
RETURNS TABLE
AS
RETURN
(
    SELECT rd.FromDate,
           rd.ToDate,
           rd.RangeType
    FROM
		(
		    VALUES
		        (@FromDate, @ToDate, @BalanceUpDay, @MoveBetsDay)
		) AS t (FromDate, ToDate, BU, MB)
    OUTER APPLY
		(
		    VALUES
		        (IIF(ToDate > MB, IIF(FromDate <= MB, DATEADD(DAY, 1, MB), FromDate), NULL), ToDate, 1),
		        (IIF(FromDate <= MB AND ToDate >= BU, IIF(FromDate <= BU, BU, FromDate), NULL), IIF(ToDate >= MB, MB, ToDate), 2),
		        (IIF(FromDate < BU, FromDate, NULL), IIF(ToDate >= BU, DATEADD(DAY, -1, BU), ToDate), 3)
		) AS rd (FromDate, ToDate, RangeType)
    WHERE t.FromDate <= t.ToDate
          AND rd.FromDate IS NOT NULL
)