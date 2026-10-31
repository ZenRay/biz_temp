/*
SKU区县
*/


-- DROP TABLE IF EXISTS changsha_sku_county_stat_daily_asc;
-- CREATE TABLE IF NOT EXISTS changsha_sku_county_stat_daily_asc (
-- 	mall_id BIGINT COMMENT "商城id"
-- 	,sku_id BIGINT COMMENT "商品id"
-- 	,sku_name STRING COMMENT "商品名称"
-- 	,merchant_id BIGINT COMMENT "商家id"
-- 	,merchant_name STRING COMMENT "商家名称"
-- 	,category_level1_id STRING COMMENT "一级类目ID"
-- 	,category_level4_id BIGINT COMMENT "四级类目id"
-- 	,category_level4_name STRING COMMENT "四级类目名称"
-- 	,province_id BIGINT COMMENT "省id"
-- 	,province_name STRING COMMENT "省名称"
-- 	,city_id BIGINT COMMENT "市id"
-- 	,city_name STRING COMMENT "市名称"
-- 	,county_id BIGINT COMMENT "区县id"
-- 	,county_name STRING COMMENT "区县名称"
-- 	,operation_type_county STRING COMMENT "区县运营类型"
-- 	,delivered_goods_amt DECIMAL(10,2) COMMENT "货值"
-- 	,ordered_store_num BIGINT COMMENT "下单门店数"
-- 	,pool_num_new_store BIGINT COMMENT "新客户池"
-- 	,ordered_store_num_new_store BIGINT COMMENT "新客户下单店铺数"
-- 	,pool_num_old_store BIGINT COMMENT "老客户池"
-- 	,ordered_store_num_old_store BIGINT COMMENT "老客户下单门店数"
-- 	,pool_num_loss_store BIGINT COMMENT "流失客户池"
-- 	,ordered_store_num_loss_store BIGINT COMMENT "流失客户下单门店数"
    
-- 	,exposed_store_num BIGINT COMMENT "曝光店铺数"
-- 	,exposed_store_num_new_store BIGINT COMMENT "新客户曝光店铺数"
-- 	,exposed_store_num_old_store BIGINT COMMENT "老客户曝光店铺数"
-- 	,exposed_store_num_loss_store BIGINT COMMENT "召回客户曝光店铺数"
-- 	,delivered_goods_amt_desc_rnk BIGINT COMMENT "货值降序排名"
-- 	,delivered_goods_amt_asc_rnk BIGINT COMMENT "货值增序排名"
    
-- 	,logon_store_num_by_county BIGINT COMMENT "区县登录店铺数"
-- 	,exposed_store_num_by_county BIGINT COMMENT "区县曝光店铺数"
-- 	,ordered_store_num_by_county BIGINT COMMENT "区县下单门店数"
--     ,shared_links_cnt BIGINT COMMENT "BD分享次数"
--     ,shared_links_store_num BIGINT COMMENT "BD分享触达店铺数"
--     ,exposed_store_num_by_share_links BIGINT COMMENT "BD分享曝光店铺数"
--     ,clicked_store_num_by_share_links BIGINT COMMENT "点击BD分享链接店铺数"
--     ,ordered_store_num_by_share_links BIGINT COMMENT "有BD分享下单的店铺数"
-- )PARTITIONED BY 
-- (
--     dt STRING COMMENT "日期"
-- )
-- TBLPROPERTIES('comment'='商品区县统计');





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

,store_tag AS (
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.sku_id
        ,t1.customer_store_id
        ,t2.province_id
        ,t2.city_id
        ,t2.county_id
        ,CASE 
            WHEN 
                INSTR(NVL(t1.customer_store_tag, "new_no_order"), "new_no_order") > 0
            THEN "new"
            WHEN
                INSTR(NVL(t1.customer_store_tag, "new_no_order"), "new_1_order") + 
                    INSTR(NVL(t1.customer_store_tag, "new_no_order"), "new_2_order") + 
                    INSTR(NVL(t1.customer_store_tag, "new_no_order"), "new_3_order") > 0
            THEN "new_pool"
            ELSE NVL(t1.customer_store_tag, "new_no_order") || "_pool"
        END AS customer_store_tag
        ,t1.is_ordered_today
        ,t1.is_exposed_today
    FROM datawarehouse_max.ads_changsha_mall_customer_sku_tag_daily_asc t1
    LEFT JOIN datawarehouse_max.dim_store_daily_full t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.dt = t1.dt
        AND t2.customer_store_id = t1.customer_store_id
        AND t2.mall_id = t1.mall_id
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871


)


,dim_sku AS(
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
        ,REGEXP_REPLACE(t1.city_name, "\\d", "") AS city_name -- "市名称" STRING
        ,t1.county_id
        ,t1.county_name
        ,t2.is_login
        ,t1.use_status
        
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




,recommends_stat AS(
    SELECT
        t1.dt -- `日期`
        ,t1.mall_id -- `商城ID`
        ,t1.sku_id
        ,t3.province_id
        ,t3.county_id
        ,t3.city_id
        ,SUM(t1.recommend_cnt) AS shared_links_cnt -- "BD分享次数" BIGINT
        
        ,COUNT(DISTINCT t1.customer_store_id) AS shared_links_store_num -- "BD分享触达店铺数" BIGINT
        ,COUNT(DISTINCT IF(
            t2.exposed_cnt >0, t1.customer_store_id, NULL
        )) AS exposed_store_num_by_share_links -- "BD分享曝光店铺数" BIGINT
        ,COUNT(DISTINCT IF(
            t2.exposed_cnt>0 AND t2.clicked_cnt>0, t1.customer_store_id, NULL
        )) AS clicked_store_num_by_share_links -- "点击BD分享链接店铺数" BIGINT
        ,COUNT(DISTINCT IF(
            t2.exposed_cnt>0 AND t2.ordered_goods_num>0, t1.customer_store_id, NULL
        )) AS ordered_store_num_by_share_links -- "有BD分享下单的店铺数" BIGINT
    FROM (
        SELECT
            t1.dt -- "日期" STRING
            ,t1.mall_id -- "商城ID" BIGINT
            ,t1.sku_id -- "商品ID" BIGINT
            ,t1.customer_store_id -- "店铺ID" BIGINT
            ,COUNT(t1.create_time) AS recommend_cnt -- "BD分享次数" BIGINT
        FROM datawarehouse_max.dwd_store_mall_store_sku_bd_recommend_detail_daily_asc t1

        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND t1.mall_id = 871
        GROUP BY t1.dt -- "日期" STRING
            ,t1.mall_id
            ,t1.sku_id -- "商品ID" BIGINT
            ,t1.customer_store_id -- "店铺ID" BIGINT
    ) t1

    LEFT JOIN datawarehouse_max.dws_store_mall_store_sku_base_daily_asc t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.dt = t1.dt
        AND t2.sku_id = t1.sku_id
        AND t2.customer_store_id = t1.customer_store_id
        AND t2.mall_id = t1.mall_id
    LEFT JOIN dim_store t3
        ON t3.dt = t1.dt
        AND t3.mall_id = t1.mall_id
        AND t3.customer_store_id = t1.customer_store_id
    GROUP BY t1.dt -- `日期`
        ,t1.mall_id -- `商城ID`
        ,t1.sku_id
        ,t3.province_id
        ,t3.county_id
        ,t3.city_id
)


,temp AS (
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.sku_id
        ,t1.category_level1_id
        ,t1.category_level1_name
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.customer_store_id
        ,t3.province_id
        ,t3.province_name
        ,t3.city_id
        ,REGEXP_REPLACE(t3.city_name, "\\d", "") AS city_name -- "市名称" STRING
        ,t3.county_id
        ,t3.county_name
        ,t3.is_login
        ,t3.use_status

        ,t1.exposed_cnt
        ,t1.ordered_goods_num
        ,t1.delivered_goods_amt
        ,NVL(t2.customer_store_tag, "new_no_order") AS customer_store_tag
        
    FROM datawarehouse_max.dws_store_mall_store_sku_base_daily_asc t1
    LEFT JOIN store_tag t2
        ON t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.sku_id = t1.sku_id
        AND t2.customer_store_id = t1.customer_store_id
    JOIN dim_store t3
        ON t3.dt = t1.dt
        AND t3.mall_id = t1.mall_id
        AND t3.customer_store_id = t1.customer_store_id
    


    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871


)




,base AS(
    SELECT
        t1.*
        ,NVL(t2.business_model, "自营") || "区域" AS operation_type_county -- "区县运营类型" STRING
    FROM (
        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.sku_id
            ,t1.province_id
            ,t1.province_name
            ,t1.city_id
            ,t1.city_name
            ,t1.county_id
            ,t1.county_name
            ,SUM(t1.delivered_goods_amt) AS delivered_goods_amt
        
            ,COUNT(DISTINCT IF(
                INSTR(NVL(t1.customer_store_tag, "new"), "new")>0, t1.customer_store_id, NULL
            )) AS pool_num_new_store
            ,COUNT(DISTINCT IF(
                INSTR(NVL(t1.customer_store_tag, "new"), "old")>0, t1.customer_store_id, NULL
            )) AS pool_num_old_store
            ,COUNT(DISTINCT IF(
                INSTR(NVL(t1.customer_store_tag, "new"), "loss")>0, t1.customer_store_id, NULL
            )) AS pool_num_loss_store


            
            ,COUNT(DISTINCT IF(
                t1.exposed_cnt>0 , t1.customer_store_id, NULL
            )) AS exposed_store_num
            ,COUNT(DISTINCT IF(
                t1.exposed_cnt>0 AND INSTR(NVL(t1.customer_store_tag, "new"), "new")>0, t1.customer_store_id, NULL
            )) AS exposed_store_num_new_store
            ,COUNT(DISTINCT IF(
                t1.exposed_cnt>0 AND INSTR(NVL(t1.customer_store_tag, "new"), "old")>0, t1.customer_store_id, NULL
            )) AS exposed_store_num_old_store
            ,COUNT(DISTINCT IF(
                t1.exposed_cnt>0 AND INSTR(NVL(t1.customer_store_tag, "new"), "loss")>0, t1.customer_store_id, NULL
            )) AS exposed_store_num_loss_store

            ,COUNT(DISTINCT IF(t1.ordered_goods_num>0, t1.customer_store_id, NULL )) AS ordered_store_num
            ,COUNT(DISTINCT IF(
                t1.ordered_goods_num>0 AND INSTR(NVL(t1.customer_store_tag, "new"), "new")>0, t1.customer_store_id, NULL
            )) AS ordered_store_num_new_store
            ,COUNT(DISTINCT IF(
                t1.ordered_goods_num>0 AND INSTR(NVL(t1.customer_store_tag, "new"), "old")>0, t1.customer_store_id, NULL
            )) AS ordered_store_num_old_store
            ,COUNT(DISTINCT IF(
                t1.ordered_goods_num>0 AND INSTR(NVL(t1.customer_store_tag, "new"), "loss")>0, t1.customer_store_id, NULL
            )) AS ordered_store_num_loss_store
        FROM temp t1
        
        GROUP BY t1.dt
            ,t1.mall_id
            ,t1.sku_id
            ,t1.province_id
            ,t1.province_name
            ,t1.city_id
            ,t1.city_name
            ,t1.county_id
            ,t1.county_name
    ) t1
    LEFT JOIN (
        SELECT
            t1.dt
            ,t1.mall_name
            ,t0.mall_id
            ,t1.province_name
            ,t1.city_name
            ,t1.county_name
            ,t1.business_model
        FROM  datawarehouse_max.ods_feishu_mall_county_business_model_info_daily_full  t1
        JOIN mall t0
            ON t0.mall = t1.mall_name
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND t1.dt BETWEEN t1.start_data AND t1.end_data
        GROUP BY t1.dt
            ,t1.mall_name
            ,t0.mall_id
            ,t1.province_name
            ,t1.city_name
            ,t1.county_name
            ,t1.business_model
    ) t2
        ON t2.dt = t1.dt
        AND t1.mall_id = t2.mall_id
        AND t2.province_name = t1.province_name
        AND t2.city_name = t1.city_name
        AND t2.county_name = t1.county_name
)



INSERT OVERWRITE TABLE changsha_sku_county_stat_daily_asc PARTITION(dt)
SELECT
    t1.mall_id -- "商城id" BIGINT
    ,t1.sku_id -- "商品id" BIGINT
    ,t01.sku_name -- "商品名称" STRING
    ,t01.merchant_id -- "商家id" BIGINT
    ,t01.merchant_name -- "商家名称" STRING
    ,t01.category_level1_id -- "一级类目ID" STRING
    ,t01.category_level4_id -- "四级类目id" BIGINT
    ,t01.category_level4_name -- "四级类目名称" STRING
    ,t1.province_id -- "省id" BIGINT
    ,t1.province_name -- "省名称" STRING
    ,t1.city_id -- "市id" BIGINT
    ,t1.city_name -- "市名称" STRING
    ,t1.county_id -- "区县id" BIGINT
    ,t1.county_name -- "区县名称" STRING
    ,t1.operation_type_county -- "区县运营类型" STRING
    ,t1.delivered_goods_amt -- "货值" DECIMAL(10,2)
    ,t1.ordered_store_num -- "下单门店数" BIGINT
    ,t1.pool_num_new_store -- "新客户池" BIGINT
    ,t1.ordered_store_num_new_store -- "新客户下单店铺数" BIGINT
    ,t1.pool_num_old_store -- "老客户池" BIGINT
    ,t1.ordered_store_num_old_store -- "老客户下单门店数" BIGINT
    ,t1.pool_num_loss_store -- "流失客户池" BIGINT
    ,t1.ordered_store_num_loss_store -- "流失客户下单门店数" BIGINT
    
    ,t1.exposed_store_num -- "曝光店铺数" BIGINT
    ,t1.exposed_store_num_new_store -- "新客户曝光店铺数" BIGINT
    ,t1.exposed_store_num_old_store -- "老客户曝光店铺数" BIGINT
    ,t1.exposed_store_num_loss_store -- "召回客户曝光店铺数" BIGINT
    ,DENSE_RANK() OVER(
        PARTITION BY t1.dt, t1.sku_id,  t1.operation_type_county ORDER BY t1.delivered_goods_amt DESC
    ) AS delivered_goods_amt_desc_rnk -- "货值降序排名" BIGINT
    ,DENSE_RANK() OVER(
        PARTITION BY t1.dt, t1.sku_id, t1.operation_type_county ORDER BY t1.delivered_goods_amt ASC
    ) AS delivered_goods_amt_asc_rnk -- "货值增序排名" BIGINT
    
    ,t03.logon_store_num_by_county -- "区县登录店铺数" BIGINT
    ,t3.exposed_store_num_by_county -- "区县曝光店铺数" BIGINT
    ,t3.ordered_store_num_by_county -- "区县下单门店数" BIGINT
    ,t5.shared_links_cnt -- "BD分享次数" BIGINT
    ,t5.shared_links_store_num -- "BD分享触达店铺数" BIGINT
    ,t5.exposed_store_num_by_share_links -- "BD分享曝光店铺数" BIGINT
    ,t5.clicked_store_num_by_share_links -- "点击BD分享链接店铺数" BIGINT
    ,t5.ordered_store_num_by_share_links -- "有BD分享下单的店铺数" BIGINT
    ,t1.dt -- "日期" STRING
FROM base t1

JOIN dim_sku t01
    ON t01.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND t01.dt = t1.dt
    AND t01.sku_id = t1.sku_id
    AND t01.mall_id = t1.mall_id
LEFT JOIN (
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.province_id
        ,t1.city_id
        ,t1.county_id
        ,COUNT(DISTINCT IF(t1.ordered_goods_num>0, t1.customer_store_id, NULL)) AS ordered_store_num_by_county
        -- ,COUNT(DISTINCT IF(t1.is_login>0, t1.customer_store_id, NULL)) AS logon_store_num_by_county
        ,COUNT(DISTINCT IF(
            t1.exposed_cnt >0, t1.customer_store_id, NULL
        )) AS exposed_store_num_by_county
    FROM temp t1
    GROUP BY t1.dt
        ,t1.mall_id
        ,t1.province_id
        ,t1.city_id
        ,t1.county_id
) t3
    ON t3.dt = t1.dt
    AND t3.mall_id = t1.mall_id
    AND t3.province_id = t1.province_id
    AND t3.city_id = t1.city_id
    AND t3.county_id = t1.county_id

LEFT JOIN (
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.county_id
        ,t1.city_id
        ,t1.province_id
        ,COUNT(DISTINCT IF(t1.is_login>0, t1.customer_store_id, NULL)) logon_store_num_by_county
    FROM dim_store t1
    GROUP BY t1.dt
        ,t1.mall_id
        ,t1.county_id
        ,t1.city_id
        ,t1.province_id
) t03
    ON t03.dt = t1.dt
    AND t03.mall_id = t1.mall_id
    AND t03.province_id = t1.province_id
    AND t03.city_id = t1.city_id
    AND t03.county_id = t1.county_id

LEFT JOIN (
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.sku_id
        ,t1.province_id
        ,t1.city_id
        ,t1.county_id
        
        ,COUNT(DISTINCT IF(t1.customer_store_tag="new", t1.customer_store_id, NULL)) AS new_pool_store_num
        ,COUNT(DISTINCT IF(
            t1.customer_store_tag="new" AND t1.is_exposed_today>0, t1.customer_store_id, NULL
        )) AS exposed_new_pool_store_num
        ,COUNT(DISTINCT IF(
            t1.customer_store_tag="new" AND t1.is_exposed_today>0
                AND t1.is_ordered_today>0, t1.customer_store_id, NULL
        )) AS exposed2ordered_new_pool_store_num
        ,COUNT(DISTINCT IF(
            INSTR(t1.customer_store_tag, "old")>0, t1.customer_store_id, NULL
        )) AS old_pool_store_num
        ,COUNT(DISTINCT IF(
            INSTR(t1.customer_store_tag, "loss")>0, t1.customer_store_id, NULL
        )) AS loss_pool_store_num
    FROM store_tag t1
    GROUP BY t1.dt
        ,t1.mall_id
        ,t1.sku_id
        ,t1.province_id
        ,t1.city_id
        ,t1.county_id
) t4
    ON t4.dt = t1.dt
    AND t4.mall_id = t1.mall_id
    AND t4.sku_id = t1.sku_id
    AND t4.province_id = t1.province_id
    AND t4.county_id = t1.county_id
    AND t4.city_id = t1.city_id

LEFT JOIN recommends_stat t5
    ON t5.dt = t1.dt
    AND t5.mall_id = t1.mall_id
    AND t5.sku_id = t1.sku_id
    AND t5.province_id = t1.province_id
    AND t5.city_id = t1.city_id
    AND t5.county_id = t1.county_id


WHERE NVL(t3.ordered_store_num_by_county, 0) + NVL(t03.logon_store_num_by_county, 0) +
        NVL(t3.exposed_store_num_by_county, 0)>0
    AND t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND t01.category_level1_name = "水果"
    AND t1.mall_id = 871
;


