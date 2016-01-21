USE [bodb02]
GO

ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_RefundAll] 
     @matchid                        INT
    ,@IsExcludeBetdaq                BIT = 0
    ,@IsExcludeBetfair                BIT = 0
    ,@IsSettleAbandonedMatchIBC        BIT = 0
    ,@SelectedSet                    VARCHAR(50)     = NULL 
    ,@SelectedSettleFinishedGame    VARCHAR(50)     = NULL 
    ,@SetxGameyFinishedGame            VARCHAR(MAX) = NULL 
    ,@ResourceIDs                    VARCHAR(MAX) = NULL 
AS
/*    Created by: Kathy
    Date: 20140213
    Task: Refund All
    DB: DBTXN/BODB02    
    Revisions:
        - 20140304@Kathy: Execute settlement for abandoned/postponed matches- Clean Sheet, Both/One/Neither team to score, To Win To Nil 
        - 20140411@Kathy: Add more param for LAS command
        - 20140426@Kathy: Add 1H FGLG (127) [Redmine:#14449]
        - 20140729@Kathy: Add one more account(BF3) into BetFair's group [Redmine:#19665]
        - 20140711@Kathy: Apply BetRadar [Redmine:#17142]
        - 20140728@Kathy: Settle determined tickets for Correct Score(4,30), Total Goal (6,126) [Redmine:#19310]
        - 20140812@Kathy: Support new 11 bettypes [Redmine:#19667]
        - 20140905@Lukas: exclude virtual racing bettype 1231,1232,1233
        - 20140909@Kathy: Exclude virtual racing (bettype 1237, 1238), outright (bettype 10, 31, 32, 33), keno (1501 -> 1599)
        - 20141027@Jamie: Sportting Solution Tennis Settlement [Redmine:#23034]
        - 20150206@Jamie: Auto Settlement Betradar phase 2 [Redmine: #27212]
        - 20150605@Johnson: Exclude SOLD/BOUGHT/COM tickets from bettrade [Redmine:#35921] 
		- 20150716@Johnson: Exclude range bettypes of Metric Gaming from settlement of SB [Redmine: #37688]
		- 20150919@Kathy: Intergrate Myanmar Odds ( 4 new bettypes: 301->304)
		- 20151126@Patrick: Apply 28 Live Bettypes for Settlement [Redmine:#47843]
		- 20151210@Patrick: Database - Change datatype [Redmine: #48660]
		- 20160120@Patrick: PH-AiO - Change request [Redmine: #51116]
        
    Note: For settlement SPs should hardcode the custid of betdaq customer to avoid replication problem
*/
BEGIN
    SET NOCOUNT ON

    ----- LAS settlement 
    --IF @@SERVERNAME IN ('DB052', 'DB054', 'DB231', 'DB232','DB215') AND EXISTS (
    --        SELECT *
    --        FROM sys.databases
    --        WHERE NAME = 'LASDB'
    --        )
    --BEGIN
    --    DECLARE @LASCommand NVARCHAR(1000)
    --        ,@createdDate DATETIME

    --    SELECT @LASCommand = 'EXEC [dbo].[Admin_Calculate_RefundAll] @matchid = ' + CONVERT(NVARCHAR(10), @matchid)
    --                        + ', @IsSettleAbandonedMatchIBC = ' + CONVERT(NVARCHAR(10), ISNULL(@IsSettleAbandonedMatchIBC, 0))                                                     
    --        ,@createdDate = GETDATE()

    --    EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand] @SPName = 'Admin_Calculate_RefundAll'
    --        ,@SQLCommand = @LASCommand
    --        ,@CreatedDate = @createdDate
    --        ,@StatusID = 0 -- waiting
    --        ,@MatchID = @matchid
    --        ,@Bettype = 0 -- hardcode
    --        ,@Status = 'waiting'
    --        ,@BetCount = 0
    --END

    WHILE 1 = 1
    BEGIN
        UPDATE TOP (10000) dbo.bettrans WITH (ROWLOCK, UPDLOCK)
        SET [status] = N'Refund'
            ,statusID = 103
            ,winlost = actual_stake
            ,awinlost = 0
            ,mwinlost = 0
            ,swinlost = 0
            ,playercomm = 0
            ,comm = 0
            ,acomm = 0
            ,scomm = 0
            ,ruben = 1
            ,statuswinlost = 0
        WHERE matchid = @matchid AND statusID NOT IN (103, 101, 102) 
            AND bettype NOT IN (14, 127) 
            AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
            AND bettype NOT BETWEEN 1501 and 1599 -- Keno
			AND bettype NOT IN (901,902,903)
			AND bettype NOT BETWEEN 801 AND 899--Metric Gaming
            AND 1 = CASE WHEN @SelectedSet IS NULL THEN 1 
                         WHEN @SelectedSet LIKE '%1%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND (BetID = 801 OR BetID BETWEEN 80101 AND 80199) THEN 1 
                         WHEN @SelectedSet LIKE '%2%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND (BetID = 802 OR BetID BETWEEN 80201 AND 80299) THEN 1
                         WHEN @SelectedSet LIKE '%3%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND (BetID = 803 OR BetID BETWEEN 80301 AND 80399) THEN 1
                         WHEN @SelectedSet LIKE '%4%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND (BetID = 804 OR BetID BETWEEN 80401 AND 80499) THEN 1
                         WHEN @SelectedSet LIKE '%5%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND (BetID = 805 OR BetID BETWEEN 80501 AND 80599) THEN 1
                         WHEN @SelectedSet LIKE '%6%' AND Bettype IN (1,2,3,20,153,1301,1302,1303,1305,1306,1308) THEN 1 
                         ELSE 0 END 
            AND 1 = CASE WHEN @SelectedSettleFinishedGame LIKE '%1%' AND betID BETWEEN 80101 AND 80199 AND CHARINDEX(SUBSTRING(CAST(BetID AS VARCHAR(10)),2,4),@SetxGameyFinishedGame)>0 THEN 0 
                         WHEN @SelectedSettleFinishedGame LIKE '%2%' AND BetID BETWEEN 80201 AND 80299 AND CHARINDEX(SUBSTRING(CAST(BetID AS VARCHAR(10)),2,4),@SetxGameyFinishedGame)>0 THEN 0  
                         WHEN @SelectedSettleFinishedGame LIKE '%3%' AND BetID BETWEEN 80301 AND 80399 AND CHARINDEX(SUBSTRING(CAST(BetID AS VARCHAR(10)),2,4),@SetxGameyFinishedGame)>0 THEN 0  
                         WHEN @SelectedSettleFinishedGame LIKE '%4%' AND BetID BETWEEN 80401 AND 80499 AND CHARINDEX(SUBSTRING(CAST(BetID AS VARCHAR(10)),2,4),@SetxGameyFinishedGame)>0 THEN 0   
                         WHEN @SelectedSettleFinishedGame LIKE '%5%' AND BetID BETWEEN 80501 AND 80599 AND CHARINDEX(SUBSTRING(CAST(BetID AS VARCHAR(10)),2,4),@SetxGameyFinishedGame)>0 THEN 0 
                         ELSE 1 END 
            AND 1 = CASE WHEN @ResourceIDs IS NULL  
                                AND Bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) THEN 1 
                         WHEN @ResourceIDs IS NOT NULL 
                                AND Bettype IN (160,164,169,180) AND CHARINDEX(SUBSTRING(CAST(BetID AS VARCHAR(20)),2,5),@ResourceIDs)>0 THEN 1 
                         WHEN @ResourceIDs IS NOT NULL 
                                AND Bettype IN (135,168,173,174,175,176,192,193,210,211,212,213,214,215,216,217)  
                                AND CHARINDEX(CAST(Bettype AS VARCHAR(20)),@ResourceIDs)>0 THEN 1 
                         ELSE 0 END  
            AND 1 = CASE 
                WHEN @IsExcludeBetdaq = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) 
                        AND (@SelectedSet IS NULL OR (@SelectedSet LIKE '%6%' AND Bettype IN (1,2,3,20))) THEN 0
                WHEN @IsExcludeBetfair = 1 AND custid IN (2331, 1077687, 115770, 15523642) 
                        AND (@SelectedSet IS NULL OR (@SelectedSet LIKE '%6%' AND Bettype IN (1,2,3,20))) THEN 0
                WHEN @IsSettleAbandonedMatchIBC = 1 
                        AND (custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770, 15523642) 
                            AND recommend <> 1688156) 
                        AND statusID IN (112, 113) 
                        AND bettype IN (4, 6, 13, 26, 27, 30, 126, 129, 130, 131, 132, 133, 134, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 152
                            ,159,161,162,163,170,172,179,181,182,187,188,195,196,199,200,201,202,206,207, 302, 304,401,402,403,404,406,407,408,409,412,413) THEN 0
                WHEN @IsSettleAbandonedMatchIBC = 1 
                    AND statusID IN (112, 113) 
                    AND bettype = 216 THEN 0 
                ELSE 1
                END

        IF @@ROWCOUNT < 10000
            BREAK
    END
END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Calculate_RefundAll] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_RefundAll] TO [vnteam] AS [dbo]