USE [bodb02]
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_RefundFT] @matchid INT
    ,@IsExcludeBetdaq BIT = 0
    ,@IsExcludeBetfair BIT = 0
    ,@IsSettleAbandonedMatchIBC BIT = 0
    ,@fth SMALLMONEY = 0
    ,@fta SMALLMONEY = 0
    ,@IsRefundHT BIT = 0
    ,@IsHTCal BIT = 0
AS
/*    Created by: Kathy
    Date: 20140213
    Task: Refund FT 
    DB: DBTXN/BODB02
    
    Revisions:
        - 20140304@Kathy: Execute settlement for abandoned/postponed matches- Clean Sheet, Both/One/Neither team to score, To Win To Nil 
        - 20140411@Kathy: Add more param for LAS command
        - 20140426@Kathy: Add 1H FGLG, 1H Total Goal (126, 127) [Redmine:#14449]
        - 20140729@Kathy: Add one more account(BF3) into BetFair's group [Redmine:#19665]
        - 20140620@Kathy: Apply BetRadar [Redmine:#17142]
        - 20140728@Kathy: Settle determined tickets for Correct Score(4,30), Total Goal (6,126) [Redmine:#19310]
        - 20140811@Kathy: Support new 11 bettypes [Redmine:#19667]
        - 20140905@Lukas: exclude virtual racing bettype 1231,1232,1233
        - 20140909@Kathy: Exclude virtual racing (bettype 1237, 1238), outright (bettype 10, 31, 32, 33), keno (1501 -> 1599)
        - 20150422@Jamie: Settlement Betradar phase 2 [Redmine: #27212]
        - 20150605@Johnson: Exclude SOLD/BOUGHT/COM tickets from bettrade [Redmine:#35921] 
		- 20150716@Johnson: Exclude range bettypes of Metric Gaming from settlement of SB [Redmine: #37688]
		- 20150919@Kathy: Intergrate Myanmar Odds ( 4 new bettypes: 301->304)
		- 20151125@Patrick: Apply 28 Live Bettypes for Settlement [Redmine:#47843]
        
    Param's Explanation:
        @IsRefundHT: Indicate whether or not match has been refunded HT
        @IsHTCal: Indicate whether or not match has been calculated HT
                    
    Note: For settlement SPs should hardcode the custid of betdaq customer to avoid replication problem
*/
BEGIN
    SET NOCOUNT ON

    --- LAS settlement 
    IF @@SERVERNAME IN ('DB052', 'DB054', 'DB231', 'DB232','DB215') AND EXISTS (
            SELECT *
            FROM sys.databases
            WHERE NAME = 'LASDB'
            )
    BEGIN
        DECLARE @LASCommand NVARCHAR(1000)
            ,@createdDate DATETIME

        SELECT @LASCommand = 'EXEC [dbo].[Admin_Calculate_RefundFT] @matchid = ' + CONVERT(NVARCHAR(10), @matchid)
                            + ', @IsSettleAbandonedMatchIBC = ' + CONVERT(NVARCHAR(10), ISNULL(@IsSettleAbandonedMatchIBC, 0)) 
                            + ', @IsRefundHT = ' + CONVERT(NVARCHAR(10), ISNULL(@IsRefundHT, 0))                                             
                            + ', @IsHTCal = ' + CONVERT(NVARCHAR(10), ISNULL(@IsHTCal, 0))                                                                                         

            ,@createdDate = GETDATE()

        EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand] @SPName = 'Admin_Calculate_RefundFT'
            ,@SQLCommand = @LASCommand
            ,@CreatedDate = @createdDate
            ,@StatusID = 0 -- waiting
            ,@MatchID = @matchid
            ,@Bettype = 0 -- hardcode
            ,@Status = 'waiting'
            ,@BetCount = 0
    END
    
    WHILE 1 = 1
    BEGIN
        UPDATE TOP (10000) dbo.bettrans WITH (ROWLOCK, UPDLOCK)
        SET [status] = N'Refund'
            ,statusID = 103
            ,ruben = 1
            ,winlost = actual_stake
            ,awinlost = 0
            ,mwinlost = 0
            ,swinlost = 0
            ,playercomm = 0
            ,comm = 0
            ,acomm = 0
            ,scomm = 0
        WHERE matchid = @matchid AND statusID NOT IN (103, 101, 102) 
            AND bettype NOT IN (7, 8, 15, 12, 21, 30, 14, 125, 126, 127, 129, 136, 138, 143, 151, 165,167,179,181,182,188,191,200,201,202,203,204,205,207,209, 303, 304,403,404,410,411,412) 
            AND bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) --Auto bettypes Betradar 2 
            AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
            AND bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product        
            AND bettype NOT BETWEEN 1501 and 1599 -- Keno
			AND bettype NOT IN (901,902,903)--bettrade tickets
			AND bettype NOT BETWEEN 801 and 899 -- Metric Gaming
            AND 1 = CASE 
                WHEN @IsExcludeBetdaq = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 0
                WHEN @IsExcludeBetfair = 1 AND custid IN (2331, 1077687, 115770, 15523642) THEN 0
                WHEN @IsSettleAbandonedMatchIBC = 1 AND (custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770, 15523642) 
                    AND recommend <> 1688156) AND statusID IN (112, 113) 
                    AND (( @IsRefundHT = 1 AND bettype IN (4, 6, 13, 26, 27, 130, 131, 132, 144, 145,159, 161, 162, 163, 170, 172, 195, 196, 199, 206,401,402,405,406,407,408,409)) 
                            OR (@IsHTCal = 1 AND bettype IN (4, 6, 13, 26, 27, 128, 130, 131, 132, 133, 134, 140, 141, 142, 144, 145, 146, 147, 148, 149, 150, 152,159, 161, 162, 163, 170, 172, 187, 195, 196, 199, 206, 302,401,402,405,406,407,408,409)))
                    THEN 0
                ELSE 1
                END

        IF @@ROWCOUNT < 10000
            BREAK
    END
END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Calculate_RefundFT] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_RefundFT] TO [vnteam] AS [dbo]