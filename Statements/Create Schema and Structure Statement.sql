USE [bodb_report]
GO
----------
--1
--Create file group 
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_14M01]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_14M02]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_14M03]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_14M04]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_14M05]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_14M06]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_14M07]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_14M08]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_14M09]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_14M10]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_14M11]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_14M12]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_15M01]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_15M02]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_15M03]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_15M04]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_15M05]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_15M06]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_15M07]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_15M08]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_15M09]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_15M10]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_15M11]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_15M12]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_16M01]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_16M02]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_16M03]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_16M04]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_16M05]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_16M06]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_16M07]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_16M08]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_16M09]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_16M10]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_16M11]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_16M12]
ALTER DATABASE bodb_report ADD filegroup [rptSTATEMENT_max]

--2014
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_14M01', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_14M01.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_14M01]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_14M02', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_14M02.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_14M02]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_14M03', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_14M03.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_14M03]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_14M04', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_14M04.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_14M04]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_14M05', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_14M05.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_14M05]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_14M06', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_14M06.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_14M06]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_14M07', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_14M07.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_14M07]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_14M08', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_14M08.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_14M08]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_14M09', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_14M09.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_14M09]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_14M10', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_14M10.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_14M10]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_14M11', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_14M11.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_14M11]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_14M12', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_14M12.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_14M12]
------------2015
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_15M01', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_15M01.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_15M01]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_15M02', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_15M02.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_15M02]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_15M03', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_15M03.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_15M03]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_15M04', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_15M04.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_15M04]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_15M05', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_15M05.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_15M05]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_15M06', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_15M06.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_15M06]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_15M07', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_15M07.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_15M07]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_15M08', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_15M08.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_15M08]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_15M09', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_15M09.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_15M09]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_15M10', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_15M10.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_15M10]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_15M11', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_15M11.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_15M11]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_15M12', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_15M12.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_15M12]
------------2016
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_16M01', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_16M01.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_16M01]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_16M02', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_16M02.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_16M02]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_16M03', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_16M03.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_16M03]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_16M04', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_16M04.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_16M04]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_16M05', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_16M05.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_16M05]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_16M06', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_16M06.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_16M06]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_16M07', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_16M07.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_16M07]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_16M08', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_16M08.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_16M08]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_16M09', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_16M09.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_16M09]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_16M10', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_16M10.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_16M10]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_16M11', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_16M11.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_16M11]
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_16M12', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_16M12.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_16M12]
----------
ALTER DATABASE bodb_report ADD FILE (name = 'rptSTATEMENT_max', filename ='D:\IBC_DB\bodb_Report\rptSTATEMENT_max.ndf', SIZE = 1 MB ,FILEGROWTH = 16 MB ) TO filegroup [rptSTATEMENT_max]

--2
--Create partition function
CREATE PARTITION FUNCTION pf_rptSTATEMENT_monthly (DATE) AS
RANGE LEFT FOR VALUES
(    
    '2014/01/31 00:00:00.000',--rptSTATEMENT_14M01
    '2014/02/28 00:00:00.000',--rptSTATEMENT_14M02
    '2014/03/31 00:00:00.000',--rptSTATEMENT_14M03
    '2014/04/30 00:00:00.000',--rptSTATEMENT_14M04
    '2014/05/31 00:00:00.000',--rptSTATEMENT_14M05
    '2014/06/30 00:00:00.000',--rptSTATEMENT_14M06
    '2014/07/31 00:00:00.000',--rptSTATEMENT_14M07
    '2014/08/31 00:00:00.000',--rptSTATEMENT_14M08
    '2014/09/30 00:00:00.000',--rptSTATEMENT_14M09
    '2014/10/31 00:00:00.000',--rptSTATEMENT_14M10
    '2014/11/30 00:00:00.000',--rptSTATEMENT_14M11
	'2014/12/31 00:00:00.000',--rptSTATEMENT_14M12
	'2015/01/31 00:00:00.000',--rptSTATEMENT_15M01
    '2015/02/28 00:00:00.000',--rptSTATEMENT_15M02
    '2015/03/31 00:00:00.000',--rptSTATEMENT_15M03
    '2015/04/30 00:00:00.000',--rptSTATEMENT_15M04
    '2015/05/31 00:00:00.000',--rptSTATEMENT_15M05
    '2015/06/30 00:00:00.000',--rptSTATEMENT_15M06
    '2015/07/31 00:00:00.000',--rptSTATEMENT_15M07
    '2015/08/31 00:00:00.000',--rptSTATEMENT_15M08
    '2015/09/30 00:00:00.000',--rptSTATEMENT_15M09
    '2015/10/31 00:00:00.000',--rptSTATEMENT_15M10
    '2015/11/30 00:00:00.000',--rptSTATEMENT_15M11
	'2015/12/31 00:00:00.000',--rptSTATEMENT_15M12
	'2016/01/31 00:00:00.000',--rptSTATEMENT_16M01
    '2016/02/29 00:00:00.000',--rptSTATEMENT_16M02
    '2016/03/31 00:00:00.000',--rptSTATEMENT_16M03
    '2016/04/30 00:00:00.000',--rptSTATEMENT_16M04
    '2016/05/31 00:00:00.000',--rptSTATEMENT_16M05
    '2016/06/30 00:00:00.000',--rptSTATEMENT_16M06
    '2016/07/31 00:00:00.000',--rptSTATEMENT_16M07
    '2016/08/31 00:00:00.000',--rptSTATEMENT_16M08
    '2016/09/30 00:00:00.000',--rptSTATEMENT_16M09
    '2016/10/31 00:00:00.000',--rptSTATEMENT_16M10
    '2016/11/30 00:00:00.000',--rptSTATEMENT_16M11
	'2016/12/31 00:00:00.000'--rptSTATEMENT_16M12
)
----------
--3
--Create partition schema
CREATE PARTITION SCHEME ps_rptSTATEMENT_monthly
AS PARTITION pf_rptSTATEMENT_monthly
TO
    (
	[rptSTATEMENT_14M01], 
	[rptSTATEMENT_14M02], 
	[rptSTATEMENT_14M03], 
	[rptSTATEMENT_14M04], 
	[rptSTATEMENT_14M05], 
	[rptSTATEMENT_14M06], 
	[rptSTATEMENT_14M07], 
	[rptSTATEMENT_14M08], 
	[rptSTATEMENT_14M09], 
	[rptSTATEMENT_14M10], 
	[rptSTATEMENT_14M11], 
	[rptSTATEMENT_14M12],
	[rptSTATEMENT_15M01], 
	[rptSTATEMENT_15M02], 
	[rptSTATEMENT_15M03], 
	[rptSTATEMENT_15M04], 
	[rptSTATEMENT_15M05], 
	[rptSTATEMENT_15M06], 
	[rptSTATEMENT_15M07], 
	[rptSTATEMENT_15M08], 
	[rptSTATEMENT_15M09], 
	[rptSTATEMENT_15M10], 
	[rptSTATEMENT_15M11], 
	[rptSTATEMENT_15M12],
	[rptSTATEMENT_16M01], 
	[rptSTATEMENT_16M02], 
	[rptSTATEMENT_16M03], 
	[rptSTATEMENT_16M04], 
	[rptSTATEMENT_16M05], 
	[rptSTATEMENT_16M06], 
	[rptSTATEMENT_16M07], 
	[rptSTATEMENT_16M08], 
	[rptSTATEMENT_16M09], 
	[rptSTATEMENT_16M10], 
	[rptSTATEMENT_16M11], 
	[rptSTATEMENT_16M12], 
	[rptSTATEMENT_Max]
 )                
GO
 
----------
--4
--Create rptStatementOld table


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT TOP 1 1 FROM sys.objects
	WHERE name = 'rptStatement_Old' AND type='U'
	)
BEGIN
	DROP TABLE [dbo].[rptStatement_Old]
END

CREATE TABLE [dbo].[rptStatement_Old](
	[WinlostDate] [DATE] NOT NULL,
	[Custid] [int] NOT NULL,
	[OpeningBalance] [money] NULL,
	[VoidAmt] [money] NULL,
	[Turnover] [money] NULL,
	[NetTurnover] [money] NULL,
	[TransferAmt] [money] NULL,
	[Winlost] [money] NULL,	
	[Comm] [money] NULL,
	[ClosingBalance] [money] NULL,
 CONSTRAINT [CIX_rptStatement_Old_winlostdate_custid] PRIMARY KEY CLUSTERED 
(
	[WinlostDate] ASC,
	[Custid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON ps_rptSTATEMENT_monthly ([WinlostDate])
) ON ps_rptSTATEMENT_monthly ([WinlostDate])

GO