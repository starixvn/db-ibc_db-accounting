/*
NOTEs:
	+ Sporttype: NumberGame, Virtual, LiveCasino, 
*/
CREATE TABLE dbo.Exchange
	(
	Currency varchar(3) NOT NULL,
	Year smallint NOT NULL,
	Month tinyint NOT NULL,
	Rate float(53) NULL
	)  ON DATA
GO

CREATE TABLE [dbo].[ProductSettings](
	[LCSid] [int] NOT NULL,
	[Sporttype] [varchar](20) NULL,
	[DistributorCharge] [smallmoney] NULL,
	[PartnerCharge] [smallmoney] NULL,
	[OneworksCharge] [smallmoney] NULL,
	[ChargeType] [tinyint] NOT NULL
) ON [DATA]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[ProductSettings] ADD  CONSTRAINT [DF_ProductSettings_ChargeType]  DEFAULT ((1)) FOR [ChargeType]
GO

GO

INSERT INTO exchange (currency, year, month, rate)
SELECT distinct code, year(lastdate) yy, mm, EUR eur
FROM (
		SELECT mm, DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,DATEADD(M, mm-1, '1 Jan 2012'))+1,0)) as lastdate
		FROM (
				select 1 as mm
				UNION SELECT 2
				UNION SELECT 3
				UNION SELECT 4
				UNION SELECT 5
				UNION SELECT 6
				UNION SELECT 7
				UNION SELECT 8
				UNION SELECT 9
				UNION SELECT 10
				UNION SELECT 11
				UNION SELECT 12
			) a
	) b	
	INNER JOIN dwdb.dbo.exchangedailyoanda e with(nolock) on b.lastdate = e.exchangedate
WHERE e.exchangeid in (1,2,3,4,5,6,9,12,13,15,30,32,34,35,41,45,46,49,51,52,53,54,55,56,57,58,61,63)

-- BCH (numbergame)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4200100, 'NumberGame',0.15, 0.8, 0.1, 2) --12bet
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4201400, 'NumberGame',0.15, 0.8, 0.1, 2) --bodog
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4200200, 'NumberGame',0.15, 0.8, 0.1, 2) --alog

--boping (numbergame)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4201800, 'NumberGame',0, 0.15, 0.1, 1) --macaubet
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4202500, 'NumberGame',0, 0.15, 0.1, 1) --Livebet365

-- PIH (numbergame)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100300, 'NumberGame',0, 0.05, 0.1, 1) --789y
--VCasia (numbergame)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4202000, 'NumberGame',0, 0.15, 0.1, 1) --VCasia
-- FDL (numbergame)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100200, 'NumberGame', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100800, 'NumberGame', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100900, 'NumberGame', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100600, 'NumberGame', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100400, 'NumberGame', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100700, 'NumberGame', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101500, 'NumberGame', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101300, 'NumberGame', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101100, 'NumberGame', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101400, 'NumberGame', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101000, 'NumberGame', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101200, 'NumberGame', 0, 0.05, 0.1, 1)

-- FDL (LiveCasino)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100200, 'LiveCasino', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100800, 'LiveCasino', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100900, 'LiveCasino', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100600, 'LiveCasino', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100400, 'LiveCasino', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100700, 'LiveCasino', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101500, 'LiveCasino', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101300, 'LiveCasino', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101100, 'LiveCasino', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101400, 'LiveCasino', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101000, 'LiveCasino', 0, 0.05, 0.1, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101200, 'LiveCasino', 0, 0.05, 0.1, 1)

-- FDL (VirtualSports)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100200, 'Virtual', 0, 0.03, 0.01, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100800, 'Virtual', 0, 0.03, 0.01, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100900, 'Virtual', 0, 0.03, 0.01, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100600, 'Virtual', 0, 0.03, 0.01, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100400, 'Virtual', 0, 0.03, 0.01, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4100700, 'Virtual', 0, 0.03, 0.01, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101500, 'Virtual', 0, 0.03, 0.01, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101300, 'Virtual', 0, 0.03, 0.01, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101100, 'Virtual', 0, 0.03, 0.01, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101400, 'Virtual', 0, 0.03, 0.01, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101000, 'Virtual', 0, 0.03, 0.01, 1)
INSERT INTO ProductSettings (LCSid, sporttype, DistributorCharge, PartnerCharge, OneworksCharge, ChargeType)
values (4101200, 'Virtual', 0, 0.03, 0.01, 1)


