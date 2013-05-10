-- =============================================
-- Author:		<Khoa>
-- Create date: <2009-03-01>
-- Description:	<Create Agent & Member>
-- =============================================

declare 
	@UserNameMA varchar(20), 
	@UserNameAG varchar(20), 
	@UserNameME varchar(20), 
	@CountMA int, 
	@CountAG int,
	@CountME int, 
	@srecommend int,
	@mrecommend int,
	@recommend int,
	@Counter int,
	@memberid int,
	@ErrCode int,
	@ErrMsg varchar(200)

select @UserNameMA = 'DEPT', @UserNameAG = '', @UserNameME = '', 
	@CountMA = 0, @CountAG = 0, @CountME = 0, @Counter = 0, @memberid = 0, @ErrCode = 0

declare  @TmpMaster table (username varchar(20), counter int) 
insert into @TmpMaster values ('DEPT01', 5)
insert into @TmpMaster values ('DEPT02', 10)
insert into @TmpMaster values ('DEPT03', 15)
insert into @TmpMaster values ('DEPT04', 30)
insert into @TmpMaster values ('DEPT05', 15)
insert into @TmpMaster values ('DEPT06', 15)
insert into @TmpMaster values ('DEPT07', 15)
insert into @TmpMaster values ('DEPT08', 15)
insert into @TmpMaster values ('DEPT09', 10)
insert into @TmpMaster values ('DEPT10', 5)
insert into @TmpMaster values ('DEPT11', 10)
insert into @TmpMaster values ('DEPT12', 15)
insert into @TmpMaster values ('DEPT13', 20)
insert into @TmpMaster values ('DEPT14', 5)
insert into @TmpMaster values ('DEPT15', 10)
insert into @TmpMaster values ('DEPT16', 15)
insert into @TmpMaster values ('DEPT17', 5)
insert into @TmpMaster values ('DEPT18', 15)
insert into @TmpMaster values ('DEPT19', 20)
insert into @TmpMaster values ('DEPT20', 10)
insert into @TmpMaster values ('DEPT21', 5)
insert into @TmpMaster values ('DEPT22', 10)
--select * from @TmpMaster

while(@CountMA<22)
begin
	select @CountMA = @CountMA + 1
	if(@CountMA<10)
		select @UserNameMA = @UserNameMA + '0'
	select @UserNameMA = @UserNameMA  + convert(nvarchar, @CountMA)
	--print @UserNameMA

	select 
		@srecommend  = srecommend,
		@mrecommend = mrecommend
		--@recommend = recommend
	from customer (nolock) where username = @UserNameMA

	while(@CountAG<3)
	begin
		select @CountAG = @CountAG + 1
		select @UserNameAG = @UserNameMA + '0' + convert(nvarchar, @CountAG)
		
		--print @UserNameAG

		-- create agent
		EXEC dbo.Acc_CustomerInsMember_MAg 
					@custid = @recommend OUTPUT,
					@firstname = N'-',
					@lastname = N'-',
					@creator = 8,
					@username = @UserNameAG,
					@userpwd = '8557668C74DB08BF50871657FD5581',
					@discountcs = 0.01000000,
					@v201discount = 0.00250000,
					@v151discount_31 = 0,
					@v151discount_32 = 0,
					@phone = N'-',
					@mobilephone = N'-',
					@email = N'-',
					@fax = N'-',
					@address = N'-',
					@city = N'-',
					@state = N'-',
					@country = N'-',
					@postal = N'-',
					@groupa=0.00250000,
					@groupb=0.00500000,
					@groupc=0.00750000,
					@groupd=0.01000000,
					@suspended = 0,
					@DisableHorseRacing = 1,
					@MinBet = 10,
					@MaxBet = 1000,
					@MaxPerMatch = 1000,
					@MinBetv2 = 10,
					@MaxBetv2 = 1000,
					@MaxPerMatchv2 = 1000,
					@MinBetv3 = 10,
					@MaxBetv3 = 1000,
					@MaxPerMatchv3 = 1000,
					@MinBetv5 = 10,
					@MaxBetv5 = 1000,
					@MaxPerMatchv5 = 1000,
					@MinBetv8 = 10,
					@MaxBetv8 = 1000,
					@MaxPerMatchv8 = 1000,
					@MinBetv10 = 10,
					@MaxBetv10 = 1000,
					@MaxPerMatchv10 = 1000,
					@MinBetv11 = 10,
					@MaxBetv11 = 1000,
					@MaxPerMatchv11 = 1000,
					@MinBetv201 = 10,
					@MaxBetv201 = 1000,
					@MaxPerMatchv201 = 1000,
					@MinBetv151 = 0,
					@MaxBetv151 = 0,
					@MaxPerMatchv151 = 0,
					@MinBetv99 = 10,
					@MaxBetv99 = 1000,
					@MaxPerMatchv99 = 1000,
					@credit = 300000,
					@maxcredit = 0,
					@mrecommend = @mrecommend,
					@apositiontaking_1 = 0,
					@apositiontaking_2 = 0,
					@apositiontaking_3 = 0,
					@apositiontaking_4 = 0,
					@apositiontaking_5 = 0,
					@apositiontaking_6 = 0,
					@apositiontaking_7 = 0,
					@apositiontaking_8 = 0,
					@apositiontaking_9 = 0,
					@apositiontaking_10 = 0,
					@mpositiontaking_1 = 0,
					@mpositiontaking_2 = 0,
					@mpositiontaking_3 = 0,
					@mpositiontaking_4 = 0,
					@mpositiontaking_5 = 0,
					@mpositiontaking_6 = 0,
					@mpositiontaking_7 = 0,
					@mpositiontaking_8 = 0,
					@mpositiontaking_9 = 0,
					@mpositiontaking_10 = 0,
					@alivepositiontaking_1 = 0,
					@alivepositiontaking_3 = 0,
					@alivepositiontaking_7 = 0,
					@alivepositiontaking_8 = 0,
					@mlivepositiontaking_1 = 0,
					@mlivepositiontaking_3 = 0,
					@mlivepositiontaking_7 = 0,
					@mlivepositiontaking_8 = 0,
					@v2apositiontaking_1 = 0,
					@v2apositiontaking_2 = 0,
					@v2apositiontaking_3 = 0,
					@v2apositiontaking_7 = 0,
					@v2apositiontaking_8 = 0,
					@v2apositiontaking_9 = 0,
					@v2apositiontaking_20 = 0,
					@v3apositiontaking_1 = 0,
					@v3apositiontaking_2 = 0,
					@v3apositiontaking_3 = 0,
					@v3apositiontaking_20 = 0,
					@v5apositiontaking_1 = 0,
					@v5apositiontaking_2 = 0,
					@v5apositiontaking_3 = 0,
					@v5apositiontaking_20 = 0,
					@v8apositiontaking_1 = 0,
					@v8apositiontaking_3 = 0,
					@v8apositiontaking_20 = 0,
					@v10apositiontaking_1 = 0,
					@v10apositiontaking_2 = 0,
					@v10apositiontaking_3 = 0,
					@v10apositiontaking_20 = 0,
					@v11apositiontaking_1 = 0,
					@v11apositiontaking_20 = 0,
					@v201apositiontaking_3 = 0,
					@v99apositiontaking_1 = 0,
					@v99apositiontaking_2 = 0,
					@v99apositiontaking_3 = 0,
					@v99apositiontaking_20 = 0,
					@v2mpositiontaking_1 = 0,
					@v2mpositiontaking_2 = 0,
					@v2mpositiontaking_3 = 0,
					@v2mpositiontaking_7 = 0,
					@v2mpositiontaking_8 = 0,
					@v2mpositiontaking_9 = 0,
					@v2mpositiontaking_20 = 0,
					@v3mpositiontaking_1 = 0,
					@v3mpositiontaking_2 = 0,
					@v3mpositiontaking_3 = 0,
					@v3mpositiontaking_20 = 0,
					@v5mpositiontaking_1 = 0,
					@v5mpositiontaking_2 = 0,
					@v5mpositiontaking_3 = 0,
					@v5mpositiontaking_20 = 0,
					@v8mpositiontaking_1 = 0,
					@v8mpositiontaking_3 = 0,
					@v8mpositiontaking_20 = 0,
					@v10mpositiontaking_1 = 0,
					@v10mpositiontaking_2 = 0,
					@v10mpositiontaking_3 = 0,
					@v10mpositiontaking_20 = 0,
					@v11mpositiontaking_1 = 0,
					@v11mpositiontaking_20 = 0,
					@v201mpositiontaking_3 = 0,
					@v99mpositiontaking_1 = 0,
					@v99mpositiontaking_2 = 0,
					@v99mpositiontaking_3 = 0,
					@v99mpositiontaking_20 = 0,
					@auto_mpositiontaking_1 = 0,
					@auto_mpositiontaking_2 = 0,
					@auto_mpositiontaking_3 = 0,
					@auto_mpositiontaking_4 = 0,
					@auto_mpositiontaking_5 = 0,
					@auto_mpositiontaking_6 = 0,
					@auto_mpositiontaking_7 = 0,
					@auto_mpositiontaking_8 = 0,
					@auto_mpositiontaking_9 = 0,
					@auto_mpositiontaking_10 = 0,
					@auto_mlivepositiontaking_1 = 0,
					@auto_mlivepositiontaking_3 = 0,
					@auto_mlivepositiontaking_7 = 0,
					@auto_mlivepositiontaking_8 = 0,
					@auto_v2mpositiontaking_1 = 0,
					@auto_v2mpositiontaking_2 = 0,
					@auto_v2mpositiontaking_3 = 0,
					@auto_v2mpositiontaking_7 = 0,
					@auto_v2mpositiontaking_8 = 0,
					@auto_v2mpositiontaking_9 = 0,
					@auto_v2mpositiontaking_20 = 0,
					@auto_v3mpositiontaking_1 = 0,
					@auto_v3mpositiontaking_2 = 0,
					@auto_v3mpositiontaking_3 = 0,
					@auto_v3mpositiontaking_20 = 0,
					@auto_v5mpositiontaking_1 = 0,
					@auto_v5mpositiontaking_2 = 0,
					@auto_v5mpositiontaking_3 = 0,
					@auto_v5mpositiontaking_20 = 0,
					@auto_v8mpositiontaking_1 = 0,
					@auto_v8mpositiontaking_3 = 0,
					@auto_v8mpositiontaking_20 = 0,
					@auto_v10mpositiontaking_1 = 0,
					@auto_v10mpositiontaking_2 = 0,
					@auto_v10mpositiontaking_3 = 0,
					@auto_v10mpositiontaking_20 = 0,
					@auto_v11mpositiontaking_1 = 0,
					@auto_v11mpositiontaking_20 = 0,
					@auto_v201mpositiontaking_3 = 0,
					@auto_v99mpositiontaking_1 = 0,
					@auto_v99mpositiontaking_2 = 0,
					@auto_v99mpositiontaking_3 = 0,
					@auto_v99mpositiontaking_20 = 0,
					@answer = N'-',
					@sitename = default,
					@IP = N'-',
					@Language = 'E',
					@SubAccID = 0,
					@ErrCode = @ErrCode OUTPUT,
					@ErrMsg = @ErrMsg OUTPUT
				print 'Success create Agent: ' + @UserNameAG
				print @recommend
				if @ErrCode <> 0
				begin
					select @recommend = custid from customer (nolock) where username = @UserNameAG
					select @ErrCode = 0
				end

				
				SELECT @Counter = counter FROM @TmpMaster where UserName = @UserNameMA
				
				while(@CountME < @Counter)
				begin
					select @CountME = @CountME + 1
					if(@CountME<10)
						select @UserNameME = @UserNameAG + '00'
					else
						select @UserNameME = @UserNameAG + '0'	
					select @UserNameME = @UserNameME  + convert(nvarchar, @CountME)
					--print @UserNameME

					--Insert Member					
					EXEC dbo.Acc_CustomerInsMember_Ag 
						@custid = @memberid OUTPUT,
						@firstname = N'-',
						@lastname = N'-',
						@creator = 8,
						@username = @UserNameME,
						@userpwd = '8557668C74DB08BF50871657FD5581',
						@phone = N'-',
						@fax = N'-',
						@mobilephone = N'-',
						@playerdiscount = 0.00250000,
						@playerdiscountcs = 0.01000000,
						@v201playerdiscount = 0.00250000,
						@v151playerdiscount_31 = 0,
						@v151playerdiscount_32 = 0,
						@MinBet = 10,
						@MaxBet = 1000,
						@MaxPerMatch = 1000,
						@MinBetv2 = 10,
						@MaxBetv2 = 1000,
						@MaxPerMatchv2 = 1000,
						@MinBetv3 = 10,
						@MaxBetv3 = 1000,
						@MaxPerMatchv3 = 1000,
						@MinBetv5 = 10,
						@MaxBetv5 = 1000,
						@MaxPerMatchv5 = 1000,
						@MinBetv8 = 10,
						@MaxBetv8 = 1000,
						@MaxPerMatchv8 = 1000,
						@MinBetv10 = 10,
						@MaxBetv10 = 1000,
						@MaxPerMatchv10 = 1000,
						@MinBetv11 = 10,
						@MaxBetv11 = 1000,
						@MaxPerMatchv11 = 1000,
						@MinBetv201 = 10,
						@MaxBetv201 = 1000,
						@MaxPerMatchv201 = 1000,
						@MinBetv151 = 0,
						@MaxBetv151 = 0,
						@MaxPerMatchv151 = 0,
						@MinBetv99 = 10,
						@MaxBetv99 = 1000,
						@MaxPerMatchv99 = 1000,
						@credit = 10000,
						@suspended = 0,
						@DisableHorseRacing = 1,
						@recommend = @recommend,
						@ugroup = 'a',
						@closed = 0,
						@apositiontaking_1 = 0,
						@apositiontaking_2 = 0,
						@apositiontaking_3 = 0,
						@apositiontaking_4 = 0,
						@apositiontaking_5 = 0,
						@apositiontaking_6 = 0,
						@apositiontaking_7 = 0,
						@apositiontaking_8 = 0,
						@apositiontaking_9 = 0,
						@apositiontaking_10 = 0,
						@alivepositiontaking_1 = 0,
						@alivepositiontaking_3 = 0,
						@alivepositiontaking_7 = 0,
						@alivepositiontaking_8 = 0,
						@v2apositiontaking_1 = 0,
						@v2apositiontaking_2 = 0,
						@v2apositiontaking_3 = 0,
						@v2apositiontaking_7 = 0,
						@v2apositiontaking_8 = 0,
						@v2apositiontaking_9 = 0,
						@v2apositiontaking_20 = 0,
						@v3apositiontaking_1 = 0,
						@v3apositiontaking_2 = 0,
						@v3apositiontaking_3 = 0,
						@v3apositiontaking_20 = 0,
						@v5apositiontaking_1 = 0,
						@v5apositiontaking_2 = 0,
						@v5apositiontaking_3 = 0,
						@v5apositiontaking_20 = 0,
						@v8apositiontaking_1 = 0,
						@v8apositiontaking_3 = 0,
						@v8apositiontaking_20 = 0,
						@v10apositiontaking_1 = 0,
						@v10apositiontaking_2 = 0,
						@v10apositiontaking_3 = 0,
						@v10apositiontaking_20 = 0,
						@v11apositiontaking_1 = 0,
						@v11apositiontaking_20 = 0,
						@v201apositiontaking_3 = 0,
						@v99apositiontaking_1 = 0,
						@v99apositiontaking_2 = 0,
						@v99apositiontaking_3 = 0,
						@v99apositiontaking_20 = 0,
						@answer = N'-',
						@IP = N'-',
						@success = 0 ,
						@Language = 'E',
						@SubAccID = 0,
						@ErrCode = @ErrCode OUTPUT,
						@ErrMsg = @ErrMsg OUTPUT
					print 'Success create MemberI: '
					print @memberid
				
				end
				select @UserNameME = '', @CountME = 0
				


		if(@CountMA <= 6 or @CountMA = 22) 
		begin
			print''
		end
		else
			select @CountAG = 4		
	end

	select @UserNameMA = 'DEPT', @CountAG = 0
	--print @srecommend
end