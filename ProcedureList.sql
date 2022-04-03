use db_19vp_delivery
go

/* ___________________ APP USP ___________________ */
create function dbo.fn_check_is_account_is_active(@username varchar(50))
returns varchar(10)
as
begin	
	if exists (select role from dbo.LOGIN_INFOS as li
				where li.username=@username
					and li.status = 'ACTIVE')
		return 'True'
	return 'False'
end
go
	
create function dbo.fn_app_log_in(@username varchar(50), @password varchar(128)) returns varchar(20)
as
begin
	if exists (select role from dbo.LOGIN_INFOS as li
				where li.username=@username
					and li.password=@password
					and dbo.fn_check_is_account_is_active(@username) = 'True')
		return (select role from dbo.LOGIN_INFOS where username=@username and password=@password)
	return 'LOGIN_FAILED'
end
go

/*========================= ĐỐI TÁC USP ==================*/
select dbo.fn_app_log_in('partner1', '1')
go

-- đối tác đăng kí thông tin
create proc dbo.usp_partner_registation
	@username varchar(50),
	@password varchar(128),
	@name nvarchar(255),
	@representative_name nvarchar(255),
	@address_province_code nvarchar(20),
	@address_district_code nvarchar(20),
	@address_ward_code nvarchar(20),
	@address_line nvarchar(255),
	@branch_number int,
	@order_number int,
	@product_type nvarchar(255),
	@phone char(10),
	@mail varchar(255)
as begin
	begin try
		begin tran
		-- add to PARTNERS table
		insert into dbo.LOGIN_INFOS
			values (@username, @password, 'PARTNER', 'PENDING')

		insert into dbo.PARTNERS (username, name, representative_name, address_province_code, address_district_code, address_ward_code, address_line,branch_number,order_number,product_type,phone,mail)
			values (@username, @name, @representative_name, @address_province_code, @address_district_code, @address_ward_code, @address_line, @branch_number,@order_number,@product_type,@phone,@mail)
		-- INSERT TO PARTNER_REGISTRATIONS
		insert into dbo.PARTNER_REGISTRATIONS(username, at_datetime, status)
			values 
				(@username, GETDATE(), 'PENDING');
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- đối tác lập/gia hạn hợp đồng
create proc dbo.usp_partner_register_contract
	@CID varchar(20),
	@username varchar(50),
	@TIN varchar(20),
	@contract_time int,
	@commission float
as begin
	begin try
		begin tran
			if not exists (select c.CID from dbo.CONTRACTS as c where c.CID = @CID)
				-- create new contract
				begin
					insert into dbo.CONTRACTS(CID, extension,username, TIN, created_at, expired_at, commission, status)
					values (@CID, 0, @username ,@TIN, GETDATE(), DATEADD(MONTH, @contract_time, GETDATE()), @commission, 'PENDING')
				end
			else
				-- extend contract time 
				begin
					declare @last_expired_date datetime = (select c1.expired_at from dbo.CONTRACTS as c1 
																where c1.CID = @CID
																	and c1.extension >= all (select c2.extension from dbo.CONTRACTS as c2 where c1.CID = @CID))
					
					declare @extension int = (select c1.extension from dbo.CONTRACTS as c1 
																where c1.CID = @CID
																	and c1.extension >= all (select c2.extension from dbo.CONTRACTS as c2 where c2.CID = @CID))
					
					set @extension = @extension + 1
					declare @now date = getdate()
					declare @created_at date
					if DATEDIFF(DAY, @last_expired_date, @now) < 0
						set @created_at = @last_expired_date
					else 
						set @created_at = @now

					insert into dbo.CONTRACTS(CID, extension, username, TIN, created_at, expired_at, commission, status)
					values (@CID, @extension, @username ,@TIN, @created_at, DATEADD(MONTH, @contract_time, @created_at), @commission, 'PENDING')
				end
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- đối tác lập/gia hạn hợp đồng with time
create proc dbo.usp_partner_register_contract_with_start_time
	@CID varchar(20),
	@username varchar(50),
	@TIN varchar(20),
	@start_at date,
	@contract_time int,
	@commission float
as begin
	begin try
		begin tran
			if not exists (select c.CID from dbo.CONTRACTS as c where c.CID = @CID)
				-- create new contract
				begin
					insert into dbo.CONTRACTS(CID, extension,username, TIN, created_at, expired_at, commission, status)
					values (@CID, 0, @username ,@TIN, @start_at, DATEADD(MONTH, @contract_time, @start_at), @commission, 'PENDING')
				end
			else
				-- extend contract time 
				begin
					declare @last_expired_date datetime = (select c1.expired_at from dbo.CONTRACTS as c1 
																where c1.CID = @CID
																	and c1.extension >= all (select c2.extension from dbo.CONTRACTS as c2 where c1.CID = @CID))
					if (datediff(day, @last_expired_date, @start_at)) < 0
						throw 52000, 'Contract still not expired at `start_at` !!!', 1

					declare @extension int = (select c1.extension from dbo.CONTRACTS as c1 
																where c1.CID = @CID
																	and c1.extension >= all (select c2.extension from dbo.CONTRACTS as c2 where c2.CID = @CID))
					
					set @extension = @extension + 1

					insert into dbo.CONTRACTS(CID, extension, username, TIN, created_at, expired_at, commission, status)
					values (@CID, @extension, @username ,@TIN, @start_at, DATEADD(MONTH, @contract_time, @start_at), @commission, 'PENDING')
				end
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- đối tác xem hợp đồng hiện tại / hợp đồng đã được duyệt và chưa hết hạn
create proc dbo.usp_partner_get_accepted_contracts
	@username varchar(50)
as
begin
	select c1.*
		from dbo.CONTRACTS as c1 
		where c1.username = @username
			and c1.extension >= all (select c2.extension
									from dbo.CONTRACTS as c2
									where c2.CID = c1.CID)
			and c1.status = 'ACCEPTED'
			
end
go

-- đối tác xem hợp đồng đã hết hạn (gần nhất)
create proc dbo.usp_partner_get_expired_contracts
	@username varchar(50)
as
begin
	select c1.*
		from dbo.CONTRACTS as c1 
		where c1.extension >= all (select c2.extension
									from dbo.CONTRACTS as c2
									where c2.CID = c1.CID)
			and c1.is_expired = 1		
end
go

-- đối tác thêm chi nhánh
create proc dbo.usp_partner_add_branch
	@PBID varchar(20),
	@username varchar(50),
	@name nvarchar(255),
	@address_province_code nvarchar(20),
	@address_district_code nvarchar(20),
	@address_ward_code nvarchar(20),
	@address_line nvarchar(255)
as begin
	begin try
		begin tran
			if (select count(*) from dbo.PARTNER_BRANCHES where username = @username) < (select p.branch_number from dbo.PARTNERS as p where username = @username)
				begin
				insert into dbo.PARTNER_BRANCHES
					values
						(@PBID, @username, @name, @address_province_code, @address_district_code, @address_ward_code, @address_line, 0)
				end

			else
				throw 52000, --Error number must be between 50000 and  2147483647.
					'Cannot add more branch. Out of room', --Message
					1; --State
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- đối tác thêm sản phẩm
create proc dbo.usp_partner_add_product
	@PID varchar(20),
	@product_type varchar(255),
	@username varchar(50),
	@img_src nvarchar(255),
	@name nvarchar(255),
	@description nvarchar(255),
	@price float
as begin
	begin try
		begin tran			
			insert into dbo.PRODUCTS(PID, product_type, username, img_src, name, description, price, is_deleted)
				values (@PID, @product_type, @username, @img_src, @name, @description, @price, 0)
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- đối tác sửa thông tin sản phẩm
create proc dbo.usp_partner_update_product
	@PID varchar(20),
	@product_type nvarchar(255),
	@username varchar(50),
	@img_src nvarchar(255),
	@name nvarchar(255),
	@description nvarchar(255),
	@price float
as begin
	begin try
		begin tran
			update dbo.PRODUCTS
				set
					product_type = @product_type,
					username = @username,
					img_src = @img_src,
					name = @name,
					description = @description,
					price = @price
				where PID = @PID
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- đối tác xóa sản phẩm
create proc dbo.usp_partner_delete_product
	@PID varchar(20)
as begin
	begin try
		begin tran
			-- delete a product: we change product is_delete -> true
			update dbo.PRODUCTS
				set is_deleted = 1
			where PID = @PID

			-- xóa sản phẩm khỏi chi nhánh
			update dbo.PRODUCT_IN_BRANCHES
				set is_deleted = 1
			where PID = @PID
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- đối tác thêm sản phẩm vào chi nhánh phân phối
create proc dbo.usp_partner_add_product_to_branch
	@PBID varchar(20),
	@PID varchar(20),
	@stock int
as begin
	begin try
		begin tran
			-- check if producst existed in branch
			if exists (select * from dbo.PRODUCT_IN_BRANCHES as pib where pib.PID = @PID and pib.PBID = @PBID and pib.is_deleted = 0)
				begin
					declare @curr_stock int = (select pib.stock from dbo.PRODUCT_IN_BRANCHES as pib where pib.PID = @PID and pib.PBID = @PBID and pib.is_deleted = 0)

					update dbo.PRODUCT_IN_BRANCHES
						set stock = @curr_stock + @stock
						where PBID = @PBID and PID = @PID
				end
			else 
				begin
					if exists (select * from dbo.PRODUCT_IN_BRANCHES as pib where pib.PID = @PID and pib.PBID = @PBID and pib.is_deleted = 1)
						and exists (select * from dbo.PRODUCTS as p where p.PID = @PID and p.is_deleted = 0)
						begin							
							update dbo.PRODUCT_IN_BRANCHES
								set stock = @stock,
								is_deleted = 0
								where PBID = @PBID and PID = @PID
						end
					else
						begin
							insert into dbo.PRODUCT_IN_BRANCHES (PBID,PID, stock, is_deleted)
							values (@PBID, @PID, @stock, 0)
						end
				end			
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- đối tác xóa sản phẩm khỏi chi nhánh phân phối
create proc dbo.usp_partner_delete_product_from_branch
	@PBID varchar(20),
	@PID varchar(20)
as begin
	begin try
		begin tran
			delete dbo.PRODUCT_IN_BRANCHES
				where PBID = @PBID and PID = @PID
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- đối tác xem đơn hàng của mình
create proc dbo.usp_partner_get_orders
	@partner_username varchar(50)
as begins
	select o.*, p.username 
		from dbo.ORDERS as o
			join dbo.PARTNERS as p on p.username = o.partner_username
		where p.username = @partner_username
end
go

-- đối tác/tài xế cập nhật tình trạng vận chuyển đơn hàng
create proc dbo.usp_partner_or_driver_update_delivery_status
	@order_id varchar(20),
	@new_delivery_status varchar(20)
as begin
	begin try
		begin tran
			if not exists (select * from dbo.ORDERS as o where o.order_id = @order_id)
				throw 52000, 'Invalid order_id', 1
			update dbo.ORDERS
				set delivery_status = @new_delivery_status
				where order_id = order_id
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

/* ___________________ KHÁCH HÀNG USP ___________________ */
go

-- Đăng kí thành viên
create proc dbo.usp_customer_registration
	@username varchar(50),
	@password varchar(512),
	@name nvarchar(50),
	@address_province_code nvarchar(20),
	@address_district_code nvarchar(20),
	@address_ward_code nvarchar(20),
	@address_line nvarchar(255),
	@phone char(10),
	@mail varchar(50)
as begin
	insert into dbo.LOGIN_INFOS
		values (@username, @password, 'CUSTOMER', 'ACTIVE')
	insert into dbo.CUSTOMERS(username, name, address_province_code, address_district_code, address_ward_code, address_line, phone,mail)
	values 
		(@username, @name, @address_province_code, @address_district_code, @address_ward_code, @address_line, @phone, @mail)
end
go

-- KHÁCH HÀNG ĐẶT HÀNG
go

-- Khách hàng tạo đơn hàng
create proc dbo.usp_customer_create_order
	@order_id varchar(20),
	@partner_username varchar(50),
	@customer_username varchar(50),
	@payment_method varchar(20) -- CASH, MOMO, ZALOPAY
as begin
	begin try
		begin tran
			insert into dbo.ORDERS(order_id, partner_username, customer_username, payment_method, delivery_status, paid_status, shipping_fee)
				values (@order_id, @partner_username, @customer_username, @payment_method, 'PENDING', 'UNPAID', 10)
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- Thêm sản phẩm vào đơn hàng
create proc dbo.usp_customer_add_product_to_order
	@order_id varchar(20),
	@PID varchar(20),
	@PBID varchar(20),
	@quantity int
as begin
	begin try
		begin tran
			-- kiểm tra số lượng có > 0
			if @quantity <= 0
				throw 52000, --Error number must be between 50000 and  2147483647.
					'Quantity <= 0 : NOT VALID', --Message
					1; --State

			-- kiểm tra sản phầm có tồn tại trong branch/stock > 0 không
			if not exists (select stock from dbo.PRODUCT_IN_BRANCHES as pib where pib.PID = @PID and pib.PBID = @PBID) 
				or (select stock from dbo.PRODUCT_IN_BRANCHES as pib where pib.PID = @PID and pib.PBID = @PBID) = 0

				throw 52000, --Error number must be between 50000 and  2147483647.
					'Product not in branch or out of stock', --Message
					1; --State

			-- thêm sản phẩm vào ORDER_DETAILS

			---- Kiểm tra sản phẩm đã tồn tại hay chưa, nếu không tạo mới, nếu có, tăng thêm số lượng
			if not exists (select * from dbo.ORDERS_DETAILS as od where od.order_id = @order_id and od.PID = @PID)
				begin
					insert into dbo.ORDERS_DETAILS (order_id, PID, PBID, quantity)
						values (@order_id, @PID, @PBID,  @quantity)
				end
			else
				begin
					declare @curr_quantity int = (select quantity from dbo.ORDERS_DETAILS as od where od.order_id = @order_id and od.PID = @PID)
					
					update dbo.ORDERS_DETAILS
						set 
							quantity = @curr_quantity + @quantity
						where order_id = @order_id and PID = @PID
				end

			-- giảm số lượng sản phẩm trong chi nhánh đi `quantity`
			declare @curr_stock int = (select pib.stock
											from dbo.PRODUCT_IN_BRANCHES as pib									
											where pib.PID = @PID and pib.PBID = @PBID)
			declare @new_stock int = @curr_stock - @quantity
			update dbo.PRODUCT_IN_BRANCHES
				set stock = @new_stock
				where PID = @PID and PBID = @PBID
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- Bớt sản phẩm ra khỏi đơn hàng
create proc dbo.usp_customer_remove_product_to_order
	@order_id varchar(20),
	@PID varchar(20),
	@PBID varchar(20),
	@quantity int
as begin
	begin try
		begin tran
			-- kiểm tra số lượng có > 0
			if @quantity <= 0
				throw 52000, --Error number must be between 50000 and  2147483647.
					'Quantity <= 0 : NOT VALID', --Message
					1; --State

			-- kiểm tra sản phầm có tồn tại trong branch không
			if not exists (select stock from dbo.PRODUCT_IN_BRANCHES as pib where pib.PID = @PID and pib.PBID = @PBID) 
				or (select stock from dbo.PRODUCT_IN_BRANCHES as pib where pib.PID = @PID and pib.PBID = @PBID) = 0

				throw 52000, --Error number must be between 50000 and  2147483647.
					'Product not in branch', --Message
					1; --State

			-- bớt sản phẩm khỏi ORDER_DETAILS

			---- Kiểm tra sản phẩm đã tồn tại hay chưa, nếu không báo lỗi, nếu có giảm số lượng
			if not exists (select * from dbo.ORDERS_DETAILS as od where od.order_id = @order_id and od.PID = @PID)
				throw 52000, --Error number must be between 50000 and  2147483647.
					'Product not in ORDER_DETAILS', --Message
					1; --State
			else
				begin
					declare @curr_quantity int = (select quantity from dbo.ORDERS_DETAILS as od where od.order_id = @order_id and od.PID = @PID)
					
					update dbo.ORDERS_DETAILS
						set 
							quantity = @curr_quantity - @quantity
						where order_id = @order_id and PID = @PID
				end

			-- tăng số lượng sản phẩm trong chi nhánh đi `quantity`
			declare @curr_stock int = (select pib.stock
											from dbo.PRODUCT_IN_BRANCHES as pib									
											where pib.PID = @PID and pib.PBID = @PBID)

			declare @new_stock int = @curr_stock + @quantity
			update dbo.PRODUCT_IN_BRANCHES
				set stock = @new_stock
				where PID = @PID and PBID = @PBID
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- khách hàng thanh toán đơn hàng
create proc dbo.usp_customer_pay_order
	@order_id varchar(20)
as begin
	begin try
		begin tran
			if (select paid_status from ORDERS where order_id=@order_id) = 'UNPAID'
				begin
					update ORDERS
						set paid_status='PAID'
				end
			else
				throw 52000, --Error number must be between 50000 and  2147483647.
				'You have already paid this order', --Message
				1; --State
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go
	
/* ___________________ TÀI XẾ USP ___________________ */

-- Tài xế đăng kí tài khoản
create proc dbo.usp_driver_registration
	@username varchar(50),
	@password varchar(128),
	@name nvarchar(50),
	@NIN char(12),
	@address_province_code nvarchar(20),
	@address_district_code nvarchar(20),
	@address_ward_code nvarchar(20),
	@address_line nvarchar(255),
	@active_area_district_code nvarchar(20),
	@mail varchar(50),
	@BID varchar(20),
	@bank_name nvarchar(255),
	@bank_branch nvarchar(255),
	@VIN char(17)
as begin
	begin try
		begin tran
			-- tạo record ngân hàng
			insert into dbo.BANKS(BID, name, branch)
				values
					(@BID, @bank_name, @bank_branch)
			
			-- insert into LOGIN_INFOS
			insert into dbo.LOGIN_INFOS
				values (@username, @password, 'DRIVER', 'PENDING')

			-- insert into DRIVERS
			insert into dbo.DRIVERS(username, name, NIN, address_province_code, address_district_code, address_ward_code, address_line, active_area_district_code, mail, BID)
			values 
				(@username, @name, @NIN, @address_province_code, @address_district_code, @address_ward_code, @address_line, @active_area_district_code, @mail, @BID)
		
			-- insert into DRIVER_REGISTRATIONS
			insert into dbo.DRIVER_REGISTRATIONS (username, VIN, fee, registration_status, paid_fee_status)
				values (@username, @VIN, 100, 'PENDING', 'UNPAID')
			commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- Tài xế ~ đơn hàng trong khu vực đăng kí
create proc dbo.usp_driver_get_orders_in_active_area
	@username varchar(50)
as
begin
	select o.*, w.full_name, dt.full_name, pv.full_name
		from dbo.ORDERS as o
			join dbo.CUSTOMERS as c on o.customer_username = c.username
			join dbo.DRIVERS as d on c.address_district_code = d.active_area_district_code
			join dbo.PROVINCES as pv on c.address_province_code = pv.code
			join dbo.DISTRICTS as dt on c.address_district_code = dt.code
			join dbo.WARDS as w on c.address_ward_code = w.code
		where o.delivery_status = 'PENDING' and d.username = @username
end
go

-- Tài xế tiếp nhận đơn hàng
create proc dbo.usp_driver_receive_order
	@username varchar(50),
	@order_id varchar(20)
as begin
	begin try
		begin tran
			-- check đơn hàng có đang ở trạng thái `PENDING` hoặc not exists?
			if (select o.delivery_status from dbo.ORDERS as o where o.order_id = @order_id) != 'PENDING'
				or not exists (select * from dbo.ORDERS as o where o.order_id = @order_id)
				throw 52000, --Error number must be between 50000 and  2147483647.
					'Order status is not PENDING ', --Message
					1; --State

			-- check đơn hàng có phải khu vực `ACTIVE` của tài xế ?
			if (select c.address_district_code from dbo.ORDERS as o join dbo.CUSTOMERS as c on o.customer_username = c.username where o.order_id = @order_id)
				!= (select d.active_area_district_code from dbo.DRIVERS as d where d.username = @username)
				throw 52000, 'ORDER not in driver active area. Cannot receive', 1

			-- update order delivery_status to DELIVERING
			begin
				update dbo.ORDERS
					set delivery_status = 'DELIVERING'
					where order_id=@order_id
			end

			-- insert new record to driver history
			begin
				insert into dbo.DRIVER_HISTORIES
					values
						(@order_id, @username, 20)
			end
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- Tài xế theo dõi thu nhập
create proc dbo.usp_driver_history_incomes
	@username varchar(50)
as 
begin
	select dh.order_id, dh.income, w.full_name, dt.full_name, pv.full_name
		from dbo.DRIVER_HISTORIES as dh 
			join dbo.ORDERS as o on dh.order_id = o.order_id 
			join dbo.CUSTOMERS as c on o.customer_username = c.username
			join dbo.PROVINCES as pv on c.address_province_code = pv.code
			join dbo.DISTRICTS as dt on c.address_district_code = dt.code
			join dbo.WARDS as w on c.address_ward_code = w.code
		where dh.driver_username = @username
end
go

/* ___________________ NHÂN VIÊN USP ___________________ */

-- Nhân viên xem danh sách hợp đồng của đối tác
create proc dbo.usp_employee_get_contracts
	@contract_status varchar(20)
as begin
	begin try
		begin tran
			select * from dbo.CONTRACTS as c
				where c.status=@contract_status
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- Nhân viên duyệt tất cả hợp đồng -> trả về số lượng hợp đồng đã duyệt
create proc dbo.usp_employee_accept_all_contracts
@number_contracts_accepted int output
as begin
	begin try
		begin tran
			-- lần duyệt bảng thứ nhất
			set @number_contracts_accepted = (select count(*) from dbo.CONTRACTS
						where status = 'PENDING' and is_expired = 0)
			-- [TODO] A transaction to add a new contract, true output: (@number_contracts_accepted + 1)
			print 'start waiting'
			waitfor delay '00:00:05'
			print 'waited'
			update dbo.CONTRACTS
				set status = 'ACCEPTED'
				where status = 'PENDING' and is_expired = 0 -- lần duyệt bảng thứ 2
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch

	-- RETURN CONTRACT LISTS
	select * from dbo.CONTRACTS
end
go
 
-- Nhân viên duyệt 1 hợp đồng
create proc dbo.usp_employee_accept_contract
	@CID varchar(20)
as begin
	begin try
		begin tran
			-- todo
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
    select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
    raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
	if (@@TRANCOUNT > 0)
		rollback tran
	end catch
end
go

-- Nhân viên duyệt đăng kí tài khoảng 1 partner
create proc dbo.usp_employee_active_partner_account
	@partner_username varchar(50)
as begin
	begin try
		begin tran
			-- check if valid partner's username
			if not exists (select * 
						from dbo.LOGIN_INFOS as li
							join dbo.PARTNERS as p on li.username = p.username
							join dbo.PARTNER_REGISTRATIONS as pr on li.username = pr.username
						where li.username = @partner_username 
							and pr.status = 'PENDING' 
							and li.status = 'PENDING' 
							and li.role = 'PARTNER')
				throw 52000, 'Invalid username !!!', 1
			else 
				begin
					-- approve partner registration
					update dbo.PARTNER_REGISTRATIONS
						set status = 'ACCEPTED'
						where username = @partner_username
					
					-- change LOGIN_INFOS status from `PENDING` to `ACTIVE`
					update dbo.LOGIN_INFOS
						set status = 'ACTIVE'
						where username = @partner_username
				end
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
    select 
        @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
    raiserror (
        @ErrorMessage, @ErrorSeverity, @ErrorState);
	if (@@TRANCOUNT > 0)
		rollback tran
	end catch
end
go

-- Nhân viên kích hoạt 1 tài khoảng tài xế
create proc dbo.usp_employee_active_driver_account
	@driver_username varchar(50)
as begin
	begin try
		begin tran
			-- check if valid partner's username
			if not exists (select * 
						from dbo.LOGIN_INFOS as li
							join dbo.DRIVERS as p on li.username = p.username
							join dbo.DRIVER_REGISTRATIONS as dr on li.username = dr.username
						where li.username = @driver_username 
							and dr.registration_status = 'PENDING'
							and li.status = 'PENDING' 
							and li.role = 'DRIVER')
				throw 52000, 'Invalid username !!!', 1
			else 
				begin
					-- approve partner registration
					update dbo.DRIVER_REGISTRATIONS
						set registration_status = 'ACCEPTED'
						where username = @driver_username
					
					-- change LOGIN_INFOS status from `PENDING` to `ACTIVE`
					update dbo.LOGIN_INFOS
						set status = 'ACTIVE'
						where username = @driver_username
				end
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
    select 
        @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
    raiserror (
        @ErrorMessage, @ErrorSeverity, @ErrorState);
	if (@@TRANCOUNT > 0)
		rollback tran
	end catch
end
go

-- Nhân viên kích hoạt toàn bộ tài khoảng tài xế, trả về số lượng
create proc dbo.usp_employee_active_all_driver_accounts
	@number_of_driver_account int output
as begin
	begin try
		begin tran
			-- check if valid partner's username
			if not exists (select * 
						from dbo.LOGIN_INFOS as li
							join dbo.DRIVERS as d on li.username = d.username
							join dbo.DRIVER_REGISTRATIONS as dr on li.username = dr.username
						where dr.registration_status = 'PENDING'
							and li.status = 'PENDING' 
							and li.role = 'DRIVER')
				throw 52000, 'Not exist Driver registration to accept', 1
			else 
				begin
					set @number_of_driver_account = (select COUNT (*) 
						from dbo.LOGIN_INFOS as li
							join dbo.DRIVERS as d on li.username = d.username
							join dbo.DRIVER_REGISTRATIONS as dr on li.username = dr.username
						where dr.registration_status = 'PENDING'
							and li.status = 'PENDING' 
							and li.role = 'DRIVER')

					-- [todo] A transaction to add new driver registration

					-- approve partner registration
					update dbo.DRIVER_REGISTRATIONS
						set registration_status = 'ACCEPTED'
					
					-- change LOGIN_INFOS status from `PENDING` to `ACTIVE`
					update dbo.LOGIN_INFOS
						set status = 'ACTIVE'
				end
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
    select 
        @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
    raiserror (
        @ErrorMessage, @ErrorSeverity, @ErrorState);
	if (@@TRANCOUNT > 0)
		rollback tran
	end catch
end
go

/* ___________________ QUẢN TRỊ USP ___________________ */
go

/* ----- quản trị người dùng ----- */

-- Admin thêm tài khoản Admin
create proc dbo.usp_admin_add_admin_account
	@username varchar(50),
	@password varchar(128),
	@name nvarchar(255)
as begin
	begin try
		begin tran
			insert into dbo.LOGIN_INFOS 
				values (@username, @password, 'ADMIN', 'ACTIVE')
			insert into dbo.ADMINS
				values (@username, @name)
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
    select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
    raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
	if (@@TRANCOUNT > 0)
		rollback tran
	end catch
end
go

-- Admin xóa tài khoảng admin
create proc dbo.usp_admin_delete_admin_account
	@username_to_delete varchar(50)
as begin
	begin try
		begin tran
			-- check if that account is exist and is an admin account
			if exists (	select * from dbo.LOGIN_INFOS as li
							join dbo.ADMINS as a on li.username = a.username
							where li.username = @username_to_delete and li.role = 'ADMIN')
				begin
					-- delete record in ADMINS
					delete dbo.ADMINS
						where username = @username_to_delete

					-- delete record in LOGIN_INFOS
					delete dbo.LOGIN_INFOS
						where username = @username_to_delete			
				end
			else 
				throw 52000, 'Invalid username. Cannot delete admin', 1
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- Admin thêm tài khoản nhân viên
create proc dbo.usp_admin_add_employee_account
	@username varchar(50),
	@password varchar(512),
	@name nvarchar(50),
	@mail varchar(50)
as begin
	begin try
		begin tran
			insert into dbo.LOGIN_INFOS 
				values (@username, @password, 'EMPLOYEE', 'ACTIVE')
			insert into dbo.EMPLOYEES
				values (@username, @name, @mail)
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
    select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
    raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
	if (@@TRANCOUNT > 0)
		rollback tran
	end catch
end
go

-- Admin xóa tài khoảng nhân viên
create proc dbo.usp_admin_delete_employee_account
	@username_to_delete varchar(50)
as begin
	begin try
		begin tran
			-- check if that account is exist and is an Employee account
			if exists (	select * from dbo.LOGIN_INFOS as li
							join dbo.EMPLOYEES as a on li.username = a.username
							where li.username = @username_to_delete and li.role = 'EMPLOYEE')
				begin
					-- delete record in ADMINS
					delete dbo.EMPLOYEES
						where username = @username_to_delete

					-- delete record in LOGIN_INFOS
					delete dbo.LOGIN_INFOS
						where username = @username_to_delete			
				end
			else 
				throw 52000, 'Invalid username. Cannot delete admin', 1
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
		if (@@TRANCOUNT > 0)
			rollback tran
	end catch
end
go

-- ADMIN khóa/kích hoạt tài khoản
create proc dbo.usp_admin_change_account_status
	@username_to_change varchar(50),
	@new_status varchar(20)
as begin
	begin try
		begin tran
			-- Kiểm tra tài khoảng có tồn tại hay không
			if exists (select * from dbo.LOGIN_INFOS as li where li.username = @username_to_change)
				update dbo.LOGIN_INFOS
					set status = @new_status
					where username = @username_to_change
			else
				throw 52000, 'Invalid username !!!', 1
		commit tran
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
    select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
    raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
	if (@@TRANCOUNT > 0)
		rollback tran
	end catch
end
go