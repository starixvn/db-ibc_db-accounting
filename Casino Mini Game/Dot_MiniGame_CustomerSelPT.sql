 ALTER Procedure [dbo].[Dot_MiniGame_CustomerSelPT]
	@IBCCustid int
AS
/*
Created: 20100416
Task : Select customer PT
DB: DB052.bodb02

Revisions:
	- 20100416@Daniel: Added

Param's Explanation:
• @IBCCustid: custid of the account whose settings you want to select


*/

Declare @RoleID int, @CustID int

SELECT @RoleID=	roleid FROM Customer with (nolock) WHERE custid = @IBCCustID

IF @RoleID=4
	SELECT 
		cs.spositiontaking SuperMaxPT,
		co.minpositiontaking SuperMinPT,
		0.0025 SuperComm	
	FROM custsetting cs with (nolock) 
		INNER JOIN custoverride co with (nolock) ON cs.custid = co.custid AND cs.sporttype = co.sporttype AND cs.bettype = co.bettype
	WHERE 
		cs.sporttype = 1
		AND cs.bettype = 1
		AND cs.custID = @IBCCustID 
		
	
ELSE IF @RoleID=3
	SELECT 
		cs.spositiontaking SuperPresetPT,
		cs.isautopositiontaking IsAutoSuperPT,
		cs.autopositiontaking AutoSuperPT,
		cs.mpositiontaking MasterMaxPT,
		co.minpositiontaking MasterMinPT,
		0 MasterComm
	FROM custsetting cs with (nolock) 
		INNER JOIN custoverride co with (nolock) ON cs.custid = co.custid AND cs.sporttype = co.sporttype AND cs.bettype = co.bettype
	WHERE 
		cs.sporttype = 1
		AND cs.bettype = 1
		AND cs.custID = @IBCCustID 
	
ELSE IF @RoleID=2
	SELECT 
		case when acs.isautompositiontaking = 1 then
			case when
				case when acs.autompositiontaking < mcs.mpositiontaking - acs.apositiontaking then acs.autompositiontaking 
				else mcs.mpositiontaking - acs.apositiontaking end < co.maxpositiontaking
				then 
					case when acs.autompositiontaking < mcs.mpositiontaking - acs.apositiontaking then acs.autompositiontaking 
					else mcs.mpositiontaking - acs.apositiontaking end
			else co.maxpositiontaking end
		else acs.mpositiontaking end MasterPresetPT, --if i2=1: m2 = min(u2, m3-a2, l2)
		acs.apositiontaking AgentMaxPT,
		co.minpositiontaking AgentMinPT,
		0 AgentComm
	FROM custsetting acs with (nolock) 
		INNER JOIN custinfo aci with (nolock) ON acs.custid = aci.custid
		INNER JOIN custsetting mcs with (nolock) ON aci.mrecommend = mcs.custid AND acs.sporttype = mcs.sporttype AND acs.bettype = mcs.bettype
		INNER JOIN custoverride co with (nolock) ON acs.custid = co.custid AND acs.sporttype = co.sporttype AND acs.bettype = co.bettype
	WHERE 
		acs.sporttype = 1
		AND acs.bettype = 1
		AND acs.custID = @IBCCustID 
ELSE
	SELECT 
		cs.spositiontaking SuperPT,
		cs.isautopositiontaking IsAutoSuperPT,
		cs.autopositiontaking AutoSuperPT,		
		cs.mpositiontaking MasterPT,
		cs.apositiontaking AgenPT
	FROM custsetting cs with (nolock) 
	WHERE 
		cs.sporttype = 1
		AND cs.bettype = 1
		AND cs.custID = @IBCCustID 


	
GO
GRANT EXECUTE ON [dbo].[Dot_MiniGame_CustomerSelPT] TO [Dot_Casino]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_MiniGame_CustomerSelPT] TO [vnTeam]