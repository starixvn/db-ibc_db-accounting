
alter PROCEDURE [Acc_ExecRep_09]
(
	@roleid INT
)
AS
BEGIN

	IF (SELECT COUNT('') FROM sys.objects WHERE name IN ('custinfo','custsetting3rd') AND type = 'U') = 2
	BEGIN

		WHILE 1 = 1 
		BEGIN
			UPDATE TOP(20000) cs1 WITH(ROWLOCK,UPDLOCK)
			SET cs1.spositiontaking = cs2.spositiontaking,
				cs1.mpositiontaking = cs2.mpositiontaking,
				cs1.apositiontaking = cs2.apositiontaking,
				cs1.autopositiontaking = cs2.autopositiontaking,
				cs1.autompositiontaking = cs2.autompositiontaking,
				cs1.isautopositiontaking = cs2.isautopositiontaking,
				cs1.isautompositiontaking = cs2.isautompositiontaking,
				cs1.sdiscount = cs2.sdiscount ,
				cs1.adiscount = cs2.adiscount,
				cs1.discount = cs2.discount,
				cs1.playerdiscount= cs2.playerdiscount
			FROM CustSetting3rd cs1 
				INNER JOIN CustSetting3rd cs2 WITH (NOLOCK) ON cs1.custid =cs2.custid AND cs1.bettype = cs2.bettype
				INNER JOIN custInfo ci WITH(NOLOCK) ON ci.custid = cs1.custid
			WHERE cs1.sporttype = 152 and cs2.sporttype = 151 
			  AND( cs1.bettype = 41 AND cs2.bettype = 41
			   OR cs1.bettype = 42 AND cs2.bettype = 42)
			  and
				( cs1.spositiontaking <> cs2.spositiontaking
				   OR cs1.mpositiontaking <> cs2.mpositiontaking
				   OR cs1.apositiontaking <> cs2.apositiontaking
				   OR cs1.autopositiontaking <> cs2.autopositiontaking
				   OR cs1.autompositiontaking <> cs2.autompositiontaking
				   OR cs1.isautopositiontaking <> cs2.isautopositiontaking
				   OR cs1.isautompositiontaking <> cs2.isautompositiontaking
				   OR cs1.sdiscount <> cs2.sdiscount 
					OR cs1.adiscount <> cs2.adiscount
					OR cs1.discount <> cs2.discount
					OR cs1.playerdiscount <> cs2.playerdiscount
				)
			AND roleid = @roleid
			
			IF @@ROWCOUNT <> 20000
				BREAK
		END
	END
END