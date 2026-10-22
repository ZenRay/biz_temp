
/*
商城统计
*/


-- DROP TABLE IF EXISTS changsha_mall_stat_daily_asc;
-- CREATE TABLE IF NOT EXISTS changsha_mall_stat_daily_asc (
--     mall_id BIGINT COMMENT "商城ID"
--     ,exposed_store_num BIGINT COMMENT "曝光门店数"
--     ,delivered_goods_amt DECIMAL(10,2) COMMENT "货值"
--     ,logon_store_num BIGINT COMMENT "登录店铺数"
-- )PARTITIONED BY 
-- (
--     dt STRING COMMENT "日期"
-- )
-- TBLPROPERTIES('comment'='商城统计');



WITH mall AS(
    SELECT
        t1.mall_id
        ,t1.mall
    FROM datawarehouse_max.dim_mall_full t1
    WHERE t1.mall IN (
        "标果南昌", 
        "标果嘉兴", 
        "标果成都", 
        "标果东莞", 
        "标果贵阳", 
        "标果郑州", 
        "标果西安",
        "标果长沙"
    )
)

INSERT OVERWRITE TABLE changsha_mall_stat_daily_asc PARTITION(dt)
SELECT
    t1.mall_id -- "商城ID" BIGINT
    ,t1.exposed_store_num -- "曝光门店数" BIGINT
    ,t1.delivered_goods_amt -- "货值" DECIMAL(10,2)
    ,t2.logon_store_num -- "登录店铺数" BIGINT
    ,t1.dt -- "日期" STRING
FROM datawarehouse_max.dws_pub_mall_base_daily_asc t1
JOIN mall t0
    ON t0.mall_id = t1.mall_id

LEFT JOIN (
    SELECT
        t1.dt
        ,t1.mall_id
        ,COUNT(DISTINCT t1.customer_store_id) AS logon_store_num
    FROM datawarehouse_max.dws_store_central_warehouse_base_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.is_login > 0
    GROUP BY t1.dt
        ,t1.mall_id
) t2
    ON t2.dt = t1.dt
    AND t2.mall_id = t1.mall_id
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND ISNOTNULL(t1.mall_id)

;