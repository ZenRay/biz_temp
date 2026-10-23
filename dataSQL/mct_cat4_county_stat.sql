/*
商家四级类目区县统计
*/


-- DROP TABLE IF EXISTS changsha_mct_cat4_county_stat_daily_asc;
-- CREATE TABLE IF NOT EXISTS changsha_mct_cat4_county_stat_daily_asc (
-- 	mall_id BIGINT COMMENT "商城ID"
-- 	,merchant_id BIGINT COMMENT "商家ID"
-- 	,merchant_name STRING COMMENT "商家名称"
-- 	,category_level1_id BIGINT COMMENT "一级类目ID"
-- 	,category_level1_name STRING COMMENT "一级类目名称"
-- 	,category_level4_id BIGINT COMMENT "四级类目ID"
-- 	,category_level4_name STRING COMMENT "四级类目名称"
-- 	,province_id BIGINT COMMENT "商城ID"
-- 	,province_name STRING COMMENT "商城名称"
-- 	,city_id BIGINT COMMENT "市ID"
-- 	,city_name STRING COMMENT "市名称"
-- 	,county_id BIGINT COMMENT "区县ID"
-- 	,county_name STRING COMMENT "区县名称"
-- 	,operation_type_county STRING COMMENT "区县运营类型"
-- 	,exposed_store_num BIGINT COMMENT "曝光店铺数"
-- 	,clicked_store_num BIGINT COMMENT "点击店铺数"
-- 	,ordered_store_num BIGINT COMMENT "下单店铺数"
-- 	,delivered_goods_amt DECIMAL(10,2) COMMENT "货值"
-- )PARTITIONED BY 
-- (
--     dt STRING COMMENT "日期"
-- )
-- TBLPROPERTIES('comment'='商家四级类目区县统计');





WITH dim_sku AS(
    SELECT 
        t1.dt
        ,t1.sku_id
        ,t1.sku_name
        ,t1.mall_id
        ,t1.merchant_id
        ,t1.merchant_name
        ,t1.category_level1_id
        ,t1.category_level1_name
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.is_up_today
        ,t1.is_sku_valid
    FROM datawarehouse_max.dim_goods_daily_full t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.is_up_today>0
        AND t1.mall_id = 871
)


,dim_store AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.customer_store_id
        ,t1.province_id
        ,t1.province_name
        ,t1.city_id
        ,t1.city_name
        ,t1.county_id
        ,t1.county_name
        ,t2.is_login
        ,t1.use_status
        ,t2.county_model
    FROM datawarehouse_max.dim_store_daily_full t1
    LEFT JOIN datawarehouse_max.ads_store_mall_store_central_warehouse_fruit_features_daily_asc  t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.customer_store_id = t1.customer_store_id 
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
)

,temp AS (
    SELECT
        t1.dt
        ,t1.mall_id -- "商城ID" BIGINT
        ,t1.merchant_id -- "商家ID" BIGINT
        ,t1.merchant_name -- "商家名称" STRING
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level1_name -- "一级类目名称" STRING
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.category_level4_name -- "四级类目名称" STRING
        ,t1.province_id -- "商城ID" BIGINT
        ,t1.province_name -- "商城名称" STRING
        ,t1.city_id -- "市ID" BIGINT
        ,t1.city_name -- "市名称" STRING
        ,t1.county_id -- "区县ID" BIGINT
        ,t1.county_name -- "区县名称" STRING
        ,WM_CONCAT(
            DISTINCT "-"
            ,t1.operation_type_county
        ) AS operation_type_county -- "区县运营类型" STRING
        ,COUNT(DISTINCT IF(
            t1.exposed_cnt>0, t1.customer_store_id, NULL
        )) AS exposed_store_num -- "曝光店铺数" BIGINT
        ,COUNT(DISTINCT IF(
            t1.clicked_cnt>0, t1.customer_store_id, NULL
        )) AS clicked_store_num -- "点击店铺数" BIGINT
        ,COUNT(DISTINCT IF(
            t1.ordered_goods_num>0, t1.customer_store_id, NULL
        )) AS ordered_store_num -- "下单店铺数" BIGINT
        ,SUM(t1.delivered_goods_amt) AS delivered_goods_amt -- "货值" DECIMAL(10,2)
    FROM(
        SELECT
            t1.dt
            ,t1.mall_id
            ,t2.merchant_id
            ,t2.merchant_name
            ,t2.category_level1_id
            ,t2.category_level1_name
            ,t2.category_level4_id
            ,t2.category_level4_name
            ,t1.customer_store_id
            ,t3.province_id
            ,t3.province_name
            ,t3.city_id
            ,t3.city_name
            ,t3.county_id
            ,t3.county_name

            ,t1.ordered_goods_num
            
            ,t1.delivered_goods_amt
            ,t1.delivered_goods_num
            ,t1.deliveried_gross_wgt
            ,CASE
                WHEN
                    INSTR(t3.county_model, "自营") > 0
                THEN "自营区域"
                ELSE "代理区域"
            END AS operation_type_county -- "区县运营类型" STRING
            ,t1.exposed_cnt
            ,t1.clicked_cnt
            ,t1.added_cnt
            
        FROM datawarehouse_max.dws_store_mall_store_sku_base_daily_asc t1
        LEFT JOIN dim_sku t2
            ON t2.dt = t1.dt
            AND t2.mall_id = t1.mall_id
            AND t2.sku_id = t1.sku_id
        JOIN dim_store t3
            ON t3.dt = t1.dt
            AND t3.mall_id = t1.mall_id
            AND t3.customer_store_id = t1.customer_store_id
        

        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND t1.mall_id = 871
    )t1
    GROUP BY t1.dt
        ,t1.mall_id
        ,t1.merchant_id
        ,t1.merchant_name
        ,t1.category_level1_id
        ,t1.category_level1_name
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.province_id
        ,t1.province_name
        ,t1.city_id
        ,t1.city_name
        ,t1.county_id
        ,t1.county_name
        

)




,base AS(
    SELECT
        t1.mall_id -- "商城ID" BIGINT
        ,t1.merchant_id -- "商家ID" BIGINT
        ,t1.merchant_name -- "商家名称" STRING
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level1_name -- "一级类目名称" STRING
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.category_level4_name -- "四级类目名称" STRING
        ,t1.province_id -- "商城ID" BIGINT
        ,t1.province_name -- "商城名称" STRING
        ,t1.city_id -- "市ID" BIGINT
        ,t1.city_name -- "市名称" STRING
        ,t1.county_id -- "区县ID" BIGINT
        ,t1.county_name -- "区县名称" STRING
        ,IF(
            INSTR(t1.operation_type_county, "自营")>0, "自营区域", "代理区域"
        ) AS operation_type_county -- "区县运营类型" STRING
        ,t1.exposed_store_num -- "曝光店铺数" BIGINT
        ,t1.clicked_store_num -- "点击店铺数" BIGINT
        ,t1.ordered_store_num -- "下单店铺数" BIGINT
        ,t1.delivered_goods_amt -- "货值" DECIMAL(10,2)
        ,t1.dt
    FROM temp t1

)



INSERT OVERWRITE TABLE changsha_mct_cat4_county_stat_daily_asc PARTITION(dt)
SELECT
    t1.mall_id -- "商城ID" BIGINT
	,t1.merchant_id -- "商家ID" BIGINT
	,t1.merchant_name -- "商家名称" STRING
	,t1.category_level1_id -- "一级类目ID" BIGINT
	,t1.category_level1_name -- "一级类目名称" STRING
	,t1.category_level4_id -- "四级类目ID" BIGINT
	,t1.category_level4_name -- "四级类目名称" STRING
	,t1.province_id -- "商城ID" BIGINT
	,t1.province_name -- "商城名称" STRING
	,t1.city_id -- "市ID" BIGINT
	,t1.city_name -- "市名称" STRING
	,t1.county_id -- "区县ID" BIGINT
	,t1.county_name -- "区县名称" STRING
	,t1.operation_type_county -- "区县运营类型" STRING
	,t1.exposed_store_num -- "曝光店铺数" BIGINT
	,t1.clicked_store_num -- "点击店铺数" BIGINT
	,t1.ordered_store_num -- "下单店铺数" BIGINT
	,t1.delivered_goods_amt -- "货值" DECIMAL(10,2)
    ,t1.dt -- "日期" STRING
FROM base t1
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND t1.category_level1_name = "水果"
    AND t1.mall_id = 871
;

