--  dọn dẹp
drop table if exists post_like;
drop table if exists post;

create table post (
    post_id serial primary key,
    user_id int not null,
    content text,
    tags text[],
    created_at timestamp default current_timestamp,
    is_public boolean default true
);

create table post_like (
    user_id int not null,
    post_id int not null,
    liked_at timestamp default current_timestamp,
    primary key (user_id, post_id)
);


insert into post (user_id, content, tags, created_at, is_public)
select
    (random() * 10 + 1)::int,
    case
        when gs % 3 = 0 then 'du lịch đà nẵng rất đẹp'
        when gs % 3 = 1 then 'kinh nghiệm du lịch sapa'
        else 'chia sẻ cuộc sống hàng ngày'
    end,
    case
        when gs % 2 = 0 then array['travel', 'life']
        else array['life']
    end,
    now() - (gs || ' days')::interval,
    gs % 5 <> 0
from generate_series(1, 20000) gs;


--  trước khi tạo index
explain analyze
select *
from post
where is_public = true
  and lower(content) like '%du lịch%';

--  expression index cho tìm kiếm không phân biệt hoa thường
create index idx_post_lower_content
on post (lower(content));

--  sau khi tạo index
explain analyze
select *
from post
where is_public = true
  and lower(content) like '%du lịch%';




--  trước gin index
explain analyze
select *
from post
where tags @> array['travel'];

--  tạo gin index cho tags
create index idx_post_tags_gin
on post
using gin (tags);

--  sau gin index
explain analyze
select *
from post
where tags @> array['travel'];


--  trước partial index
explain analyze
select *
from post
where is_public = true
  and created_at >= now() - interval '7 days';

--  partial index cho bài công khai
create index idx_post_recent_public
on post (created_at desc)
where is_public = true;

--  sau partial index
explain analyze
select *
from post
where is_public = true
  and created_at >= now() - interval '7 days';

--  composite index cho feed cá nhân
create index idx_post_user_recent
on post (user_id, created_at desc);

--  truy vấn "bài đăng gần đây của bạn bè"
explain analyze
select *
from post
where user_id = 3
order by created_at desc
limit 10;



/*
1. expression index (lower(content)) giúp tối ưu tìm kiếm ilike,
   tránh sequential scan trên cột text.
2. gin index là lựa chọn hiệu quả nhất cho kiểu dữ liệu array (tags),
   đặc biệt với toán tử @>.
3. partial index giúp giảm kích thước index và tăng tốc truy vấn
   khi chỉ quan tâm đến bài viết công khai.
4. composite index (user_id, created_at desc) rất phù hợp cho feed,
   truy vấn theo người dùng và sắp xếp theo thời gian.
5. kết hợp nhiều loại index đúng ngữ cảnh giúp postgresql planner
   chọn được execution plan tối ưu nhất.
*/


