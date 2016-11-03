USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Set_MatchSelDetail_Auto_1s]
    @MatchID					INT
    ,@IsSettleAbandonedMatchIBC	BIT = 0 OUTPUT

AS
/*    Creator: Jamie
    Date: 20150202
    Task: BetRadar - Auto settlement detail for manual calculation 
    DB: DBTXN/BODB02
    Original: 
    
    Revisions:
        - 20160830@Kathy: PH-AIO phase 2b [Redmine:#62861]
        - 20161118@Kathy: Changes on Auto Settlement [Redmine:#67328]
		- 20160505@Patrick: Move code select match info to another SP [RedmineId: #56587]

    Param's Explanation:
*/
BEGIN
    SET NOCOUNT ON 
            
    DECLARE    @tmpTicketStatus TABLE(
         ResourceID			VARCHAR(20)
        ,BetCount			INT
        ,InRunning			INT
        ,GroupId			SMALLINT
    )
    
    DECLARE    @tmpTicketStatusParlay TABLE(
         ResourceID			VARCHAR(20)
        ,BetCount			INT
        ,InRunning			INT
        ,GroupId			SMALLINT
    )
	
	IF EXISTS (
			SELECT 1
			FROM bettrans b WITH (NOLOCK)
				INNER JOIN dbo.f_Set_GetGroupBettypes() f
					ON b.bettype = f.BetType
			WHERE    f.GroupId = 8
					AND f.IsDetermined = 1
					AND matchid = @matchid AND statusID NOT IN (101, 102, 103) 
					AND ruben = 0 
		)
	BEGIN
		SELECT @IsSettleAbandonedMatchIBC = 1
	END
	
    INSERT INTO @tmpTicketStatus(ResourceID, BetCount, InRunning, GroupId)
    SELECT    
            CASE
                WHEN b.bettype IN (160, 164, 169, 180) THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5) 
                ELSE b.bettype 
            END AS ResourceID
            ,SUM(CASE    WHEN StatusID BETWEEN 101 AND 102 THEN 0
                        ELSE 1 END)
            ,SUM(CASE    WHEN StatusID = 0 THEN 1 
                        ELSE 0 END)
            ,MAX(f.GroupId)
    FROM    dbo.Bettrans b WITH (NOLOCK)
        INNER JOIN dbo.f_Set_GetGroupBettypes() f
            ON b.bettype = f.BetType
    WHERE    f.GroupId IN (3,4,8)
            AND matchID = @MatchID 
    GROUP BY CASE
                WHEN b.bettype IN (160, 164, 169, 180) THEN SUBSTRING(CAST(betID AS VARCHAR(20)),2,5) 
                ELSE b.bettype 
            END
	
	INSERT INTO @tmpTicketStatusParlay(ResourceID, BetCount, InRunning, GroupId)
    SELECT    
            CASE
                WHEN bm.bettype IN (160, 164, 169, 180) THEN SUBSTRING(CAST(bm.betcheck AS VARCHAR(20)),2,5) 
                ELSE bm.bettype 
            END AS ResourceID            
            ,SUM(CASE    WHEN bm.StatusID BETWEEN 101 AND 102 THEN 0
                        ELSE 1 END)
            ,SUM(CASE    WHEN bm.StatusID = 0 THEN 1 
                        ELSE 0 END)
            ,MAX(f.GroupId)
    FROM    dbo.Bettransm bm WITH (NOLOCK)
        INNER JOIN dbo.f_Set_GetGroupBettypes() f
            ON bm.bettype = f.BetType
    WHERE    f.GroupId IN (3,4,8)
            AND matchID = @MatchID 
    GROUP BY  CASE
                WHEN bm.bettype IN (160, 164, 169, 180) THEN SUBSTRING(CAST(bm.betcheck AS VARCHAR(20)),2,5) 
                ELSE bm.bettype 
            END
	
	IF EXISTS (SELECT TOP 1 1 FROM @tmpTicketStatus WHERE GroupId = 3)
		SET @IsExistHtFgLg = 1
	ELSE IF EXISTS (SELECT TOP 1 1 FROM @tmpTicketStatusParlay WHERE GroupId = 3)
		SET @IsExistHtFgLg = 1
	
	IF EXISTS (SELECT TOP 1 1 FROM @tmpTicketStatus WHERE GroupId = 4)
		SET @IsExistFgLg = 1
	ELSE IF EXISTS (SELECT TOP 1 1 FROM @tmpTicketStatusParlay WHERE GroupId = 4)
		SET @IsExistFgLg = 1
	
	

    -- Detail
    ;WITH cteBettype 
    AS(
		SELECT	CASE 
					WHEN BetType IN (160, 164, 169, 180, 216) THEN CAST(BetType AS VARCHAR(20)) + '__'
					ELSE CAST(BetType AS VARCHAR(20))
				END AS ResourceId
				,GroupId
		FROM	dbo.f_Set_GetGroupBettypes()
		WHERE	GroupId = 8
    )           
    SELECT    
		 ResourceID = CASE WHEN COALESCE(r.ResourceID,t.ResourceID,p.ResourceID) ='216' THEN '21601' ELSE COALESCE(r.ResourceID,t.ResourceID,p.ResourceID) END 
            ,TicketStatus = CASE 
								WHEN ISNULL(t.BetCount,0) = 0 AND ISNULL(p.BetCount,0) = 0 THEN 'No Ticket'
								WHEN t.InRunning > 0 THEN 'Running'
								WHEN ISNULL(t.BetCount,0) = 0 AND p.InRunning > 0 THEN 'Parlay Running'
                                ELSE 'Calculated'
                            END
         ,HomeValue = CASE WHEN r.ResourceId BETWEEN 214 AND 215 THEN r.AwayValue ELSE r.HomeValue END
        ,r.OtherInfo
        ,r.ResultStatusID
        ,r.SettlementStatusID
    FROM    @tmpTicketStatus t
			FULL JOIN @tmpTicketStatusParlay p
				ON t.resourceId = p.ResourceID
            FULL JOIN( 
                SELECT  r.MatchID  
                        ,r.ResourceId
                        ,CASE WHEN r.ResourceID LIKE '216__' THEN '216' ELSE r.ResourceID END AS ResourceID2 
                        ,r.HomeValue
                        ,r.AwayValue
                        ,r.OtherInfo
                        ,r.ResultStatusID
                        ,r.SettlementStatusID
                        ,c.GroupId
                FROM    DBPRO.bodb02.dbo.ResultDetail r WITH (NOLOCK)
					INNER JOIN	cteBettype c
						ON	r.MatchID = @MatchID
							AND r.ResourceId LIKE c.ResourceId                        
            ) r ON ISNULL(t.ResourceID, p.ResourceID) = r.ResourceId2
    WHERE	COALESCE(r.GroupId,t.GroupId,p.GroupId) = 8
    ORDER BY CASE WHEN COALESCE(r.ResourceID,t.ResourceID,p.ResourceID) ='216' THEN '21601' ELSE COALESCE(r.ResourceID,t.ResourceID,p.ResourceID) END  ASC 

END




GO
GRANT EXECUTE ON [dbo].[NAP_Set_MatchSelDetail_Auto_1s] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSelDetail_Auto_1s] TO [vnteam] AS [dbo]