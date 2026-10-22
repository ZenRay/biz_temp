
/*
商城一级类目
*/

-- DROP TABLE IF EXISTS changsha_mall_cat1_stat_daily_asc;
-- CREATE TABLE IF NOT EXISTS changsha_mall_cat1_stat_daily_asc (
--     mall_id BIGINT COMMENT "商城ID"
--     ,category_level1_id BIGINT COMMENT "一级类目ID"
--     ,category_level1_name STRING COMMENT "一级类目名称"
--     ,delivered_goods_amt DECIMAL(10,2) COMMENT "货值"
--     ,delivered_goods_wgt DECIMAL(10,2) COMMENT "重量"
--     ,delivered_goods_num BIGINT COMMENT "件数"
--     ,exposed_store_num BIGINT COMMENT "曝光店铺数"
--     ,ordered_store_num BIGINT COMMENT "下单店铺数"
--     ,plat_market_fee_amt DECIMAL(10,2) COMMENT "平台营销费用"
-- )PARTITIONED BY 
-- (
--     dt STRING COMMENT "日期"
-- )
-- TBLPROPERTIES('comment'='商城一级类目统计');


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



,subsidies AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t3.category_level1_id
        -- 优惠券
        ,SUM(
            NVL(t1.platform_market_amt_full_reduce_coupon, 0) + NVL(t1.platform_market_amt_single_goods_coupon,0)
        ) AS plat_coupon_market_fee
        -- 平台补贴
        ,SUM(t2.platform_subsidy_amount) AS plat_subsidy_amount
    FROM datawarehouse_max.dwt_order_order_item_daily_asc t1
    LEFT JOIN datawarehouse_max.dwt_order_clearing_asc t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.order_item_id = t1.order_item_id
    LEFT JOIN datawarehouse_max.dim_goods_daily_full  t3
        ON t3.dt = t1.dt
        AND t3.mall_id = t1.mall_id
        AND t3.sku_id = t1.sku_id
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
        AND t1.status != "CANCEL"

    GROUP BY t1.dt
        ,t1.mall_id
        ,t3.category_level1_id
)
INSERT OVERWRITE TABLE changsha_mall_cat1_stat_daily_asc PARTITION(dt)
SELECT
    t1.mall_id -- "商城ID" BIGINT
    ,t1.category_level1_id -- "一级类目ID" BIGINT
    ,t1.category_level1_name -- "一级类目名称" STRING
    ,t1.delivered_goods_amt -- "货值" DECIMAL(10,2)
    ,t1.deliveried_gross_wgt AS delivered_goods_wgt -- "重量" DECMAL(10,2)
    ,t1.delivered_goods_num -- "件数" BIGINT
    ,t1.exposed_store_num -- "曝光店铺数" BIGINT
    ,t1.ordered_store_num -- "下单店铺数" BIGINT
    ,NVL(t3.plat_subsidy_amount,0) + NVL(t3.plat_coupon_market_fee,0) AS plat_market_fee_amt -- "平台营销费用" DECIMAL(10,2)
    ,t1.dt
FROM datawarehouse_max.dws_pub_mall_cate1_base_daily_asc t1
JOIN mall t2
    ON t2.mall_id = t1.mall_id
LEFT JOIN subsidies t3
    ON t3.dt = t1.dt
    AND t3.mall_id = t1.mall_id
    AND t3.category_level1_id = t1.category_level1_id
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND t1.mall_id = 871
    AND ISNOTNULL(t1.category_level1_id)
;
