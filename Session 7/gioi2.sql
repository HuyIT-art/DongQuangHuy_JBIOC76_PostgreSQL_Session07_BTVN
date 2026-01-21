-- 1. dọn dẹp
drop view if exists v_order_detail_updatable;
drop view if exists v_revenue_above_avg;
drop view if exists v_revenue_by_region;
drop materialized view if exists mv_monthly_sales;

drop table if exists order_detail;
drop table if exists orders;
drop table if exists product;
drop table if exists customer;


create table customer (
    customer_id serial primary key,
    full_name varchar(100),
    region varchar(50)
);

create table orders (
    order_id serial primary key,
    customer_id int references customer(customer_id),
    total_amount decimal(10,2),
    order_date date,
    status varchar(20)
);

create table product (
    product_id serial primary key,
    name varchar(100),
    price decimal(10,2),
    category varchar(50)
);

create table order_detail (
    order_id int references orders(order_id),
    product_id int references product(product_id),
    quantity int
);



insert into customer (full_name, region) values
('nguyen van a', 'north'),
('tran thi b', 'south'),
('le van c', 'central'),
('pham thi d', 'north');

insert into orders (customer_id, total_amount, order_date, status) values
(1, 5000000, '2024-01-10', 'new'),
(2, 8000000, '2024-01-15', 'new'),
(3, 3000000, '2024-02-05', 'shipped'),
(4, 9000000, '2024-02-20', 'new');


create view v_revenue_by_region as
select
    c.region,
    sum(o.total_amount) as total_revenue
from customer c
join orders o on c.customer_id = o.customer_id
group by c.region;

-- xem dữ liệu
select * from v_revenue_by_region;


select *
from v_revenue_by_region
order by total_revenue desc
limit 3;


create view v_order_detail_updatable as
select
    o.order_id,
    o.customer_id,
    o.total_amount,
    o.order_date,
    o.status
from orders o
where o.status = 'new'
with check option;

-- xem đơn hàng new
select * from v_order_detail_updatable;


-- hợp lệ: vẫn thỏa where status = 'new'
update v_order_detail_updatable
set status = 'new'
where order_id = 1;

-- không hợp lệ: vi phạm with check option
-- (lệnh này sẽ fail)
update v_order_detail_updatable
set status = 'shipped'
where order_id = 1;


create materialized view mv_monthly_sales as
select
    date_trunc('month', order_date) as month,
    sum(total_amount) as monthly_revenue
from orders
group by date_trunc('month', order_date);

-- xem dữ liệu
select * from mv_monthly_sales;

--  nested view

create view v_revenue_above_avg as
select *
from v_revenue_by_region
where total_revenue >
      (select avg(total_revenue) from v_revenue_by_region);

-- xem kết quả
select * from v_revenue_above_avg;


/*
1. v_revenue_by_region là view tổng hợp (group by),
   chỉ dùng để select, không update được.
2. v_order_detail_updatable là view đơn giản trên 1 bảng,
   cho phép update và kiểm soát dữ liệu bằng with check option.
3. with check option ngăn cập nhật làm bản ghi "biến mất" khỏi view.
4. nested view giúp tái sử dụng logic và làm câu sql dễ đọc hơn.
5. materialized view lưu dữ liệu vật lý, cần refresh khi dữ liệu gốc thay đổi.
*/

