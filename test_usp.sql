use db_19vp_delivery
go

-- exec as user = '_app'

-- test đăng nhập
select dbo.fn_app_log_in('phatnm.partner1', 'pn12345') as role
go

revert
go

-- EXECUTE AS USER = '_partner';
-- test đối tác đăng kí thông tin
go

exec dbo.usp_partner_registation
	@username = 'phatnm.partner1',
	@password = 'pn12345',
	@name = N'Phát Partner1',
	@representative_name = N'Ngô Minh Phát1',
	@address_province_code = N'01',
	@address_district_code = N'001',
	@address_ward_code = N'00001',
	@address_line = N'123 nhà vàng',
	@branch_number = 2,
	@order_number = 100,
	@product_type = 'FOOD',
	@phone = '0704921213',
	@mail = 'nmphat.partner3@mail.com';
go

-- test đăng nhập
select dbo.fn_app_log_in('phatnm.partner1', 'pn12345')
go

select * from dbo.LOGIN_INFOS
go

-- test đối tác lập hợp đồng
exec dbo.usp_partner_register_contract
	@CID = 'CID003',
	@username = 'phatnm.partner1',
	@TIN = '01234567890123456789',
	@contract_time = 6,
	@commission = 0.7
go

exec dbo.usp_partner_create_contract_with_start_time
	@CID = 'CID007',
	@username = 'phatnm.partner1',
	@TIN = '01234567890123456789',
	@start_at = '2024-09-11',
	@contract_time = 6,
	@commission = 0.7
go

---- Xem toàn bộ các hợp đồng đã lập
select c.* from dbo.CONTRACTS as c
	order by c.extension desc

-- đối tác xem hợp đồng hiện tại / accepted
exec dbo.usp_partner_get_accepted_contracts 'phatnm.partner1'
go

-- đối tác xem hợp đồng hết hạn MÀ CHƯA ĐƯỢC GIA HẠN
exec dbo.usp_partner_get_expired_contracts 'phatnm.partner1'
go

-- test đối tác thêm chi nhánh
--@PBID varchar(20),
--@username varchar(50),
--@name nvarchar(255),
--@address_province_code nvarchar(20),
--@address_district_code nvarchar(20),
--@address_ward_code nvarchar(20),
--@address_line nvarchar(255)
exec dbo.usp_partner_add_branch
	@PBID = 'PBID001',
	@username = 'phatnm.partner1',
	@name = N'PN3 - chi nhánh 3',
	@address_province_code = N'01',
	@address_district_code = N'001',
	@address_ward_code = N'00001',
	@address_line = N'123 nhà vàng 3'
go

exec dbo.usp_partner_add_branch
	@PBID = 'PBID002',
	@username = 'phatnm.partner1',
	@name = N'PN2 - chi nhánh 2',
	@address_province_code = N'01',
	@address_district_code = N'001',
	@address_ward_code = N'00019',
	@address_line = N'123 nhà vàng 00019'
go

exec dbo.usp_partner_add_branch
	@PBID = 'PBID003',
	@username = 'phatnm.partner1',
	@name = N'PN1 - chi nhánh 3',
	@address_province_code = N'01',
	@address_district_code = N'002',
	@address_ward_code = N'00040',
	@address_line = N'123 nhà vàng 00040'
go

select * from dbo.PARTNER_BRANCHES
go

-- test đối tác thêm sản phẩm
exec dbo.usp_partner_add_product 'PID001', 'FOOD', 'phatnm.partner1', 'img_src', N'Bánh oishi', N'Bánh oishi cay nồng', 5
exec dbo.usp_partner_add_product 'PID003', 'FOOD', 'phatnm.partner1', 'img_src', N'Bánh bông lan', N'Bánh bông lan nhân trứng muối', 5
go

-- test đối tác thêm sản phẩm vào chi nhánh phân phối
exec dbo.usp_partner_add_product_to_branch
	@PID = 'PID001',
	@PBID = 'PBID001',
	@stock = 100
go

exec dbo.usp_partner_add_product_to_branch
	@PID = 'PID003',
	@PBID = 'PBID001',
	@stock = 20
go

exec dbo.usp_partner_add_product_to_branch
	@PID = 'PID001',
	@PBID = 'PBID002',
	@stock = 77
go

exec dbo.usp_partner_add_product_to_branch
	@PID = 'PID003',
	@PBID = 'PBID002',
	@stock = 100
go

-- đối tác sửa thông tin sản phẩm
exec dbo.usp_partner_update_product 'PID001', 'FOOD', 'phatnm.partner1', 'img_src', N'Bánh oishi ngon ngon', N'Bánh oishi cay nồng', 6
go

-- đối tác xóa sản phẩm
--exec dbo.usp_partner_delete_product 'PID001'
--go

revert
go

-- exec as user = '_customer'
-- test khách hàng đăng kí
exec dbo.usp_customer_registration
	@username = 'phatnm.customer2',
	@password = 'cus12345',
	@name = N'Phát Partner1',
	@address_province_code = N'87',
	@address_district_code = N'876',
	@address_ward_code = N'30211',
	@address_line = N'319A, ấp Tân Lộc A',
	@phone = '0704921215',
	@mail = 'nmphat.partner3@mail.com';
go

-- test khách hàng tạo đơn hàng
/*
	@order_id varchar(20),
	@partner_username varchar(50),
	@customer_username varchar(50),
	@payment_method varchar(20) -- CASH, MOMO, ZALOPAY
*/
exec dbo.usp_customer_create_order 'ORDER001', 'phatnm.partner1', 'phatnm.customer2', 'CASH'
go

revert
go

-- test KHÁCH HÀNG Thêm/bớt sản phẩm ~ đơn hàng
exec dbo.usp_customer_add_product_to_order 'ORDER001', 'PID001', 'PBID001', 10
go
exec dbo.usp_customer_remove_product_to_order 'ORDER001', 'PID001', 'PBID001', 2
go 

-- khách hàng thanh toán đơn hàng 
exec dbo.usp_customer_pay_order 'ORDER001'
go

-- exec as user = '_driver'
go

-- Test tài xế đăng kí tài khoản
---- Tài xế 1
exec dbo.usp_driver_registration
	@username = 'phatnm.driver1',
	@password = 'dri12345',
	@name = N'Phát driver1',
	@NIN = '0000000000001',
	@address_province_code = N'87',
	@address_district_code = N'876',
	@address_ward_code = N'30211',
	@address_line = N'319A, ấp Tân Lộc A',
	@active_area_district_code = N'876',
	@mail = 'nmphat.partner3@mail.com',
	@BID = 'BID001',
	@bank_name = N'Ngân hàng agribank',
	@bank_branch = N'Quận 7'
go

---- Tài xế 2
exec dbo.usp_driver_registration
	@username = 'phatnm.driver2',
	@password = 'dri12345',
	@name = N'Phát driver1',
	@NIN = '0000000000002',
	@address_province_code = N'87',
	@address_district_code = N'876',
	@address_ward_code = N'30211',
	@address_line = N'319A, ấp Tân Lộc A',
	@active_area_district_code = N'876',
	@mail = 'nmphat.partner3@mail.com',
	@BID = 'BID002',
	@bank_name = N'Ngân hàng agribank',
	@bank_branch = N'Quận 7'
go

-- Test Tài xế 2 xem đơn hàng trong khu vực đăng kí
exec dbo.usp_driver_get_orders_in_active_area 'phatnm.driver2'
go

-- Test Tài xế tiếp nhận đơn hàng
exec dbo.usp_driver_receive_order 'phatnm.driver2', 'ORDER001'
go

-- Test Tài xế theo dõi thu nhập
exec dbo.usp_driver_history_incomes 'phatnm.driver2'
go

revert
go

-- exec as user = '_employee'
-- Test Nhân viên duyệt tất cả hợp đồng
declare @number_contracts int
exec dbo.usp_employee_accept_all_contracts 
	@number_contracts_accepted = @number_contracts output

select @number_contracts as N'Số lượng hợp đồng đã duyệt'

/* -- CODE TEST ĐỤNG ĐỘ
exec dbo.usp_partner_create_contract_with_start_time
	@CID = 'CID010',
	@username = 'phatnm.partner1',
	@TIN = '01234567890123456789',
	@start_at = '2024-09-11',
	@contract_time = 6,
	@commission = 0.7
go
*/

-- nhân viên lấy các hợp dồng với status = @status
exec dbo.usp_employee_get_contracts 
	@contract_status = 'ACCEPTED'
go

-- Nhân viên duyệt đăng kí của 1 tài xế
exec dbo.usp_employee_active_driver_account 'phatnm.driver1'
go

revert
go