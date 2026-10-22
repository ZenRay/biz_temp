-- DROP TABLE IF EXISTS changsha_county_daily_asc;
-- CREATE TABLE IF NOT EXISTS changsha_county_daily_asc (
--     mall_id  BIGINT COMMENT "商城ID"
--     ,province_id  BIGINT COMMENT "省ID"
--     ,province_name  STRING COMMENT "省名称"
--     ,city_id  BIGINT COMMENT "市ID"
--     ,city_name  STRING COMMENT "市名称"
--     ,county_id  BIGINT COMMENT "区县ID"
--     ,county_name  STRING COMMENT "区县名称"
--     ,ordered_store_num  BIGINT COMMENT "下单门店数"
--     ,visited_item_info STRING COMMENT "BD拜访详情"
--     ,visited_store_num  BIGINT COMMENT "拜访门店数量"
-- )PARTITIONED BY 
-- (
--     dt STRING COMMENT "日期"
-- )
-- TBLPROPERTIES('comment'='区县统计');


WITH visited_store AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t2.province_id
        ,t2.city_id
        ,t2.county_id
        ,t1.bd_id
        ,t1.bd_name
        ,"{"
            || '"bd_id" :' || t1.bd_id || ","
            || '"bd_name" : "' || t1.bd_name || '",'
            || '"visited_store_num" :' 
            || COUNT(DISTINCT IF(NVL(t1.is_visit_store,0) + NVL(t1.is_visit_on_line,0)>0, t1.customer_store_id, NULL)) ||
        "}" AS visited_item
        ,COUNT(DISTINCT IF(NVL(t1.is_visit_store,0) + NVL(t1.is_visit_on_line,0)>0, t1.customer_store_id, NULL)) AS visited_store_num -- "拜访门店数量" BIGINT
    FROM datawarehouse_max.dws_store_mall_store_business_format_visit_info_daily_asc t1
    LEFT JOIN datawarehouse_max.dim_store_daily_full t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.mall_id = t1.mall_id
        AND t2.customer_store_id = t1.customer_store_id
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id=871
    GROUP BY t1.dt
        ,t1.mall_id
        ,t2.province_id
        ,t2.city_id
        ,t2.county_id
        ,t1.bd_id
        ,t1.bd_name
)

INSERT OVERWRITE TABLE changsha_county_daily_asc PARTITION(dt)
SELECT
    t1.mall_id -- "商城ID" BIGINT
    ,t1.province_id -- "省ID" BIGINT
    ,t1.province_name -- "省名称" STRING
    ,t1.city_id -- "市ID" BIGINT
    ,t1.city_name -- "市名称" STRING
    ,t1.county_id -- "区县ID" BIGINT
    ,t1.county_name -- "区县名称" STRING
    ,t1.ordered_store_num -- "下单门店数" BIGINT
    ,IF(
        t2.visited_store_num>0, t2.visited_item_info, NULL
    ) AS visited_item_info -- "BD拜访详情" STRING
    ,t2.visited_store_num -- "拜访门店数量" BIGINT

    ,t1.dt
FROM datawarehouse_max.dws_pub_mall_country_base_daily_asc t1
LEFT JOIN (
    SELECT
        t1.dt
        ,t1.province_id
        ,t1.city_id
        ,t1.county_id
        ,t1.mall_id
        ,"["
            || ARRAY_JOIN(FILTER(
                COLLECT_LIST(
                    t1.visited_item), item -> GET_JSON_OBJECT(item, "$.visited_store_num")>0
                ), ","
            ) ||
        "]" AS visited_item_info -- "BD拜访详情" STRING
        ,SUM(t1.visited_store_num) AS visited_store_num -- "拜访门店数量" BIGINT
    FROM visited_store t1
    GROUP BY t1.dt
        ,t1.province_id
        ,t1.city_id
        ,t1.county_id
        ,t1.mall_id
) t2
    ON t2.dt = t1.dt
    AND t2.mall_id = t1.mall_id
    AND t2.province_id = t1.province_id
    AND t2.city_id = t1.city_id
    AND t2.county_id = t1.county_id
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND t1.mall_id = 871
    AND ISNOTNULL(t1.county_id)

;
