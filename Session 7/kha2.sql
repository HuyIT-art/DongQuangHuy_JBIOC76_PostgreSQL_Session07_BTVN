-- 1. dọn dẹp nếu đã tồn tại
drop view if exists v_order_summary;
drop view if exists v_monthly_sales;
drop table if exists orders;
drop table if exists customer;


create table customer (
    customer_id serial primary key,
    full_name varchar(100),
    email varchar(100),
    phone varchar(15)
);

create table orders (
    order_id serial primary key,
    customer_id int references customer(customer_id),
    total_amount decimal(10,2),
    order_date date
);



insert into customer (full_name, email, phone) values
('nguyen van a', 'a@gmail.com', '0901111111'),
('tran thi b', 'b@gmail.com', '0902222222'),
('le van c', 'c@gmail.com', '0903333333');

insert into orders (customer_id, total_amount, order_date) values
(1, 1500000, '2024-01-10'),
(1, 2000000, '2024-02-15'),
(2, 3000000, '2024-02-20'),
(3, 1200000, '2024-03-05');


-- tạo view v_order_summary
-- ẩn email và phone


create view v_order_summary as
select
    c.full_name,
    o.total_amount,
    o.order_date
from customer c
join orders o on c.customer_id = o.customer_id
with check option;


--  xem tất cả dữ liệu từ view


select * from v_order_summary;


--  cập nhật tổng tiền đơn hàng thông qua view


update v_order_summary
set total_amount = 1800000
where full_name = 'nguyen van a'
  and order_date = '2024-01-10';

-- kiểm tra lại
select * from v_order_summary;


-- view thống kê tổng doanh thu mỗi tháng


create view v_monthly_sales as
select
    date_trunc('month', order_date)::date as sales_month,
    sum(total_amount) as total_revenue
from orders
group by date_trunc('month', order_date)
order by sales_month;

-- xem doanh thu theo tháng
select * from v_monthly_sales;


--  drop view


drop view v_order_summary;

/*
drop view:
- chỉ xóa định nghĩa view (câu select).
- không lưu dữ liệu vật lý.
- mỗi lần query view sẽ chạy lại câu select gốc.

drop materialized view:
- xóa cả dữ liệu đã được lưu vật lý + định nghĩa view.
- materialized view nhanh hơn khi select,
  nhưng cần refresh khi dữ liệu gốc thay đổi.

tóm lại:
view = bảng ảo (logic)
materialized view = bảng thật (có lưu dữ liệu)
*/

-- ================= end file =================
