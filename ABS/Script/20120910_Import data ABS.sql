 SET IDENTITY_INSERT [bodb_ABS].[dbo].[ABPunterCode] ON
GO
INSERT INTO [bodb_ABS].[dbo].[ABPunterCode]
           ([punterid]
			,[code]
           ,[currency]
           ,[color]
           ,[fb_1]
           ,[fb_3]
           ,[enabled]
           ,[fb_5])
SELECT [punterid],[code],[currency],[color],[fb_1],[fb_3],[enabled],[fb_5]
FROM bodb02.dbo.ABPunterCode WITH(NOLOCK)
GO
SET IDENTITY_INSERT  [bodb_ABS].[dbo].[ABPunterCode] OFF
GO

INSERT INTO [bodb_ABS].[dbo].[ABCustomer]
           ([PunterID]
           ,[CustID]
           ,[updatedtime])
SELECT [PunterID],[CustID],[updatedtime]
FROM bodb02.dbo.ABCustomer WITH(NOLOCK)

GO

INSERT INTO [bodb_ABS].[dbo].[ABPunterGroup]
           ([adminid]
           ,[punterid])
SELECT [adminid],[punterid]   
FROM bodb02.dbo.ABPunterGroup WITH(NOLOCK)
GO

DECLARE @min_transid14 BIGINT

SELECT @min_transid14 = min(transid)
FROM bodb02.dbo.bettrans14 WITH(NOLOCK)

INSERT INTO [bodb_ABS].[dbo].[ABTransaction_BK]
           ([transid]
           ,[punterid]
           ,[custid]
           ,[remark])
SELECT [transid],[punterid],[custid],[remark]
FROM bodb02.dbo.ABTransaction WITH(NOLOCK)
WHERE transid < @min_transid14

PRINT '[ABTransaction_BK]'

WAITFOR DELAY '0:00:05'

INSERT INTO [bodb_ABS].[dbo].[ABTransaction]
           ([transid]
           ,[punterid]
           ,[custid]
           ,[remark])
SELECT [transid],[punterid],[custid],[remark]
FROM bodb02.dbo.ABTransaction WITH(NOLOCK)
WHERE transid >= @min_transid14

PRINT '[ABTransaction]'
WAITFOR DELAY '0:00:03'

INSERT INTO [bodb_ABS].[dbo].[ABMatch_Remark_BK]
           ([matchid]
           ,[bettype]
           ,[hdp]
           ,[odds]
           ,[transid])
SELECT [matchid],[bettype],[hdp],[odds],[transid]
FROM bodb02.[dbo].[ABMatch_Remark] WITH(NOLOCK)
WHERE transid < @min_transid14

PRINT '[ABMatch_Remark_BK]'
WAITFOR DELAY '0:00:05'

INSERT INTO [bodb_ABS].[dbo].[ABMatch_Remark]
           ([matchid]
           ,[bettype]
           ,[hdp]
           ,[odds]
           ,[transid])
SELECT [matchid],[bettype],[hdp],[odds],[transid]
FROM bodb02.[dbo].[ABMatch_Remark] WITH(NOLOCK)
WHERE transid >= @min_transid14

GO

DECLARE @min_sumdate DATETIME

SELECT @min_sumdate = min(winlostdate)
FROM bodb02.dbo.sum_winloss WITH(NOLOCK)

INSERT INTO [bodb_ABS].[dbo].[ABSum_winloss]
           ([winlostdate]
           ,[punterid]
           ,[leagueid]
           ,[matchid]
           ,[bettype]
           ,[currency]
           ,[statusid]
           ,[turnover]
           ,[comm]
           ,[winlost]
           ,[betcount])
SELECT [winlostdate],[punterid],[leagueid],[matchid],[bettype],[currency],[statusid],[turnover],[comm],[winlost],[betcount]    
FROM bodb02.dbo.ABSum_winloss2 WITH(NOLOCK)
WHERE winlostdate >= @min_sumdate

WAITFOR delay '0:00:03'

INSERT INTO [bodb_ABS].[dbo].[ABSum_winloss_Old]
           ([winlostdate]
           ,[punterid]
           ,[leagueid]
           ,[matchid]
           ,[bettype]
           ,[currency]
           ,[statusid]
           ,[turnover]
           ,[comm]
           ,[winlost]
           ,[betcount])
SELECT [winlostdate],[punterid],[leagueid],[matchid],[bettype],[currency],[statusid],[turnover],[comm],[winlost],[betcount]    
FROM bodb02.dbo.ABSum_winloss2 WITH(NOLOCK)
WHERE winlostdate < @min_sumdate     

GO
          