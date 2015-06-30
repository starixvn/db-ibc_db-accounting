 --Step 1 - create dummy/standby table. Same table structure and permission.  just it empty table.
 
 CREATE TABLE [dbo].[bettransm_temp](
	[transid] [int] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[oddsid] [int] NOT NULL,
	[hdp1] [float] NULL,
	[hdp2] [float] NULL,
	[odds] [float] NULL,
	[stake] [float] NOT NULL,
	[status] [nvarchar](50) NULL,
	[winlost] [float] NULL,
	[livehomescore] [int] NULL,
	[liveawayscore] [int] NULL,
	[liveindicator] [bit] NULL,
	[betteam] [nvarchar](50) NULL,
	[creator] [nvarchar](50) NOT NULL,
	[refno] [bigint] NOT NULL,
	[comstatus] [nvarchar](50) NULL,
	[winlostdate] [datetime] NULL,
	[betfrom] [nvarchar](50) NULL,
	[betcheck] [nvarchar](50) NULL,
	[checktime] [datetime] NULL,
	[oddsspread] [float] NULL,
	[apositiontaking] [float] NULL,
	[mpositiontaking] [float] NULL,
	[tpositiontaking] [float] NULL,
	[awinlost] [float] NULL,
	[mwinlost] [float] NULL,
	[playerdiscount] [float] NULL,
	[discount] [float] NULL,
	[adiscount] [float] NULL,
	[playercomm] [float] NULL,
	[comm] [float] NULL,
	[acomm] [float] NULL,
	[actualrate] [float] NULL,
	[matchid] [int] NULL,
	[matchdate] [datetime] NULL,
	[finalodds] [float] NULL,
	[isfinish] [char](1) NULL,
	[statuswinlost] [tinyint] NULL,
	[ruben] [tinyint] NULL,
	[bettype] [int] NULL,
 CONSTRAINT [PK_bettransm_temp] PRIMARY KEY NONCLUSTERED 
(
	[transid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
GRANT SELECT ON [dbo].[bettransm_temp] TO [bodbDownlineNet]
GO
GRANT SELECT ON [dbo].[bettransm_temp] TO [bodbDownlineNetView]
GO
GRANT SELECT ON [dbo].[bettransm_temp] TO [bodbSuperNet]
GO

--Step 2 -- rename
Exec sp_rename 'bettransm', 'bettransm_origin'
Exec sp_rename 'bettransm_temp', 'bettransm'

--Step 3 -- add fields to original table
Use bodb_Archive
 
ALTER TABLE dbo.bettransm_origin ADD
 spositiontaking float(53) NULL,
 swinlost float(53) NULL,
 sdiscount float(53) NULL,
 scomm float(53) NULL
GO

--Step 4 -- rename back
Exec sp_rename 'bettransm', 'bettransm_temp'
Exec sp_rename 'bettransm_origin', 'bettransm'

--Step -- Double check and then drop bettransm_temp

