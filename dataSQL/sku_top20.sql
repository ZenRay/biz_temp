

/*
商品门店Top20统计
*/



-- DROP TABLE IF EXISTS changsha_sku_top_daily_asc;
-- CREATE TABLE IF NOT EXISTS changsha_sku_top_daily_asc (
-- 	mall_id BIGINT COMMENT "商城id"
-- 	,sku_id BIGINT COMMENT "商品id"
-- 	,sku_name STRING COMMENT "商品名称"
-- 	,category_level1_id BIGINT COMMENT "一级类目ID"
-- 	,category_level4_id BIGINT COMMENT "四级类目id"
-- 	,category_level4_name STRING COMMENT "四级类目名称"
-- 	,merchant_id BIGINT COMMENT "商家id"
-- 	,merchant_name STRING COMMENT "商家名称"
-- 	,customer_store_id BIGINT COMMENT "店铺id"
-- 	,customer_store_name STRING COMMENT "店铺名称"
--     ,store_type STRING COMMENT "门店类型"
-- 	,province_id BIGINT COMMENT "省id"
-- 	,province_name STRING COMMENT "省名称"
-- 	,city_id BIGINT COMMENT "市id"
-- 	,city_name STRING COMMENT "市名称"
-- 	,county_id BIGINT COMMENT "区县id"
-- 	,county_name STRING COMMENT "区县名称"
--     ,grid_id BIGINT COMMENT "网格ID"
--     ,grid_name STRING COMMENT "网格名称"
--     ,bd_id BIGINT COMMENT "BDID"
--     ,bd_name STRING COMMENT "BD姓名"
-- 	,ordered_cnt_30d BIGINT COMMENT "近30天下单频次"
-- 	,delivered_goods_amt_30d DECIMAL(10,2) COMMENT "近30天货值"
-- 	,applied_after_sale_cnt_30d BIGINT COMMENT "近30天售后频次"
-- 	,refund_amt_30d_by_asdt DECIMAL(10,2) COMMENT "近30天赔付金额"
-- 	,applied_after_sale_ratio_by_ordered DECIMAL(10,6) COMMENT "近30天售后频次占比"

-- 	,store_rnk BIGINT COMMENT "排名"
-- 	,top_type STRING COMMENT "头部类型"
-- )PARTITIONED BY 
-- (
--     dt STRING COMMENT "日期"
-- )
-- TBLPROPERTIES('comment'='商品Top数据统计');





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



,base AS (

    SELECT /*+ MAPJOIN(t0) */
        DATEADD(DATE(t0.dt), + 1, "dd") AS dt
        ,t1.sku_id
        ,t1.customer_store_id
        ,t1.mall_id
        ,SUM(IF(
            t1.dt BETWEEN DATEADD(DATE(t0.dt), BIGINT("${offset}") - 30, "dd")
                AND DATEADD(DATE(t0.dt), BIGINT("${offset}") - 1, "dd")
            ,t1.final_refund_amt, 0
        )) AS refund_amt_30d_by_asdt
        ,COUNT(DISTINCT IF(
            t1.dt BETWEEN DATEADD(DATE(t0.dt), BIGINT("${offset}") - 30, "dd")
                AND DATEADD(DATE(t0.dt), BIGINT("${offset}") - 1, "dd")
                AND t1.after_sale_num > 0
            ,t1.dt, NULL
        )) AS applied_after_sale_cnt_30d
        ,COUNT(DISTINCT IF(
            t1.dt BETWEEN DATEADD(DATE(t0.dt), BIGINT("${offset}") - 30, "dd")
                AND DATEADD(DATE(t0.dt), BIGINT("${offset}") - 1, "dd")
                AND t1.ordered_goods_num>0
            ,t1.dt, NULL
        )) AS ordered_cnt_30d
        ,SUM(IF(
            t1.dt BETWEEN DATEADD(DATE(t0.dt), BIGINT("${offset}") - 30, "dd")
                AND DATEADD(DATE(t0.dt), BIGINT("${offset}") - 1, "dd")
            ,t1.delivered_goods_amt, 0
        )) AS delivered_goods_amt_30d
    FROM(
        SELECT
            t1.dt
            ,t1.sku_id
            ,t1.customer_store_id
            ,t1.mall_id
            ,t1.final_refund_amt
            ,t1.ordered_goods_num
            ,t1.delivered_goods_amt
            ,t1.after_sale_num
        FROM datawarehouse_max.dws_store_mall_store_sku_base_daily_asc t1
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") -6 -30, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND t1.mall_id = 871
            AND t1.final_refund_amt > 0
    ) t1
    JOIN datawarehouse_max.dim_date_full  t0
        ON t0.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.dt BETWEEN DATEADD(DATE(t0.dt), BIGINT("${offset}") - 30, "dd")
            AND DATEADD(DATE(t0.dt), BIGINT("${offset}") - 1, "dd")
    
    GROUP BY DATEADD(DATE(t0.dt), + 1, "dd")
        ,t1.sku_id
        ,t1.customer_store_id
        ,t1.mall_id
)







,result AS(
    SELECT
        t1.mall_id -- "商城id" BIGINT
        ,t1.sku_id -- "商品id" BIGINT
        ,t01.sku_name -- "商品名称" STRING
        ,t01.category_level1_id -- "一级类目ID" BIGINT
        ,t01.category_level4_id -- "四级类目id" BIGINT
        ,t01.category_level4_name -- "四级类目名称" STRING
        ,t01.merchant_id -- "商家id" BIGINT
        ,t01.merchant_name -- "商家名称" STRING
        ,t1.customer_store_id -- "店铺id" BIGINT
        ,t2.customer_store_name -- "店铺名称" STRING
        ,t2.store_type_desc AS store_type -- "店铺类型" STRING
        ,t2.province_id -- "省id" BIGINT
        ,t2.province_name -- "省名称" STRING
        ,t2.city_id -- "市id" BIGINT
        ,t2.city_name -- "市名称" STRING
        ,t2.county_id -- "区县id" BIGINT
        ,t2.county_name -- "区县名称" STRING
        ,t2.grid_id -- "网格ID" BIGINT
        ,t2.grid_name -- "网格名称" STRING
        ,t2.bd_id -- "BDID" BIGINT
        ,t2.bd_name -- "BD姓名" STRING
        
        ,t1.ordered_cnt_30d -- "近30天下单频次" BIGINT
        ,t1.delivered_goods_amt_30d-- "近30天货值" DECIMAL(10,2)
        ,t1.applied_after_sale_cnt_30d -- "近30天售后频次" BIGINT
        ,t1.refund_amt_30d_by_asdt -- "近30天赔付金额" DECIMAL(10,2)
        ,ROUND(
            t1.applied_after_sale_cnt_30d / t1.ordered_cnt_30d, 6
        ) AS applied_after_sale_ratio_by_ordered -- "近30天售后频次占比" DECIMAL(10,6)

        ,ROW_NUMBER()OVER(
            PARTITION BY t1.dt, t1.mall_id, t1.sku_id ORDER BY t1.applied_after_sale_cnt_30d / t1.ordered_cnt_30d DESC
        ) applied_after_sale_ratio_by_ordered_desc_rnk -- "售后频次占比倒序排名" BIGINT
        ,ROW_NUMBER()OVER(
            PARTITION BY t1.dt, t1.mall_id, t1.sku_id ORDER BY t1.delivered_goods_amt_30d DESC
        ) AS delivered_goods_amt_30d_desc_cnk -- "总货值倒序排名" BIGINT
        ,t1.dt
        
    FROM base t1
    LEFT JOIN datawarehouse_max.dim_store_daily_full t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.customer_store_id = t1.customer_store_id
    JOIN datawarehouse_max.ads_changsha_sku_dashboard_daily_asc t0
        ON t0.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t0.dt = t1.dt
        AND t0.goods_id = t1.sku_id
        AND t1.mall_id = 871
    LEFT JOIN datawarehouse_max.dim_goods_daily_full t01
        ON t01.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t01.dt = t1.dt
        AND t01.sku_id = t1.sku_id
        AND t01.mall_id = t1.mall_id

    WHERE 
        t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
        AND ISNOTNULL(t1.sku_id)
)



INSERT OVERWRITE TABLE changsha_sku_top_daily_asc PARTITION (dt)
SELECT
	t1.mall_id -- "商城id" BIGINT
	,t1.sku_id -- "商品id" BIGINT
	,t1.sku_name -- "商品名称" STRING
	,t1.category_level1_id -- "一级类目ID" BIGINT
	,t1.category_level4_id -- "四级类目id" BIGINT
	,t1.category_level4_name -- "四级类目名称" STRING
	,t1.merchant_id -- "商家id" BIGINT
	,t1.merchant_name -- "商家名称" STRING
	,t1.customer_store_id -- "店铺id" BIGINT
	,t1.customer_store_name -- "店铺名称" STRING
    ,t1.store_type -- "门店类型" STRING
	,t1.province_id -- "省id" BIGINT
	,t1.province_name -- "省名称" STRING
	,t1.city_id -- "市id" BIGINT
	,t1.city_name -- "市名称" STRING
	,t1.county_id -- "区县id" BIGINT
	,t1.county_name -- "区县名称" STRING
    ,t1.grid_id -- "网格ID" BIGINT
    ,t1.grid_name -- "网格名称" STRING
    ,t1.bd_id -- "BDID" BIGINT
    ,t1.bd_name -- "BD姓名" STRING
	,t1.ordered_cnt_30d -- "近30天下单频次" BIGINT
	,t1.delivered_goods_amt_30d-- "近30天货值" DECIMAL(10,2)
	,t1.applied_after_sale_cnt_30d -- "近30天售后频次" BIGINT
	,t1.refund_amt_30d_by_asdt -- "近30天赔付金额" DECIMAL(10,2)
	,t1.applied_after_sale_ratio_by_ordered -- "近30天售后频次占比" DECIMAL(10,6)

	,t1.delivered_goods_amt_30d_desc_cnk AS store_rnk -- "排名" BIGINT
    ,"GoodsAmtTop20" AS top_type -- "头部类型" STRING
    ,t1.dt

FROM result t1
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND t1.delivered_goods_amt_30d_desc_cnk <= 20
    AND t1.mall_id = 871

UNION ALL

SELECT
	t1.mall_id -- "商城id" BIGINT
	,t1.sku_id -- "商品id" BIGINT
	,t1.sku_name -- "商品名称" STRING
	,t1.category_level1_id -- "一级类目ID" BIGINT
	,t1.category_level4_id -- "四级类目id" BIGINT
	,t1.category_level4_name -- "四级类目名称" STRING
	,t1.merchant_id -- "商家id" BIGINT
	,t1.merchant_name -- "商家名称" STRING
	,t1.customer_store_id -- "店铺id" BIGINT
	,t1.customer_store_name -- "店铺名称" STRING
    ,t1.store_type -- "门店类型" STRING
	,t1.province_id -- "省id" BIGINT
	,t1.province_name -- "省名称" STRING
	,t1.city_id -- "市id" BIGINT
	,t1.city_name -- "市名称" STRING
	,t1.county_id -- "区县id" BIGINT
	,t1.county_name -- "区县名称" STRING
    ,t1.grid_id -- "网格ID" BIGINT
    ,t1.grid_name -- "网格名称" STRING
    ,t1.bd_id -- "BDID" BIGINT
    ,t1.bd_name -- "BD姓名" STRING
	,t1.ordered_cnt_30d -- "近30天下单频次" BIGINT
	,t1.delivered_goods_amt_30d-- "近30天货值" DECIMAL(10,2)
	,t1.applied_after_sale_cnt_30d -- "近30天售后频次" BIGINT
	,t1.refund_amt_30d_by_asdt -- "近30天赔付金额" DECIMAL(10,2)
	,t1.applied_after_sale_ratio_by_ordered -- "近30天售后频次占比" DECIMAL(10,6)

	,t1.delivered_goods_amt_30d_desc_cnk AS store_rnk -- "排名" BIGINT
    ,"ASTop20" AS top_type -- "头部类型" STRING
    ,t1.dt

FROM result t1
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND t1.applied_after_sale_ratio_by_ordered_desc_rnk <= 20
    AND t1.mall_id = 871

;

