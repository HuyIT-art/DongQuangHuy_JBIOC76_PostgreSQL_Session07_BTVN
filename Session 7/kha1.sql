
-- 1. dọn dẹp nếu đã tồn tại
drop table if exists book;

-- 2. tạo bảng
create table book (
    book_id serial primary key,
    title varchar(255),
    author varchar(100),
    genre varchar(50),
    price decimal(10,2),
    description text,
    created_at timestamp default current_timestamp
);

-- 3. thêm dữ liệu mẫu (đủ lớn để thấy khác biệt)
insert into book (title, author, genre, price, description)
select
    'book ' || gs,
    case
        when gs % 5 = 0 then 'j.k. rowling'
        when gs % 5 = 1 then 'george r.r. martin'
        when gs % 5 = 2 then 'haruki murakami'
        else 'unknown author'
    end,
    case
        when gs % 3 = 0 then 'fantasy'
        when gs % 3 = 1 then 'science'
        else 'novel'
    end,
    (random() * 50 + 10)::decimal(10,2),
    'this is a fantasy magic story about wizard and dragon number ' || gs
from generate_series(1, 50000) gs;


-- 4. tìm sách theo author (ilike)
explain analyze
select * from book
where author ilike '%rowling%';

-- 5. tìm sách theo genre
explain analyze
select * from book
where genre = 'fantasy';

-- 6. tìm kiếm full-text trong description
explain analyze
select * from book
where to_tsvector('english', description)
      @@ to_tsquery('english', 'magic');


-- 7. b-tree index cho genre (tốt cho =, <, >)
create index idx_book_genre
on book (genre);

-- 8. gin index cho full-text search (title + description)
create index idx_book_fts
on book
using gin (
    to_tsvector('english', title || ' ' || description)
);


-- 9. tìm sách theo genre (dùng b-tree)
explain analyze
select * from book
where genre = 'fantasy';

-- 10. full-text search (dùng gin)
explain analyze
select * from book
where to_tsvector('english', title || ' ' || description)
      @@ to_tsquery('english', 'magic');



-- 11. sắp xếp vật lý bảng theo genre
cluster book using idx_book_genre;

-- 12. sau cluster: test lại truy vấn theo genre
explain analyze
select * from book
where genre = 'fantasy';


/*
1. b-tree index hiệu quả nhất cho truy vấn so sánh chính xác (=) trên cột genre,
   giúp postgresql tránh sequential scan.
2. gin index vượt trội trong bài toán full-text search, đặc biệt với dữ liệu text lớn.
3. truy vấn tìm kiếm từ khóa trong description nhanh hơn nhiều khi dùng gin
   so với quét toàn bảng.
4. cluster giúp cải thiện hiệu năng khi thường xuyên truy vấn theo genre,
   do dữ liệu được sắp xếp vật lý trên đĩa.
5. hash index không được khuyến khích vì chỉ hỗ trợ phép so sánh (=),
   không hỗ trợ order by, và ít được tối ưu bởi planner.
6. ngoài ra, hash index không có lợi thế rõ ràng so với b-tree trong postgresql hiện đại.
*/

