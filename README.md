# 借助LLM，搜集开源新闻

## 安装依赖

1. `bundle install`

## CREATE TABLE

1. SEE `news.sql`

```sql
CREATE TABLE public.news (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    date date NOT NULL,
    summary text,
    category character varying(100),
    url text
);
```

## 收集

1. ruby news_collection.rb
2. input URL
3. 请输入操作 (S: 保存, D: 丢弃, E: 修改分类, F: 修改日期)
4. exit

## 导出

1. ruby export_db_to_excel.rb

