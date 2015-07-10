ALTER PROCEDURE [dbo].[DBA_ArchiveAccount_UpdateMove]
	@AccName varchar(50),	
	@UserID int = 360418,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS

/*
Created:  
Task : Review the SP again once executing as maybe new fields were added to customer or custinfo table
DB: DBTRANS.bodb02
Original:

Revisions:
 
Param's Explanation:
  
*/
SET NOCOUNT ON

Declare @roleid int, @AgentID int, @Now datetime, @Enabled bit

SELECT @roleid = roleid, @AgentID = custid, @Enabled = Enabled
FROM custinfo (nolock)
WHERE username = @AccName

if isnull(@AgentID,0) = 0 or @roleid NOT in (2,3,4)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'Invalid Agent User Name', @ErrCode = 101
	print @ErrMsg
	return
END

if @Enabled = 0
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent has been archived!!', @ErrCode = 101
	print @ErrMsg
	return
END


print  @AccName +':'+ 'Start:' + convert(varchar(50), getdate(), 113)

--==========================================================
--CREATING TEMP TABLES
--==========================================================

	CREATE TABLE #Member 
	(
		custid int PRIMARY KEY, recommend int, mrecommend int, srecommend int,
		membername varchar(50), agentname varchar(50), mastername varchar(50), supername varchar(50), 
		memberBalance MONEY default 0
	)
	CREATE TABLE #Agent (recommend int PRIMARY KEY, mrecommend int, srecommend int,
		agentname varchar(50), mastername varchar(50), agentBalance MONEY default 0)
	
	CREATE TABLE #Master (mrecommend int PRIMARY KEY, srecommend int,
			mastername varchar(50), supername varchar(50), masterBalance MONEY default 0)
		
	IF @roleid NOT IN (2,3,4) RETURN 0
		
	IF @roleid = 2
	BEGIN
		INSERT INTO #Member (custid, recommend, mrecommend, srecommend, 
							membername, agentname, mastername, supername)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend, 
				c.username, ag.username, mag.username, sag.username
		FROM custinfo c (nolock)
			inner join custinfo ag (nolock) on c.recommend = ag.custid
			inner join custinfo mag (nolock) on c.mrecommend = mag.custid
			inner join custinfo sag (nolock) on c.srecommend = sag.custid
		WHERE  c.recommend = @AgentID AND c.roleid = 1
		
		INSERT INTO #Agent (recommend, mrecommend, srecommend, 
						agentname, mastername)
		SELECT distinct c.recommend, c.mrecommend, c.srecommend, c.username, mag.username 
		FROM custinfo c (nolock)			
			inner join custinfo mag (nolock) on c.mrecommend = mag.custid
		WHERE  c.recommend = @AgentID AND c.roleid = 2		
		
	END
	IF @roleid = 3
	BEGIN
		INSERT INTO #Member (custid, recommend, mrecommend, srecommend,
							membername, agentname, mastername, supername)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend, 
				c.username, ag.username, mag.username, sag.username
		FROM custinfo c (nolock)
			inner join custinfo ag (nolock) on c.recommend = ag.custid
			inner join custinfo mag (nolock) on c.mrecommend = mag.custid
			inner join custinfo sag (nolock) on c.srecommend = sag.custid
		WHERE c.mrecommend = @AgentID AND c.roleid = 1
		
		INSERT INTO #Agent (recommend, mrecommend, srecommend, 
						agentname, mastername)
		SELECT distinct c.recommend, c.mrecommend, c.srecommend, c.username, mag.username 
		FROM custinfo c (nolock)			
			inner join custinfo mag (nolock) on c.mrecommend = mag.custid
		WHERE  c.mrecommend = @AgentID AND c.roleid = 2
		
		INSERT INTO #Master (mrecommend, srecommend, 
							mastername, supername)
		SELECT distinct c.mrecommend, c.srecommend, c.username, sag.username
		FROM custinfo c (nolock)			
			inner join custinfo sag (nolock) on c.srecommend = sag.custid
		WHERE  c.mrecommend = @AgentID AND c.roleid = 3
		
	END
	IF @roleid = 4
	BEGIN
		INSERT INTO #Member (custid, recommend, mrecommend, srecommend,
							membername, agentname, mastername, supername)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend,
				c.username, ag.username, mag.username, sag.username
		FROM custinfo c (nolock)
			inner join custinfo ag (nolock) on c.recommend = ag.custid
			inner join custinfo mag (nolock) on c.mrecommend = mag.custid
			inner join custinfo sag (nolock) on c.srecommend = sag.custid
		WHERE c.srecommend = @AgentID AND c.roleid = 1
		
		INSERT INTO #Agent (recommend, mrecommend, srecommend, 
						agentname, mastername)
		SELECT distinct c.recommend, c.mrecommend, c.srecommend, c.username, mag.username 
		FROM custinfo c (nolock)			
			inner join custinfo mag (nolock) on c.mrecommend = mag.custid
		WHERE  c.srecommend = @AgentID AND c.roleid = 2
		
		INSERT INTO #Master (mrecommend, srecommend, 
							mastername, supername)
		SELECT distinct c.mrecommend, c.srecommend, c.username, sag.username
		FROM custinfo c (nolock)			
			inner join custinfo sag (nolock) on c.srecommend = sag.custid
		WHERE  c.srecommend = @AgentID AND c.roleid = 3
	END
	
	
--==========================================================
--CHECK BALANCE FIRST, MAKE SURE ALL BALANCE ARE CLEARED
--==========================================================

-- CHECK MEMBER BALANCE	
	Update #Member set memberBalance = b.MemberBalance
	from #Member
		inner join (
			Select custid, isnull(SUM(isnull(case when ruben=0 then 0 else winlost-actual_stake+playercomm end, 0)), 0) as MemberBalance
			From bettrans with (NOLOCK)
			group by custid
			) b on #Member.custid = b.custid	

	--select * from #Member

	if exists(select 1 from #Member where MemberBalance > 0)
	BEGIN
		print @AccName +':'+ 'Error: Unlcleared member''s balance exist!'
		Select @ErrMsg = @AccName +':'+ 'Unlcleared member''s balance exist!', @ErrCode = 101
		return
	END	
	
	print @AccName +':'+ 'Check members balance done:' + convert(varchar(50), getdate(), 113)	
	
-------------------------------------------------------------------------------	
--CHECK SUPER BALANCE
IF @roleid = 4
BEGIN
	Declare @SuperTotalBalance money
	
	SELECT @SuperTotalBalance = 
					IsNull(sum(case when custid=srecommend then winlost-actual_stake else swinlost+scomm-acomm end),0)
					+ IsNull(sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end),0)
					+ IsNull(sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end),0)
					+ IsNull(sum(case when custid <> recommend and custid <> mrecommend and custid <> srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end),0)
	FROM bettrans WITH (NOLOCK)  
	WHERE srecommend=@AgentID
	
	if @SuperTotalBalance > 0
	BEGIN
		print @AccName +':'+ 'Error: Unlcleared SUPER''s balance exist!'
		Select @ErrMsg = @AccName +':'+ 'Unlcleared SUPER''s balance exist!', @ErrCode = 102
		return
	END	

	print @AccName +':'+ 'Check SUPER balance done:' + convert(varchar(50), getdate(), 113)
END
-------------------------------------------------------------------------------
-- CHECK AGENT BALANCE

Update #Agent set agentBalance = b.agentBalance
from #Agent
	inner join (
		Select recommend, isnull(sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end), 0)
						+ isnull(sum(case when custid<>recommend and ruben=1 then winlost-actual_stake+playercomm else 0 end), 0) as agentBalance
		From bettrans with (NOLOCK)
		group by recommend
		) b on #Agent.recommend = b.recommend


if exists(select 1 from #Agent where agentBalance > 0)
BEGIN
	print @AccName +':'+ 'Error: Unlcleared agent''s balance exist!'
	Select @ErrMsg = @AccName +':'+ 'Unlcleared agent''s balance exist!', @ErrCode = 102
	return
END	

print @AccName +':'+ 'Check agents balance done:' + convert(varchar(50), getdate(), 113)	

----------------------------------------------------------------------------

-- CHECK MASTER BALANCE	
if @RoleID >= 3
BEGIN	
	
	Update #Master set masterBalance = b.masterBalance
	from #Master
		inner join (
			Select mrecommend, isnull(sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end), 0) + 
						isnull(sum(case when custid<>mrecommend and custid <> recommend and custid<>srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end), 0) 
						+ IsNull(sum(case when custid=recommend then winlost-actual_stake else awinlost+comm-playercomm end),0)	 as masterBalance
			From bettrans with (NOLOCK)
			group by mrecommend
			) b on #Master.mrecommend = b.mrecommend	
			
	
	if exists(select 1 from #Master where masterBalance > 0)
	BEGIN
		print @AccName +':'+ 'Error: Unlcleared master''s balance exist!'
		Select @ErrMsg = @AccName +':'+ 'Unlcleared master''s balance exist!', @ErrCode = 103
		return
	END		

	print @AccName +':'+ 'Check masters balance done:' + convert(varchar(50), getdate(), 113)	
			
END
------------------------------------------------------------------------------------------------------
--return


--================================
--PERFORM DISABLING AGENCY LEVELS
--================================

update custinfo set enabled = 0 where custid IN(select recommend from #Agent)

if @roleid >= 3 
	update custinfo set enabled = 0 where custid IN(select mrecommend from #Master)
	
if @roleid = 4
BEGIN
	update custinfo set enabled = 0 where custid IN(select distinct srecommend from #Master)
	
	IF @@ROWCOUNT = 0
		update custinfo set enabled = 0 where custid = @AgentID
END


print @AccName +':'+ 'Disable agency levels done:' + convert(varchar(50), getdate(), 113)	
-------------------------------------------------------------------------------


--=============================
--PERFORM MOVING MEMBERS
--=============================

select @Now = current_timestamp

--Copy members'info to bodb_Customer before delete
insert into bodb_Customer.dbo.customer_old
	select * from customer (nolock) where custid IN (select custid from #Member)
insert into bodb_Customer.dbo.custinfo_old
	select @Now, @UserID, *  from custinfo (nolock) where custid IN (select custid from #Member)
	
--delete all related member's infomation:
delete custinfo where custid IN(select custid from #Member)
delete custsetting where custid IN(select custid from #Member)
--delete custoverride where custid IN(select custid from #Member) -- no need as members don't have custoverride
delete customer where custid IN(select custid from #Member)


print @AccName +':'+ 'Move members done:' + convert(varchar(50), getdate(), 113)	
----------------------------------------------------------------