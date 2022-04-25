use db_19vp_delivery
go

revert
go

-- creat 6 role
CREATE LOGIN _app WITH PASSWORD = '1', CHECK_POLICY = OFF;
CREATE LOGIN _admin WITH PASSWORD = '1', CHECK_POLICY = OFF;
CREATE LOGIN _partner WITH PASSWORD = '1', CHECK_POLICY = OFF;
CREATE LOGIN _customer WITH PASSWORD = '1', CHECK_POLICY = OFF;
CREATE LOGIN _employee WITH PASSWORD = '1', CHECK_POLICY = OFF;
CREATE LOGIN _driver WITH PASSWORD = '1', CHECK_POLICY = OFF;
GO

CREATE user _app from login _app;
CREATE user _admin from login _admin;
CREATE user _partner from login _partner;
CREATE user _customer from login _customer;
CREATE user _employee from login _employee;
CREATE user _driver from login _driver;
go

-- public access
grant exec on dbo.usp_get_provinces to public
grant exec on dbo.usp_get_districts to public
grant exec on dbo.usp_get_wards to public
grant select on dbo.WARDS to public
grant select on dbo.DISTRICTS to public
grant select on dbo.PROVINCES to public


-- GRANT ACCESS TO _app
grant exec on dbo.fn_app_log_in to _app


-- GRANT ACCESS TO _partner

grant exec on dbo.fn_app_log_in to _partner
grant exec on dbo.usp_user_get_order_details to _partner
grant exec on dbo.usp_partner_registation to _partner
grant exec on dbo.usp_partner_register_contract to _partner
grant exec on dbo.usp_partner_register_contract_with_start_time to _partner
grant exec on dbo.usp_partner_get_accepted_contracts to _partner
grant exec on dbo.usp_partner_get_expired_contracts to _partner
grant exec on dbo.usp_partner_add_branch to _partner
grant exec on dbo.usp_partner_add_product to _partner
grant exec on dbo.usp_partner_update_product to _partner
grant exec on dbo.usp_partner_delete_product to _partner
grant exec on dbo.usp_partner_add_product_to_branch to _partner
grant exec on dbo.usp_partner_delete_product_from_branch to _partner
grant exec on dbo.usp_partner_get_orders to _partner
grant exec on dbo.usp_partner_or_driver_update_delivery_status to _partner

-- GRANT ACCESS TO _customer
grant insert, select, update on dbo.ORDERS to _customer
grant insert, select, update on dbo.ORDERS_DETAILS to _customer
grant select, select, update on dbo.PRODUCT_IN_BRANCHES to _customer

grant exec on dbo.fn_app_log_in to _customer
grant exec on dbo.usp_user_get_order_details to _customer

grant exec on dbo.usp_customer_registration to _customer
grant exec on usp_customer_get_partner to _customer
grant exec on usp_customer_get_products to _customer
grant exec on usp_customer_change_cart_detail to _customer
grant exec on dbo.usp_customer_get_cart_details to _customer
grant exec on dbo.usp_customer_delete_cart_details to _customer
grant exec on dbo.usp_customer_create_order to _customer
grant exec on dbo.usp_customer_add_product_to_order to _customer
grant exec on dbo.usp_customer_remove_product_to_order to _customer
grant exec on dbo.usp_customer_pay_order to _customer

-- GRANT ACCESS TO _driver
grant exec on dbo.fn_app_log_in to _driver
grant exec on dbo.usp_user_get_order_details to _driver

grant exec on dbo.usp_driver_registration to _driver
grant exec on dbo.usp_driver_get_orders_in_active_area to _driver
grant exec on dbo.usp_driver_receive_order to _driver
grant exec on dbo.usp_driver_history_incomes to _driver

-- GRANT ACCESS TO _employee
grant exec on dbo.fn_app_log_in to _employee
grant exec on dbo.usp_user_get_order_details to _employee

grant exec on dbo.usp_employee_get_contracts to _employee
grant exec on dbo.usp_employee_accept_all_contracts to _employee
grant exec on dbo.usp_employee_accept_contract to _employee
-- grant exec on dbo.usp_employee_active_partner_account to _employee
-- grant exec on dbo.usp_employee_active_driver_account to _employee
grant exec on dbo.usp_employee_active_all_driver_accounts to _employee

-- GRANT ACCESS TO _admin
grant exec on dbo.fn_app_log_in to _admin
grant exec on dbo.usp_user_get_order_details to _admin

grant exec on dbo.usp_admin_add_admin_account to _admin
grant exec on dbo.usp_admin_delete_admin_account to _admin
grant exec on dbo.usp_admin_add_employee_account to _admin
grant exec on dbo.usp_admin_delete_employee_account to _admin
grant exec on dbo.usp_admin_change_account_status to _admin
