
/*
四级类目区县统计
*/


-- DROP TABLE IF EXISTS changsha_cat4_county_stat_daily_asc;
-- CREATE TABLE IF NOT EXISTS changsha_cat4_county_stat_daily_asc (
-- 	mall_id BIGINT COMMENT "商城ID"
-- 	,category_level1_id BIGINT COMMENT "一级类目ID"
-- 	,category_level1_name STRING COMMENT "一级类目名称"
-- 	,category_level4_id BIGINT COMMENT "四级类目ID"
-- 	,category_level4_name STRING COMMENT "四级类目名称"
-- 	,province_id BIGINT COMMENT "省ID"
-- 	,province_name STRING COMMENT "省名称"
-- 	,city_id BIGINT COMMENT "市ID"
-- 	,city_name STRING COMMENT "市名称"
-- 	,county_id BIGINT COMMENT "区县ID"
-- 	,county_name STRING COMMENT "区县名称"
-- 	,operation_type_county STRING COMMENT "区县运营类型"
-- 	,exposed_store_num BIGINT COMMENT "曝光店铺数"
-- 	,clicked_store_num BIGINT COMMENT "点击店铺数"
-- 	,ordered_store_num BIGINT COMMENT "下单店铺数"
-- 	,delivered_goods_amt DECIMAL(10,2) COMMENT "货值"
--     ,pool_store_num_new_store BIGINT COMMENT "新客户池"
--     ,pool_store_num_old_store BIGINT COMMENT "老客户池"
--     ,pool_store_num_loss_store BIGINT COMMENT "召回客户池"
--     ,exposed_store_num_new_store  BIGINT COMMENT "新客户曝光店铺数"
--     ,clicked_store_num_new_store  BIGINT COMMENT "新客户点击店铺数"
--     ,ordered_store_num_new_store  BIGINT COMMENT "新客户下单店铺数"
--     ,exposed_store_num_old_store  BIGINT COMMENT "老客户曝光店铺数"
--     ,clicked_store_num_old_store  BIGINT COMMENT "老客户点击店铺数"
--     ,ordered_store_num_old_store  BIGINT COMMENT "老客户下单店铺数"
--     ,exposed_store_num_loss_store  BIGINT COMMENT "召回客户曝光店铺数"
--     ,ordered_store_num_loss_store  BIGINT COMMENT "召回客户下单店铺数"
--     ,shared_links_cnt BIGINT COMMENT "BD分享次数"
--     ,shared_links_store_num BIGINT COMMENT "BD分享触达店铺数"
--     ,exposed_store_num_by_share_links BIGINT COMMENT "BD分享曝光店铺数"
--     ,clicked_store_num_by_share_links BIGINT COMMENT "点击BD分享链接店铺数"
--     ,ordered_store_num_by_share_links BIGINT COMMENT "有BD分享下单的店铺数"    
-- )PARTITIONED BY 
-- (
--     dt STRING COMMENT "日期"
-- )
-- TBLPROPERTIES('comment'='四级类目区县统计');





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
        ,REGEXP_REPLACE(t1.city_name, "\\d", "") AS city_name
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




,store_tag AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.category_level4_id
        ,t02.category_level1_id
        ,t1.customer_store_id
        ,t2.province_id
        ,t2.city_id
        ,t2.county_id
        ,t1.customer_store_tag
    FROM datawarehouse_max.dws_pub_mall_cate4_customer_tag_daily_asc t1
    LEFT JOIN datawarehouse_max.dim_category_daily_full t02
        ON t02.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t02.dt = t1.dt
        AND t02.back_category_id = t1.category_level4_id
        AND t02.source_type= "OLD"
    LEFT JOIN dim_store t2
        ON t2.dt = t1.dt
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
        
        ,COUNT(DISTINCT IF(
            t1.exposed_cnt>0 AND INSTR(t1.customer_store_tag, "new")>0, t1.customer_store_id, NULL
        )) AS exposed_store_num_new_store -- "新客户曝光店铺数" BIGINT
        ,COUNT(DISTINCT IF(
            t1.clicked_cnt>0 AND INSTR(t1.customer_store_tag, "new")>0, t1.customer_store_id, NULL
        )) AS clicked_store_num_new_store -- "新客户点击店铺数" BIGINT
        ,COUNT(DISTINCT IF(
            t1.ordered_goods_num>0 AND INSTR(t1.customer_store_tag, "new")>0, t1.customer_store_id, NULL
        )) AS ordered_store_num_new_store -- "新客户下单店铺数" BIGINT

        ,COUNT(DISTINCT IF(
            t1.exposed_cnt>0 AND INSTR(t1.customer_store_tag, "old")>0, t1.customer_store_id, NULL
        )) AS exposed_store_num_old_store -- "老客户曝光店铺数" BIGINT
        ,COUNT(DISTINCT IF(
            t1.clicked_cnt>0 AND INSTR(t1.customer_store_tag, "old")>0, t1.customer_store_id, NULL
        )) AS clicked_store_num_old_store -- "老客户点击店铺数" BIGINT
        ,COUNT(DISTINCT IF(
            t1.ordered_goods_num>0 AND INSTR(t1.customer_store_tag, "old")>0, t1.customer_store_id, NULL
        )) AS ordered_store_num_old_store -- "老客户下单店铺数" BIGINT

        ,COUNT(DISTINCT IF(
            t1.exposed_cnt>0 AND INSTR(t1.customer_store_tag, "loss")>0, t1.customer_store_id, NULL
        )) AS exposed_store_num_loss_store -- "召回客户曝光店铺数" BIGINT
        ,COUNT(DISTINCT IF(
            t1.clicked_cnt>0 AND INSTR(t1.customer_store_tag, "loss")>0, t1.customer_store_id, NULL
        )) AS clicked_store_num_loss_store -- "召回客户点击店铺数" BIGINT
        ,COUNT(DISTINCT IF(
            t1.ordered_goods_num>0 AND INSTR(t1.customer_store_tag, "loss")>0, t1.customer_store_id, NULL
        )) AS ordered_store_num_loss_store -- "召回客户下单店铺数" BIGINT
    FROM(
        SELECT
            t1.dt
            ,t1.mall_id
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
            ,t1.exposed_cnt
            ,t1.clicked_cnt
            ,t1.added_cnt
            ,NVL(t4.customer_store_tag, "new") AS customer_store_tag
        FROM datawarehouse_max.dws_store_mall_store_sku_base_daily_asc t1
        LEFT JOIN dim_sku t2
            ON t2.dt = t1.dt
            AND t2.mall_id = t1.mall_id
            AND t2.sku_id = t1.sku_id
        JOIN dim_store t3
            ON t3.dt = t1.dt
            AND t3.mall_id = t1.mall_id
            AND t3.customer_store_id = t1.customer_store_id
        LEFT JOIN store_tag t4
            ON t4.dt = t1.dt
            AND t4.mall_id = t1.mall_id
            AND t4.category_level1_id = t1.category_level1_id
            AND t4.category_level4_id = t1.category_level4_id
            AND t4.customer_store_id = t1.customer_store_id

        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND t1.mall_id = 871
    )t1
    GROUP BY t1.dt
        ,t1.mall_id
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


,recommends_stat AS(
    SELECT
        t1.dt -- `日期`
        ,t1.mall_id -- `商城ID`
        ,t3.category_level1_id
        ,t3.category_level4_id
        ,t4.province_id
        ,t4.city_id
        ,t4.county_id
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
    LEFT JOIN dim_sku t3
        ON t3.dt = t1.dt
        AND t3.sku_id =t1.sku_id
        AND t3.mall_id  = t1.mall_id
    LEFT JOIN dim_store t4
        ON t4.dt = t1.dt
        AND t4.customer_store_id = t1.customer_store_id
        AND t4.mall_id = t1.mall_id
    GROUP BY t1.dt -- `日期`
        ,t1.mall_id -- `商城ID`
        ,t3.category_level1_id
        ,t3.category_level4_id
        ,t4.province_id
        ,t4.city_id
        ,t4.county_id
)



,base AS(
    SELECT
        t1.mall_id -- "商城ID" BIGINT
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level1_name -- "一级类目名称" STRING
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.category_level4_name -- "四级类目名称" STRING
        ,t1.province_id -- "省ID" BIGINT
        ,t1.province_name -- "省名称" STRING
        ,t1.city_id -- "市ID" BIGINT
        ,t1.city_name -- "市名称" STRING
        ,t1.county_id -- "区县ID" BIGINT
        ,t1.county_name -- "区县名称" STRING
        ,NVL(t2.business_model, "自营") || "区域" AS operation_type_county -- "区县运营类型" STRING
        
        ,t1.exposed_store_num -- "曝光店铺数" BIGINT
        ,t1.clicked_store_num -- "点击店铺数" BIGINT
        ,t1.ordered_store_num -- "下单店铺数" BIGINT
        ,t1.delivered_goods_amt -- "货值" DECIMAL(10,2)
        ,t3.pool_store_num_new_store -- "新客户池" BIGINT
        ,t3.pool_store_num_old_store -- "老客户池" BIGINT
        ,t3.pool_store_num_loss_store -- "召回客户池" BIGINT
        ,t1.exposed_store_num_new_store -- "新客户曝光店铺数" BIGINT
        ,t1.clicked_store_num_new_store -- "新客户点击店铺数" BIGINT
        ,t1.ordered_store_num_new_store -- "新客户下单店铺数" BIGINT
        ,t1.exposed_store_num_old_store -- "老客户曝光店铺数" BIGINT
        ,t1.clicked_store_num_old_store -- "老客户点击店铺数" BIGINT
        ,t1.ordered_store_num_old_store -- "老客户下单店铺数" BIGINT
        ,t1.exposed_store_num_loss_store -- "召回客户曝光店铺数" BIGINT
        ,t1.ordered_store_num_loss_store -- "召回客户下单店铺数" BIGINT
        ,t1.dt
    FROM temp t1
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

    
    LEFT JOIN (
        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.category_level1_id
            ,t1.category_level4_id
            ,t1.province_id
            ,t1.city_id
            ,t1.county_id
            ,COUNT(DISTINCT IF(
                INSTR(t1.customer_store_tag, "new") >0, t1.customer_store_id, NULL
            )) AS pool_store_num_new_store -- "新客户池" BIGINT
            ,COUNT(DISTINCT IF(
                INSTR(t1.customer_store_tag, "old") >0, t1.customer_store_id, NULL
            )) AS pool_store_num_old_store -- "老客户池" BIGINT
            ,COUNT(DISTINCT IF(
                INSTR(t1.customer_store_tag, "loss") >0, t1.customer_store_id, NULL
            )) AS pool_store_num_loss_store -- "召回客户池" BIGINT
        FROM store_tag t1

        GROUP BY t1.dt
            ,t1.mall_id
            ,t1.category_level1_id
            ,t1.category_level4_id
            ,t1.province_id
            ,t1.city_id
            ,t1.county_id
    ) t3
        ON t3.dt = t1.dt
        AND t3.mall_id = t1.mall_id
        AND t3.province_id = t1.province_id
        AND t3.city_id = t1.city_id
        AND t3.county_id = t1.county_id
        AND t3.category_level1_id = t1.category_level1_id
        AND t3.category_level4_id = t1.category_level4_id

)



INSERT OVERWRITE TABLE changsha_cat4_county_stat_daily_asc PARTITION(dt)
SELECT
    t1.mall_id -- "商城ID" BIGINT
	,t1.category_level1_id -- "一级类目ID" BIGINT
	,t1.category_level1_name -- "一级类目名称" STRING
	,t1.category_level4_id -- "四级类目ID" BIGINT
	,t1.category_level4_name -- "四级类目名称" STRING
	,t1.province_id -- "省ID" BIGINT
	,t1.province_name -- "省名称" STRING
	,t1.city_id -- "市ID" BIGINT
	,t1.city_name -- "市名称" STRING
	,t1.county_id -- "区县ID" BIGINT
	,t1.county_name -- "区县名称" STRING
	,t1.operation_type_county -- "区县运营类型" STRING
	,t1.exposed_store_num -- "曝光店铺数" BIGINT
	,t1.clicked_store_num -- "点击店铺数" BIGINT
	,t1.ordered_store_num -- "下单店铺数" BIGINT
	,t1.delivered_goods_amt -- "货值" DECIMAL(10,2)
    ,t1.pool_store_num_new_store -- "新客户池" BIGINT
    ,t1.pool_store_num_old_store -- "老客户池" BIGINT
    ,t1.pool_store_num_loss_store -- "召回客户池" BIGINT
    ,t1.exposed_store_num_new_store -- "新客户曝光店铺数" BIGINT
    ,t1.clicked_store_num_new_store -- "新客户点击店铺数" BIGINT
    ,t1.ordered_store_num_new_store -- "新客户下单店铺数" BIGINT
    ,t1.exposed_store_num_old_store -- "老客户曝光店铺数" BIGINT
    ,t1.clicked_store_num_old_store -- "老客户点击店铺数" BIGINT
    ,t1.ordered_store_num_old_store -- "老客户下单店铺数" BIGINT
    ,t1.exposed_store_num_loss_store -- "召回客户曝光店铺数" BIGINT
    ,t1.ordered_store_num_loss_store -- "召回客户下单店铺数" BIGINT

    ,t2.shared_links_cnt -- "BD分享次数" BIGINT
    ,t2.shared_links_store_num -- "BD分享触达店铺数" BIGINT
    ,t2.exposed_store_num_by_share_links -- "BD分享曝光店铺数" BIGINT
    ,t2.clicked_store_num_by_share_links -- "点击BD分享链接店铺数" BIGINT
    ,t2.ordered_store_num_by_share_links -- "有BD分享下单的店铺数" BIGINT
    ,t1.dt -- "日期" STRING
FROM base t1
LEFT JOIN recommends_stat t2
    ON t2.dt = t1.dt
    AND t2.mall_id = t1.mall_id
    AND t2.category_level1_id = t1.category_level1_id
    AND t2.category_level4_id = t1.category_level4_id
    AND t2.province_id = t1.province_id
    AND t2.city_id = t1.city_id
    AND t2.county_id = t1.county_id
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND t1.category_level1_name = "水果"
    AND t1.mall_id = 871
;