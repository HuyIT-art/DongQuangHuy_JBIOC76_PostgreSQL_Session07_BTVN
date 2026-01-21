drop view if exists v_top_customers;
drop view if exists v_product_revenue;
drop view if exists v_customer_city;

drop table if exists orders;
drop table if exists products;
drop table if exists customers;


create table customers (
    customer_id serial primary key,
    full_name varchar(100),
    email varchar(100) unique,
    city varchar(50)
);

create table products (
    product_id serial primary key,
    product_name varchar(100),
    category text[],
    price numeric(10,2)
);

create table orders (
    order_id serial primary key,
    customer_id int references customers(customer_id),
    product_id int references products(product_id),
    order_date date,
    quantity int
);


insert into customers (full_name, email, city) values
('nguyen van a', 'a@gmail.com', 'hanoi'),
('tran thi b', 'b@gmail.com', 'hcm'),
('le van c', 'c@gmail.com', 'danang'),
('pham thi d', 'd@gmail.com', 'hanoi'),
('hoang van e', 'e@gmail.com', 'hcm');

insert into products (product_name, category, price) values
('laptop dell', array['electronics'], 1200),
('iphone', array['electronics', 'mobile'], 1000),
('tv samsung', array['electronics'], 800),
('chair', array['furniture'], 300),
('desk', array['furniture'], 600);

insert into orders (customer_id, product_id, order_date, quantity) values
(1, 1, '2024-01-01', 1),
(1, 2, '2024-01-02', 2),
(2, 2, '2024-01-03', 1),
(2, 3, '2024-01-04', 1),
(3, 4, '2024-01-05', 3),
(3, 5, '2024-01-06', 1),
(4, 1, '2024-01-07', 1),
(4, 3, '2024-01-08', 2),
(5, 2, '2024-01-09', 1),
(5, 5, '2024-01-10', 2);

-- truy vấn trước index

explain analyze
select * from customers where email = 'a@gmail.com';

explain analyze
select * from products where category @> array['electronics'];

explain analyze
select * from products where price between 500 and 1000;

-- tạo index

create index idx_customers_email
on customers (email);

create index idx_customers_city_hash
on customers using hash (city);

create index idx_products_category_gin
on products using gin (category);

create index idx_products_price_gist
on products using gist (price);

-- truy vấn sau index

explain analyze
select * from customers where email = 'a@gmail.com';

explain analyze
select * from products where category @> array['electronics'];

explain analyze
select * from products where price between 500 and 1000;

-- clustered index

create index idx_orders_order_date
on orders (order_date);

cluster orders using idx_orders_order_date;

-- view: top 3 khách hàng mua nhiều nhất

create view v_top_customers as
select
    c.customer_id,
    c.full_name,
    sum(o.quantity) as total_quantity
from customers c
join orders o on c.customer_id = o.customer_id
group by c.customer_id, c.full_name
order by total_quantity desc
limit 3;

select * from v_top_customers;

-- view: tổng doanh thu theo sản phẩm


create view v_product_revenue as
select
    p.product_name,
    sum(o.quantity * p.price) as total_revenue
from products p
join orders o on p.product_id = o.product_id
group by p.product_name;

select * from v_product_revenue;

-- view có thể ghi (update)


create view v_customer_city as
select customer_id, full_name, city
from customers
with check option;

-- cập nhật city qua view
update v_customer_city
set city = 'hue'
where customer_id = 1;

-- kiểm tra lại bảng gốc
select * from customers where customer_id = 1;


/*
thêm dữ liệu mẫu cho customers, products, orders
tạo b-tree index để tìm khách hàng theo email
tạo hash index để lọc khách hàng theo city
tạo gin index cho cột category dạng mảng
tạo gist index để tìm sản phẩm theo khoảng giá
so sánh hiệu suất truy vấn bằng explain analyze
thực hiện cluster bảng orders theo order_date
sử dụng view để xem top khách hàng và doanh thu sản phẩm
cập nhật dữ liệu thông qua view và kiểm tra bảng gốc
*/


