

--select * from resultDEtail 
--Where MatchID = 10655333
 
--------------------------------
---NORMAL

DECLARE @MatchID INT 
SELECT @MatchID = 10655333

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)

VALUES 
( @MatchId,
 '00' ,
  3, ----HomeValue
  2,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)

VALUES 
( @MatchId,
 '01' ,
  6, ----HomeValue
  4,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)




INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '02' ,
  3, ----HomeValue
  6,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '03' ,
  4, ----HomeValue
  6,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)



INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '04' ,
  7, ----HomeValue
  5,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)



INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '05' ,
  8, ----HomeValue
  10,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


---Set
INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0101' ,
  40, ----HomeValue
  15,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0102' ,
  40, ----HomeValue
  30,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0103' ,
  30, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0104' ,
  15, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0105' ,
  40, ----HomeValue
  15,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0106' ,
  30, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

 
INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0107' ,
  'A', ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0108' ,
  40, ----HomeValue
  15,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0109' ,
  0, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0110' ,
  'A', ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

 -------------
 
---Set '02'
INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0201' ,
  40, ----HomeValue
  30,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0202' ,
  40, ----HomeValue
  0,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0203' ,
  30, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0204' ,
  40, ----HomeValue
  15,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0205' ,
  0, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0206' ,
  30, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

 
INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0207' ,
  40, ----HomeValue
  'A',  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0208' ,
  15, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0209' ,
  0, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

---------------------
---Set 3 

--DECLARE @MatchID INT 
--SELECT @MatchID = 10655333

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0301' ,
  15, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0302' ,
  15, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0303' ,
  40, ----HomeValue
  30,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0304' ,
  40, ----HomeValue
  15,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0305' ,
  40, ----HomeValue
  30,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)



INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0306' ,
  'A', ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)




INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0307' ,
 15, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)




INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0308' ,
  0, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)




INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0309' ,
  30, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)




INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0310' ,
 40, ----HomeValue
 'A',  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

------------------------------------
------------Set 4

--DECLARE @MatchID INT 
--SELECT @MatchID = 10655333


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0401' ,
  15, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)



INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0402' ,
  40, ----HomeValue
  15,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0403' ,
  40, ----HomeValue
  30,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)



INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0404' ,
  40, ----HomeValue
  15,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)



INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0405' ,
  15, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0406' ,
  30, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0407' ,
  40, ----HomeValue
  15,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)



INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0408' ,
  30, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)



INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0409' ,
  40, ----HomeValue
  15,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)



INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0410' ,
  0, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)



INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0411' ,
  40, ----HomeValue
  30,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0412' ,
  'A', ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)
---------------------
----- Set 5

--DECLARE @MatchID INT 
--SELECT @MatchID = 10655333

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0501' ,
  30, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0502' ,
  40, ----HomeValue
  30,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0503' ,
  0, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0504' ,
  'A', ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0505' ,
  30, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)
INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0506' ,
  40, ----HomeValue
  15,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0507' ,
  40, ----HomeValue
  'A',  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0508' ,
  40, ----HomeValue
  30,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)
INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0509' ,
  0, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0510' ,
  'A', ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0511' ,
  30, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)
 

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0512' ,
  40, ----HomeValue
  15,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0513' ,
  40, ----HomeValue
  'A',  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)
INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0514' ,
  40, ----HomeValue
  15,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0515' ,
  30, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0516' ,
  40, ----HomeValue
  0,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0517' ,
  40, ----HomeValue
 'A',  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)

INSERT INTO ResultDetail
(
	MatchId,
	ResourceId,
	HomeValue,
	AwayValue,
	ResultStatusID,
	SettlementStatusID
)
VALUES 
( @MatchId,
 '0518' ,
  30, ----HomeValue
  40,  ----AwayValue
  5, ---ResultStatusID
  4 --- SettlementStatusID
)


UPDATE ResultDetail 
SET Creator = 8,
CreateDate = GETDATE (),
LastModifyUser = 8 ,
LastModifyDate = getdate()
WHERE MatchID =@MatchId

---------------------------------------------------------
---##################################################---
---- Create many data for result detail table..... ----
/* 

----Cursor insert -------------
DECLARE @Cur_MatchID INT 
DECLARE Cur CURSOR FOR
SELECT MatchId FROM Match WITH (NOLOCK) WHERE Sporttype = 5 AND MatchID NOT IN (SELECT MatchID FROM ResultDetail ) AND ....

OPEN Cur
FETCH NEXT FROM Cur
INTO @Cur_MatchID

WHILE @@FETCH_STATUS = 0 
BEGIN 
	
		INSERT INTO ResultDetail (
		MatchId,
		ResourceId,
		HomeValue,
		AwayValue,
		ResultStatusID,
		SettlementStatusID,
		Creator,
		CreateDate,
		LastModifyUser,
		LastModifyDate)

		SELECT
		@Cur_matchID AS MatchId,
		ResourceId,
		HomeValue,
		AwayValue,
		ResultStatusID,
		SettlementStatusID,
		Creator,
		CreateDate,
		LastModifyUser,
		LastModifyDate 
		FROM ResultDetail 
		WHERE MatchID = 10655333 ---@MatchId

FETCH NEXT FROM Cur
INTO @Cur_MatchId
END
CLOSE Cur
DEALLOCATE Cur

 */
 ------------------------------------------
 --##################################--

 --UPDATE r
 --SET SettlementStatusID = 1
 --FROM Match  m 
 --INNER JOIN ResultDetail r 
 --ON m.matchId = r.matchID 
 --WHERE m.betstatus like '%refund%'

 --select * from ResultDetail WHERE SettlementStatusID = 1