ALTER PROCEDURE [dbo].[Acc_CustomerSelAllInfo]
	@username VARCHAR(30)
AS

/*
Created: 
Task : Get move bet day, balanceup day
DB: DBAGE/bodb02
Original:Accounting site

Revisions:
	- 20080925@PhuongDao: Calculate Balance with correct date instead of date - 1 
		- Add yesterday balance info
		- Web calculation (for current balance & yesterday balance):
		- Balance (general) = self cash + total downline cash
		- Agent balance = his cash + total cash of his members
		- Master balance = his cash + total cash of his agents + total cash of his members
		- Super balance = his cash + total cash of his masters  + total cash of his agents + total cash of his members
	- Dung@20081021 : Get ci.danger field instead of ci.dangercust in General info block	
	- Khoa@20090312 : Get ci.autosuspend field 
	- Qui@20090317 : Get ci.disablecasino, ci.synccasino field
	- 20090320@PhuongDao: Get the auto-suspend status of the upline. 
    - Shifu@20090324: Get c.site, customer's site information
	- 20090325@PhuongDao: Get the HR, FI status of Downlines under the customer
	- 20090401@Shifu: Get member website base agent website
	- 20090701@Phuc: get disableautoMPT.
	- 20090717@pluto: get danger2, danger3.
	- 20090729@Simon: get Status DisableOutRight.
	- 20090731@pluto:get Enabled status: Member, Agent, Master, Super
	- 20100505@pluto:get DisableDownlinesOpenTote status
	- 20100608@pluto:get DisableDownlinesCasino status
	- 20100619@Thien: get custID FROM Username on DB06, via f_GetCustIDFromUsername function
	- 201000909@Ethan:get  DisableBingo, DisableDownlinesBI, syncbingo, DisableDownlinesNumber, DisableNumber  status
	- 20101007@Henry: Change column transid FROM INT to BIGINT
	- 20101015@Ethan: Get Limited Per IP value @LimitPerIP + SelectedBetting
	- 20110315@Johnson: remove get status Horse Racing
	- 20110429@Lukas: get downline statistics (number of Active, closed, suspended)
	- 20110516@Lukas: re-arrange bettype
	- 20110718@Sophia: because username2 add prefix 'Agency$', so hide the prefix when SELECT username2
	- 20110721@Sophia: remove prefix 'Agency$' when SELECT username2
	- 20110822@Elly: - Correct Turnover of sports book since Sep 01, 2011
	- 20120131@Johnson: Get DisableLiveCasino, SyncLiveCasino status, currencyid
	- 20120302@Jim: add more isBA column in General info return
	- 20120504@Dom: add more IsDeposit column in General info return
	- 20120423@Lukas: check if roleid > 4 then return
	- 20120815@Sophia: Get DisableVirtualSports, HideVirtualSports, DisableDownlinesVirtualSports
	- 20120822@Elodie: Get Abnormal field
	- 20120927@Johnson: Get double comm losing status
	- 20130121@Dan: change linked server DB06 to DBARC, DB052 to DBLIC
	- 20130322@Ethan:Get column NicknameLoginOnly for Super, Master, Agent
	- 20130422@Johnson: get field LastChangedSecurityCodeDate
	- 20130719@Elodie: Correct link server DBACC instead of DBARC
	- 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
	- 20131108@Elodie: Splitting bodb02 INTo CustDB (call CustLoginInfo, CustLoginInfo_Member by link server DBTXN.CustDB)
	- 20140305@Dom: Change Outstanding formula to get FROM Bettrans AND Translog for Keno tickets
	- 20140820@Logan:   Add status for E-Sports [Redmine: #20531]
	- 20140912@Logan:   Add status of Direct/Indirect Account [Redmine: #15267]
	- 20141120@Johnson: correct Last transaction date for super [Redmine: #26006]
	- 20141226@Johnson: Separate virtual rate by sporttype, bettype [Redmine: #25840]			
	- 20150422@Elodie: Add Gold Deluxe product [Redmine:#34486]
	- 20150606@Kathy: Migrate custDB to new server DBCust(Get credit from DBCust.CustDB) [Redmine:#36216]
	- 20150707@Elodie: Add Super Live product [Redmine: #35776]
	- 20150707@Jim: exclude Metric Gaming running ticket from bettrans (Feature #38789)
	 
	
Param's Explanation:
	@username: username want to get all info related
*/		

BEGIN
    SET NOCOUNT ON

    DECLARE @custid INT
          , @uplineid INT
          , @roleid TINYINT
          , @UsedCredit MONEY
          , @DisableDownlinesHR BIT
          , @DisableDownlinesOpenTote BIT
          , @DisableDownlinesFI BIT
          , @DisableDownlinesCS BIT
          , @DisableDownlinesBI BIT
          , @DisableDownlinesNumber BIT
          , @DisableDownlinesLiveCS BIT
          , @DisableDownlinesHRFixedOdds BIT
          , @DisableDownlinesVirtualSports BIT
          , @DisableDownlinesEsports BIT
          , @DownlinesSelectedBetting BIT
		  , @DisableDownlinesGoldDeluxe BIT
		  , @DisableDownlinesSuperLive BIT
          , @IsInternal BIT
          , @LimitPerIP TINYINT
          , @SelectedBetting BIT
          , @NicknameLoginOnly BIT
          , @LastChangedSecurityCodeDate DATETIME
		  , @HasDownline BIT = 0

    DECLARE @todaySuperCash MONEY
          , @todayMasterCash MONEY
          , @todayAgentCash MONEY
          , @todayCustCash MONEY

    DECLARE @currentDate DATETIME 
    DECLARE @membersite VARCHAR(10)
    DECLARE @TotalMAgentActive INT,
		    @TotalMAgentClosed INT,
		    @TotalMAgentSuspended INT,
		    @TotalAgentActive INT,
		    @TotalAgentClosed INT,
		    @TotalAgentSuspended INT,
		    @TotalMemberActive INT,
		    @TotalMemberClosed INT,
		    @TotalMemberSuspended INT

    DECLARE @TransLogOT MONEY
          , @TransLogOTPT MONEY

    DECLARE @IsHideDirectStatus BIT = 0
          , @IsCheckedDirectStatus BIT = 0
          , @IsDisabledDirectStatus BIT = 0

    DECLARE @NegativeBetEffectiveDate DATETIME
    SET @NegativeBetEffectiveDate='2011-09-01'

    SELECT @currentDate = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)

    --Get CustID FROM DB06, WHERE got index on Username AND Username2
    EXEC @custid = DBACC.bodb02.dbo.f_GetCustIDFromUsername @username

    IF @custid is NULL
    BEGIN
	    RETURN
    END
    ELSE
    BEGIN
	    SELECT @roleid = roleID
	      FROM custinfo WITH(NOLOCK)
	     WHERE custid = @custid
    END

    IF @roleid > 4
	    RETURN
    -----------------------------	

    SELECT @DisableDownlinesFI = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableFinancial,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableFinancial = 1)
										      WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableFinancial,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableFinancial = 1) 											 
										      WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableFinancial,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableFinancial = 1) 											 
										      ELSE 0 END 	
    										  
    SELECT @DisableDownlinesCS = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableCasino,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableCasino = 1)
										      WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableCasino,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableCasino = 1) 											 
										      WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableCasino,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableCasino = 1) 											 
										      ELSE 0 END

    SELECT @DisableDownlinesBI = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableBingo,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableBingo = 1)
										      WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableBingo,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableBingo = 1) 											 
										      WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableBingo,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableBingo = 1) 											 
										      ELSE 0 END				
    			
    SELECT @DisableDownlinesNumber = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableNumber,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableNumber = 1)
										      WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableNumber,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableNumber = 1) 											 
										      WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableNumber,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableNumber = 1) 											 
										      ELSE 0 END	
    										  
    SELECT @DisableDownlinesLiveCS = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableLiveCasino,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableLiveCasino = 1)
										      WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableLiveCasino,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableLiveCasino = 1) 											 
										      WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableLiveCasino,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableLiveCasino = 1) 											 
										      ELSE 0 END
    										  
    SELECT @DisableDownlinesHRFixedOdds= CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableHRFixedOdds,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableHRFixedOdds = 1)
										      WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableHRFixedOdds,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableHRFixedOdds = 1) 											 
										      WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableHRFixedOdds,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableHRFixedOdds = 1) 											 
										      ELSE 0 END
    										  
    SELECT @DisableDownlinesVirtualSports = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableVirtualSports,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableVirtualSports = 1)
										     WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableVirtualSports,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableVirtualSports = 1) 											 
										     WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableVirtualSports,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableVirtualSports = 1) 											 
										     ELSE 0 END

    SELECT @DisableDownlinesEsports = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableEsports, 0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableEsports = 1)
											WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableEsports, 0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableEsports = 1)
											WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableEsports, 0) FROM custInfo WITH(NOLOCK) WHERE recommend = @custid AND roleid = 1 AND DisableEsports = 1)
											ELSE 0 END

    SELECT @DisableDownlinesGoldDeluxe = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableGoldDeluxe,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableGoldDeluxe = 1)
										      WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableGoldDeluxe,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableGoldDeluxe = 1) 											 
										      WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableGoldDeluxe,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableGoldDeluxe = 1) 											 
										      ELSE 0 END	

	SELECT @DisableDownlinesSuperLive = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableSuperLive,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableSuperLive = 1)
										      WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableSuperLive,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableSuperLive = 1) 											 
										      WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableSuperLive,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableSuperLive = 1) 											 
										      ELSE 0 END												  									  										  							  
    -------------------------------------------------------------------------
    DECLARE @IsDeposit BIT --Identify deposit customer
	    SET @IsDeposit = 0

    IF @roleid in (2,3,4)
    BEGIN
	    IF EXISTS (SELECT 1 FROM dbo.Customer c WITH(NOLOCK)
							    INNER JOIN dbo.Site s WITH(NOLOCK) ON c.site = s.site 
					    WHERE custid = @custid
						      AND isLicensee =1)
	    SET @IsDeposit =1
    	
	    SELECT @LastChangedSecurityCodeDate = LastChangedSecurityCodeDate
	    FROM DBCUST.CustDB.dbo.CustLoginInfo WITH(NOLOCK)
	    WHERE custid = @custid
    END

    --Get member site
    IF @roleid = 1
    BEGIN
	    SELECT	@membersite = c.site, @uplineid = c.custid
	    FROM	customer c WITH(NOLOCK)
		    INNER JOIN custinfo ci WITH(NOLOCK) ON c.custid = ci.recommend
	    WHERE ci.custid = @custid
    	
	    IF EXISTS (SELECT 1 FROM dbo.Customer c WITH(NOLOCK)
							    INNER JOIN dbo.Site s WITH(NOLOCK) ON c.site = s.site 
					    WHERE custid = @uplineid
						      AND isLicensee =1)

	    SET @IsDeposit =1
    	
	    SELECT @LastChangedSecurityCodeDate = LastChangedDate
	    FROM DBCUST.CustDB.dbo.CustLoginInfo_Member WITH(NOLOCK)
	    WHERE custid = @custid
    END

    /*
    --Get INTernal status
    SELECT @IsInternal = CASE @roleid WHEN 4 THEN (SELECT ISNULL(IsInternal, 0) FROM custSuper WITH(NOLOCK) WHERE custid = @custid)
								      WHEN 3 THEN (SELECT ISNULL(IsInternal, 0) FROM custMaster WITH(NOLOCK) WHERE custid = @custid)
								      WHEN 2 THEN (SELECT ISNULL(IsInternal, 0) FROM custAgent WITH(NOLOCK) WHERE custid = @custid 		)
								      WHEN 1 THEN (SELECT ISNULL(IsInternal, 0) FROM custAgent WITH(NOLOCK) WHERE custid = @uplineid)
								      ELSE 0 END 	
    */								  

    SET @LimitPerIP = 0
    SET @NicknameLoginOnly=0
    SET @SelectedBetting = 0
    SET @IsInternal = 0
    SET @DownlinesSelectedBetting = 0

    IF @roleid = 4 --super
    BEGIN
		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3

	    SELECT @IsInternal = ISNULL(IsInternal, 0)
	         , @LimitPerIP = ISNULL(LimitPerIP, 0)
	         , @SelectedBetting = ISNULL(SelectedBetting, 0)
	         , @NicknameLoginOnly = ISNULL(NicknameLoginOnly, 0)
	      FROM custSuper WITH(NOLOCK)
	     WHERE custid = @custid

	    SELECT TOP 1 @DownlinesSelectedBetting = ISNULL(SelectedBetting, 0)
	      FROM custMaster WITH(NOLOCK)
	     WHERE custid IN (SELECT mrecommend 
	                        FROM custinfo WITH(NOLOCK)  
					       WHERE srecommend = @custid 
						     AND roleid = 3
				         )

	    SELECT @TotalMAgentActive =
	             ISNULL(SUM(CASE
	                          WHEN RoleID = 3 AND Closed = 0 AND ISNULL(reject, 0) = 0 THEN 1
	                          ELSE 0
	                        END
	                       ), 0
	                   )
	         , @TotalMAgentClosed =
	             ISNULL(SUM(CASE
	                          WHEN RoleID = 3 AND Closed = 1 THEN 1
	                          ELSE 0 END
	                       ), 0
	                   )
             , @TotalMAgentSuspended =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 3 AND ISNULL(reject, 0) = 1 AND Closed = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalAgentActive =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 2 AND Closed = 0 AND ISNULL(reject, 0) = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalAgentClosed =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 2 AND Closed = 1 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalAgentSuspended =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 2 AND ISNULL(reject, 0) = 1 AND Closed = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalMemberActive =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 1 AND Closed = 0 AND ISNULL(reject, 0) = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalMemberClosed =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 1 AND Closed = 1 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalMemberSuspended =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 1 AND ISNULL(reject, 0) = 1 AND Closed = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
	      FROM dbo.custInfo WITH(NOLOCK)
	     WHERE srecommend = @custid
    END								  
    ELSE IF @roleid = 3 --master
    BEGIN
		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2

	    SELECT @IsInternal = ISNULL(IsInternal, 0)
	         , @LimitPerIP = ISNULL(LimitPerIP, 0)
	         , @SelectedBetting = ISNULL(SelectedBetting, 0)
	         , @NicknameLoginOnly = ISNULL(NicknameLoginOnly, 0)
	      FROM custMaster WITH(NOLOCK)
	     WHERE custid = @custid
    	
	    SELECT TOP 1 @DownlinesSelectedBetting = ISNULL(SelectedBetting, 0)
	      FROM custAgent WITH(NOLOCK)
	     WHERE custid IN (SELECT recommend
	                        FROM custinfo WITH(NOLOCK)  
					       WHERE srecommend = @custid 
						     AND roleid = 2
				         )
	    SELECT
	    @TotalAgentActive = ISNULL(SUM(CASE WHEN RoleID = 2 AND Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
	    @TotalAgentClosed = ISNULL(SUM(CASE WHEN RoleID = 2 AND Closed = 1 THEN 1 ELSE 0 END), 0),
	    @TotalAgentSuspended = ISNULL(SUM(CASE WHEN RoleID = 2 AND ISNULL(reject,0) = 1 AND Closed = 0 THEN 1 ELSE 0 END), 0),
    	
	    @TotalMemberActive = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
	    @TotalMemberClosed = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 1 THEN 1 ELSE 0 END), 0),
	    @TotalMemberSuspended = ISNULL(SUM(CASE WHEN RoleID = 1 AND ISNULL(reject,0) = 1 AND Closed = 0 THEN 1 ELSE 0 END), 0)
	    FROM Custinfo WITH(NOLOCK)
	    WHERE MRecommend = @custid

        --------------

    END
    ELSE IF @roleid = 2 --agent
    BEGIN
		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE recommend = @custid AND roleid = 1

	    SELECT 
		    @IsInternal = ISNULL(IsInternal, 0),
		    @LimitPerIP = ISNULL(LimitPerIP, 0),
		    @SelectedBetting =  ISNULL(SelectedBetting, 0),
		    @NicknameLoginOnly =ISNULL(NicknameLoginOnly, 0)
	    FROM custAgent WITH(NOLOCK) WHERE custid = @custid
    	
	    SELECT
	    @TotalMemberActive = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
	    @TotalMemberClosed = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 1 THEN 1 ELSE 0 END), 0),
	    @TotalMemberSuspended = ISNULL(SUM(CASE WHEN RoleID = 1 AND ISNULL(reject,0) = 1 AND Closed = 0 THEN 1 ELSE 0 END), 0)
	    FROM Custinfo WITH(NOLOCK)
	    WHERE Recommend = @custid
    END
    ELSE IF @roleid = 1 --member
    BEGIN
	    SELECT 
		    @IsInternal = ISNULL(IsInternal, 0)
	    FROM custAgent WITH(NOLOCK) WHERE custid = @uplineid
    END
    
    --Direct Customer Status
    SELECT @IsHideDirectStatus =
             CASE
               WHEN roleid = 4 OR Enabled = 0 OR @IsInternal = 1 OR @IsDeposit = 1 THEN 1
               ELSE 0
             END
      FROM dbo.custInfo WITH(NOLOCK)
     WHERE custid = @custid

    IF @IsHideDirectStatus = 0
    BEGIN
        SELECT @IsCheckedDirectStatus = 1
             , @IsDisabledDirectStatus = 1
          FROM dbo.custInfo ci WITH(NOLOCK)
         WHERE ci.custid = @custid
           AND ((ci.roleid = 1
                 AND EXISTS (SELECT 1
                               FROM dbo.Acc_CustDirect cd WITH(NOLOCK)
                              WHERE ci.recommend = cd.custid
                                AND cd.roleid = 2
                            )
                )
                OR (ci.roleid = 2
                    AND EXISTS (SELECT 1
                                  FROM dbo.Acc_CustDirect cd WITH(NOLOCK)
                                 WHERE ci.mrecommend = cd.custid
                                   AND cd.roleid = 3
                               )
                   )
                OR (ci.roleid = 3
                    AND EXISTS (SELECT 1
                                  FROM dbo.Acc_CustDirect cd WITH(NOLOCK)
                                 WHERE ci.srecommend = cd.custid
                                   AND cd.roleid = 4
                               )
                   )
               )

        SELECT @IsDisabledDirectStatus = 1
             , @IsCheckedDirectStatus = 0
          FROM dbo.Acc_CustDirect WITH(NOLOCK)
         WHERE custid = @custid
    END

    --General info
    DECLARE @isBA BIT
    IF EXISTS (
			     SELECT 1 FROM DBLIC.bodb_Licensee.dbo.LicenseeBAHistory lb WITH(NOLOCK)
			     WHERE custid=@custid AND status='running'
			    )
	    SET @isBA=1
    ELSE
	    SET @isBA=0

	DECLARE @credit MONEY
	SELECT @credit = credit
	FROM DBCUST.CustDB.dbo.CustInfo WITH(NOLOCK)
	WHERE custid = @custid
	
    SELECT c.custid, c.username, c.firstname, c.lastname, 
	    c.username2, 		
	    ci.roleid, 
	    lastlogged, 
	    iplogin lastloginip, 
	    pwdexpiry, 
	    @credit as credit, --ci.credit, 
	    e.currency,
	    e.exchangeid,
	    e.actualrate,
	    --virtual rate status
	    ci.virtualmultiplier as EnableVirtualrate,
	    important,
	    ci.danger,
	    ci.danger2,
	    ci.danger3,
	    ci.Abnormal,
	    ci.closed, ci.reject as suspended, ci.autosuspend,	
	    ci.DisableFinancial,
	    ISNULL(@DisableDownlinesFI,0) DisableDownlinesFI,
	    ISNULL(@DisableDownlinesCS,0) DisableDownlinesCS,
	    ISNULL(@DisableDownlinesBI,0) DisableDownlinesBI,
	    ISNULL(@DisableDownlinesNumber,0) DisableDownlinesNumber,
	    ISNULL(@DisableDownlinesLiveCS,0) DisableDownlinesLiveCS,
	    ISNULL(@DisableDownlinesHRFixedOdds,0) DisableDownlinesHRFixedOdds,
	    ISNULL(@DisableDownlinesVirtualSports,0) DisableDownlinesVirtualSports,
	    ISNULL(@DownlinesSelectedBetting,0) DownlinesSelectedBetting,
		ISNULL(@DisableDownlinesEsports, 0) DisableDownlinesEsports,
		ISNULL(@DisableDownlinesGoldDeluxe,0) DisableDownlinesGoldDeluxe,
		ISNULL(@DisableDownlinesSuperLive,0) DisableDownlinesSuperLive,
	    ci.DisableBingo,
	    ci.DisableNumber,
	    ci.DisableOutRight,
	    ci.disablecasino,
	    ci.synccasino,
	    ci.syncbingo,
	    ci.disableLiveCasino,
	    ci.synclivecasino,
	    ci.DisableHRFixedOdds,
	    ci.DisableVirtualSports,
	    ci.HideVirtualSports,
	    ci.DoubleCommLosing,	    	   
		ci.DisableEsports,
		ISNULL(ci.DisableGoldDeluxe,1) AS DisableGoldDeluxe,
		ISNULL(ci.HideGoldDeluxe,1) AS HideGoldDeluxe,
		ISNULL(ci.DisableSuperLive,1) AS DisableSuperLive,
	    ci.Enabled,
	    @isBA IsBA,
	    @IsDeposit IsDeposit, 
	    c.phone, c.mobilephone, c.fax, c.creatdate as createdate,
	    c.site,
	    @IsInternal as IsInternal,
	    @LimitPerIP as LimitPerIP,
	    @SelectedBetting as SelectedBetting,
	    @NicknameLoginOnly as NicknameLoginOnly,
	    @membersite as membersite,
	    @LastChangedSecurityCodeDate as LastChangedSecurityCodeDate,
	    @IsHideDirectStatus IsHideDirectStatus,
	    @IsCheckedDirectStatus IsCheckDirectStatus,
	    @IsDisabledDirectStatus IsDisabledDirectStatus,
		@HasDownline AS HasDownline
    FROM customer c WITH(NOLOCK)
	    inner join custinfo ci WITH(NOLOCK) on c.custid = ci.custid
	    inner join exchange e WITH(NOLOCK) on c.currency = e.exchangeid 
    WHERE c.custid = @custid
    ----------------------------
    -------------------------------------------------------------------------
    --Agency Info
    SELECT case when c.roleid = 1 then c.custid else NULL end as memberID,
	    case when c.roleid = 1 then c.username else NULL end as memberName,	
	    case @roleid	when 1 then ISNULL(a.autosuspend,0) 
					    when 2 then ISNULL(m.autosuspend,0) 
					    when 3 then ISNULL(s.autosuspend,0) 
					    else 0 end uplineAutosuspend,							    		
	    a.custid as agentID,
	    a.username as agentName,	
	    a.Enabled as agentEnabled,
	    m.custid as masterID,
	    m.username as masterName,
	    m.Enabled as masterEnabled,
	    s.custid as superID,
	    s.username as superName,
	    s.Enabled as superEnabled
    	
    FROM custinfo c WITH(NOLOCK)
	    left join custinfo a WITH(NOLOCK) on c.recommend = a.custid
	    left join custinfo m WITH(NOLOCK) on c.mrecommend = m.custid
	    left join custinfo s WITH(NOLOCK) on c.srecommend = s.custid
    where
	    c.custid = @custid
    -------------------------------------------------------------------------
    --Balance Info
    if @roleid = 1
    BEGIN
	    /*
	    SELECT @y_CustomerCash = sum(case when ruben=1 then winlost-actual_stake+playercomm else 0 end)
	    FROM bettrans WITH(NOLOCK) 
	    WHERE custid = @custid AND bettrans.winlostdate < convert(varchar(10), CURRENT_TIMESTAMP, 120)			
	    */
    	
	    SELECT @todayCustCash = ISNULL(SUM(winlost-actual_stake+playercomm) ,0)
	    FROM dbo.bettrans WITH(NOLOCK)
	    WHERE custid = @custid AND ruben = 1 AND bettype < 19001 
		    AND winlostdate >= convert(varchar(10), CURRENT_TIMESTAMP, 120)
    	
	    SELECT @TransLogOT = SUM(ABS(actual_stake))
	    FROM translog(NOLOCK) WHERE custid = @custid AND statusID = 0

	    SELECT	ISNULL(Balance.Cash,0) Cash,
			    ISNULL(Balance.Cash,0) - @todayCustCash yesterday_Cash,
			    ISNULL(Balance.outstanding,0)+ISNULL(@TransLogOT,0) outstanding,
			    Balance.lastTxn lastTxn 
	    FROM(		
		    SELECT 
			    ISNULL(sum(case when ruben=1 then winlost-actual_stake+playercomm else 0 end),0) Cash,
			    sum(case when ruben=0 then CASE WHEN winlostdate<@NegativeBetEffectiveDate THEN actual_stake ELSE ABS(actual_stake)END else 0 end) outstanding, 
			    max(transdate) lastTxn 
		    FROM dbo.bettrans WITH(NOLOCK) 
		    WHERE custid = @custid
				AND (
				(bettrans.bettype NOT IN (801,802,803,804,805,806)
				AND ruben =0)
				OR ruben <> 0
				)
	    ) Balance 

    END 
    else if @roleid = 2
    BEGIN
	    SELECT @UsedCredit = sum(credit)  
	    FROM DBCUST.CustDB.dbo.custinfo WITH(NOLOCK) 
	    WHERE roleid=1 
		     AND recommend = @custid
	    /*	 
	    SELECT 
		    @y_AgentCash = sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end),
		    @y_CustomerCash = sum(case when custid <> recommend AND ruben=1 then winlost-actual_stake+playercomm else 0 end)
	    FROM bettrans WITH(NOLOCK) 
	    WHERE recommend = @custid AND bettrans.winlostdate < convert(varchar(10), CURRENT_TIMESTAMP, 120)			
	    */

	    SELECT 	@todayAgentCash = ISNULL(SUM(awinlost+comm-playercomm),0),
			    @todayCustCash = ISNULL(SUM(winlost-actual_stake+playercomm),0)
	    FROM dbo.bettrans WITH(NOLOCK)
	    WHERE  recommend = @custid AND ruben = 1 AND bettype < 19001 
		    AND winlostdate >= convert(varchar(10), CURRENT_TIMESTAMP, 120)

	    SELECT @TransLogOT = SUM(actual_stake),
			    @TransLogOTPT = SUM(actual_stake * apositiontaking)
	    FROM translog(NOLOCK) WHERE recommend = @custid AND statusID = 0
    		
	    SELECT	ISNULL(Balance.agentCash,0) agentCash,
			    ISNULL(Balance.agentCash,0) - @todayAgentCash yesterday_agentCash,	
			    ISNULL(Balance.agentPositionTaking,0)+ISNULL(@TransLogOTPT,0) agentPositionTaking,
			    ISNULL(Balance.customerCash,0) customerCash,
			    ISNULL(Balance.customerCash,0) - @todayCustCash yesterday_customerCash,
			    ISNULL(Balance.customerOutstanding,0)+ISNULL(@TransLogOT,0) customerOutstanding,
			    Balance.lastTxn lastTxn,
			    @UsedCredit as agentUsedCredit
	    FROM (	
		    SELECT 
			    sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end) agentCash,
			    sum(case when ruben=0 then actual_stake * apositiontaking else 0 end) agentPositionTaking, 
			    sum(case when custid <> recommend AND ruben=1 then winlost-actual_stake+playercomm else 0 end) customerCash, 
			    sum(case when custid <> recommend AND ruben=0 then actual_stake else 0 end) customerOutstanding, 
			    max(transdate) lastTxn
		    FROM dbo.bettrans WITH(NOLOCK) 
		    WHERE recommend = @custid
				AND (
				(bettrans.bettype NOT IN (801,802,803,804,805,806)
				AND ruben =0)
				OR ruben <> 0
				)
	    )Balance 

    END
    else if @roleid = 3
    BEGIN
	    DECLARE @DisableAutoMPT BIT
	    --Get disable auto MPT
	    SELECT @DisableAutoMPT = DisableAutoMPT FROM CustMaster (nolock) WHERE CustID = @CustID

	    SELECT @TransLogOT = SUM(actual_stake),
			    @TransLogOTPT = SUM(actual_stake * mpositiontaking)
	    FROM translog(NOLOCK) WHERE mrecommend = @custid AND statusID = 0
    	
	    SELECT @UsedCredit = sum(credit)  
	    FROM DBCUST.CustDB.dbo.custinfo WITH(NOLOCK) 
	    WHERE roleid=2 
		    AND mrecommend = @custid
	    /*	
	    SELECT 
		    @y_MasterCash = sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end),
		    @y_AgentCash = sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end),
		    @y_CustomerCash = sum(case when custid <> recommend AND custid <> mrecommend AND ruben=1 then winlost-actual_stake+playercomm else 0 end)
	    FROM bettrans WITH(NOLOCK) 
	    WHERE mrecommend = @custid AND bettrans.winlostdate < convert(varchar(10), CURRENT_TIMESTAMP, 120)			
	    */	
    				
	    SELECT	@todayMasterCash = ISNULL(sum(mwinlost+acomm-comm),0),
			    @todayAgentCash  = ISNULL(sum(awinlost+comm-playercomm),0),
			    @todayCustCash   = ISNULL(sum(winlost-actual_stake + playercomm ),0)
	    FROM bettrans WITH(NOLOCK)
	    WHERE mrecommend = @custid AND ruben = 1 AND bettype < 19001 
		    AND winlostdate >= convert(varchar(10), CURRENT_TIMESTAMP, 120)
    	
	    SELECT	ISNULL(Balance.masterCash,0) masterCash,
			    ISNULL(Balance.masterCash,0) - @todayMasterCash yesterday_masterCash,
			    ISNULL(Balance.masterPositionTaking,0) + ISNULL(@TransLogOTPT,0) masterPositionTaking,
			    ISNULL(Balance.agentCash,0) agentCash,
			    ISNULL(Balance.agentCash,0)- @todayAgentCash yesterday_agentCash,
			    ISNULL(Balance.customerCash,0) customerCash,
			    ISNULL(Balance.customerCash,0) - @todayCustCash yesterday_customerCash, 
			    ISNULL(Balance.customerOutstanding,0) + ISNULL(@TransLogOT,0) customerOutstanding,
			    Balance.lastTxn lastTxn,
			    @UsedCredit as masterUsedCredit,
			    ISNULL(@DisableAutoMPT,0) as DisableAutoMPT
	    FROM (	
		    SELECT	sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end) masterCash,
				    sum (case when ruben=0 then actual_stake * mpositiontaking else 0 end) masterPositionTaking, 
				    sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end) agentCash,
				    sum(case when custid <> recommend AND custid <> mrecommend AND ruben=1 then winlost-actual_stake+playercomm else 0  end) customerCash, 
				    sum(case when custid <> recommend AND custid <> mrecommend AND ruben=0 then actual_stake else 0 end) customerOutstanding, 
				    max(transdate) lastTxn
		    FROM bettrans WITH(NOLOCK) 
		    WHERE mrecommend = @custid	
				AND (
				(bettrans.bettype NOT IN (801,802,803,804,805,806)
				AND ruben =0)
				OR ruben <> 0
				)
	    )Balance 
    	
	    /*
	    @TotalBalance = 
				    ISNULL(sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end),0)
				    + ISNULL(sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end),0)
				    + ISNULL(sum(case when custid <> recommend AND custid <> mrecommend AND ruben=1 then winlost-actual_stake+playercomm else 0 end),0)

	    FROM bettrans WITH (NOLOCK, index=bettrans16)  
	    WHERE mrecommend=@CustID
	    */
    END
    else if @roleid = 4
    BEGIN

	    DECLARE @transdate DATETIME
	    SELECT @UsedCredit = sum(credit) 
	    FROM DBCUST.CustDB.dbo.custinfo WITH(NOLOCK)
	    WHERE roleid=3
		     AND srecommend = @custid
    	    	
	    SELECT @transdate = max(transdate) FROM bettrans WITH(NOLOCK) WHERE srecommend = @custid
    	
	    SELECT	@todaySuperCash = ISNULL(sum(swinlost+scomm-acomm),0),
			    @todayMasterCash = ISNULL(sum(mwinlost+acomm-comm),0),
			    @todayAgentCash = ISNULL(sum(awinlost+comm-playercomm),0),
			    @todayCustCash = ISNULL(sum(winlost-actual_stake+playercomm),0)
	    FROM bettrans WITH(NOLOCK)
	    WHERE srecommend = @custid AND ruben = 1 AND bettype < 19001 
		    AND winlostdate >= convert(varchar(10), CURRENT_TIMESTAMP, 120)		
    	
	    SELECT @TransLogOT = SUM(actual_stake),
			    @TransLogOTPT = SUM(actual_stake * spositiontaking)
	    FROM translog(NOLOCK) WHERE srecommend = @custid AND statusID = 0
    	
	    SELECT	ISNULL(Balance.superCash ,0) superCash,
			    ISNULL(Balance.superCash ,0)- @todaySuperCash yesterday_superCash,
			    ISNULL(Balance.superPositionTaking,0) + ISNULL(@TransLogOTPT,0) superPositionTaking,
			    ISNULL(Balance.masterCash,0) masterCash,
			    ISNULL(Balance.masterCash,0) - @todayMasterCash yesterday_masterCash,
			    ISNULL(Balance.agentCash,0) agentCash,
			    ISNULL(Balance.agentCash,0) - @todayAgentCash yesterday_agentCash,
			    ISNULL(Balance.customerCash,0) customerCash,
			    ISNULL(Balance.customerCash,0) - @todayCustCash yesterday_customerCash,
			    ISNULL(Balance.customerOutstanding,0) + ISNULL(@TransLogOT,0) customerOutstanding,
			    @transdate  as lastTxn,
			    @UsedCredit as superUsedCredit
    	
	    FROM (
		    SELECT	sum(case when custid=srecommend then winlost-actual_stake else swinlost+scomm-acomm end) superCash,
				    sum(case when ruben=0 then actual_stake * spositiontaking else 0 end) superPositionTaking, 
				    sum(case when custid=mrecommend then winlost-actual_stake 
											      else mwinlost+acomm-comm 
										     end)masterCash,
				    sum(case when custid=recommend  then winlost-actual_stake else awinlost+comm-playercomm end) agentCash,
				    sum(case when custid <> recommend AND custid <> mrecommend AND custid <> srecommend AND ruben=1 then winlost-actual_stake+playercomm else 0 end) customerCash, 
				    sum(case when custid <> recommend AND custid <> mrecommend AND custid <> srecommend AND ruben=0 then actual_stake else 0 end) customerOutstanding	
		     FROM bettrans WITH(NOLOCK) 
		     WHERE srecommend = @custid
				AND (
				(bettrans.bettype NOT IN (801,802,803,804,805,806)
				AND ruben =0)
				OR ruben <> 0
				)
		    )Balance 
     
    END


    SELECT  @TotalMAgentActive MAgentActive,
		    @TotalMAgentClosed MAgentClosed,
		    @TotalMAgentSuspended MAgentSuspended,
		    @TotalAgentActive AgentActive,
		    @TotalAgentClosed AgentClosed,
		    @TotalAgentSuspended AgentSuspended,
		    @TotalMemberActive MemberActive,
		    @TotalMemberClosed MemberClosed,
		    @TotalMemberSuspended MemberSuspended
END


 
 
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelAllInfo] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelAllInfo] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelAllInfo] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelAllInfo] TO [vnteam] AS [dbo]
 
GO 
 GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelAllInfo] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[Acc_CustomerSelAllInfo] TO [bodbExtAccNet]
GO 
 GRANT EXECUTE ON [dbo].[Acc_CustomerSelAllInfo] TO [bodbDownlineNet]
GO 
 GRANT EXECUTE ON [dbo].[Acc_CustomerSelAllInfo] TO [bodbAdminNet]
GO 
 
