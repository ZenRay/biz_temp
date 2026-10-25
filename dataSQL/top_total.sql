
/*
跨中心仓Top
*/

-- DROP TABLE IF EXISTS changsha_top_total_stat_daily_asc;
-- CREATE TABLE IF NOT EXISTS changsha_top_total_stat_daily_asc (
--     mall_id  BIGINT COMMENT "商城id"
--     ,category_level1_id  BIGINT COMMENT "一级类目id"
--     ,category_level4_id  BIGINT COMMENT "四级类目id"
--     ,category_level4_name  STRING COMMENT "四级类目名称"
--     ,merchant_id  BIGINT COMMENT "商家ID"
--     ,merchant_name  STRING COMMENT "商家名称"
--     ,sku_id BIGINT COMMENT "商品ID"
--     ,sku_name  STRING COMMENT "商品名称"
--     ,metric_value  DECIMAL(15,6) COMMENT "数据值"
--     ,top_type  STRING COMMENT 'Top类型'
--     ,join_type  STRING COMMENT "关联方式"
-- )PARTITIONED BY 
-- (
--     dt STRING COMMENT "日期"
-- )
-- TBLPROPERTIES('comment'='跨中心仓Top');





        

WITH base AS(
    SELECT
        t1.dt -- "日期"
        ,t1.mall_id -- "商城id" BIGINT
        ,t1.category_level1_id -- "一级类目id" BIGINT
        ,t1.category_level4_id -- "四级类目id" BIGINT
        ,t1.category_level4_name -- "四级类目名称" STRING
        ,NULL AS merchant_id -- "商家ID" BIGINT
        ,NULL AS merchant_name -- "商家名称" STRING
        ,NULL AS sku_id -- "商品ID" BIGINT
        ,NULL AS sku_name -- "商品名称" STRING
        ,t1.exposed2ordered_store_ratio AS metric_value -- "数据值" DECIMAL(15,6)
        ,"跨中心仓Top1品类曝光转化率" AS top_type -- ' Top类型' STRING
        ,"一级类目" AS join_type -- "关联方式" STRING
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level1_id
            ORDER BY t1.exposed2ordered_store_ratio DESC
        ) AS rnk
    FROM changsha_cat4_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND INSTR(t1.category_level1_name, "水果") > 0
    QUALIFY rnk = 1

    UNION

    SELECT
        t1.dt -- "日期"
        ,t1.mall_id -- "商城id" BIGINT
        ,t1.category_level1_id -- "一级类目id" BIGINT
        ,t1.category_level4_id -- "四级类目id" BIGINT
        ,t1.category_level4_name -- "四级类目名称" STRING
        ,NULL AS merchant_id -- "商家ID" BIGINT
        ,NULL AS merchant_name -- "商家名称" STRING
        ,NULL AS sku_id -- "商品ID" BIGINT
        ,NULL AS sku_name -- "商品名称" STRING
        ,t1.exposed_store_num AS metric_value -- "数据值" DECIMAL(15,6)
        ,"跨中心仓同品类Top1品类曝光店铺数" AS top_type -- ' Top类型' STRING
        ,"四级类目" AS join_type -- "关联方式" STRING
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level4_id
            ORDER BY t1.exposed_store_num DESC
        ) AS rnk
    FROM changsha_cat4_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        
    QUALIFY rnk = 1

    UNION

    SELECT
        t1.dt -- "日期"
        ,t1.mall_id -- "商城id" BIGINT
        ,t1.category_level1_id -- "一级类目id" BIGINT
        ,t1.category_level4_id -- "四级类目id" BIGINT
        ,t1.category_level4_name -- "四级类目名称" STRING
        ,NULL AS merchant_id -- "商家ID" BIGINT
        ,NULL AS merchant_name -- "商家名称" STRING
        ,NULL AS sku_id -- "商品ID" BIGINT
        ,NULL AS sku_name -- "商品名称" STRING
        ,t1.exposed_store_num AS metric_value -- "数据值" DECIMAL(15,6)
        ,"跨中心仓Top1品类曝光店铺数" AS top_type -- ' Top类型' STRING
        ,"一级类目" AS join_type -- "关联方式" STRING
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level1_id
            ORDER BY t1.exposed_store_num DESC
        ) AS rnk
    FROM changsha_cat4_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND INSTR(t1.category_level1_name, "水果") >0
    QUALIFY rnk = 1

    UNION
    SELECT
        t1.dt -- "日期"
        ,t1.mall_id -- "商城id" BIGINT
        ,t1.category_level1_id -- "一级类目id" BIGINT
        ,t1.category_level4_id -- "四级类目id" BIGINT
        ,t1.category_level4_name -- "四级类目名称" STRING
        ,NULL AS merchant_id -- "商家ID" BIGINT
        ,NULL AS merchant_name -- "商家名称" STRING
        ,NULL AS sku_id -- "商品ID" BIGINT
        ,NULL AS sku_name -- "商品名称" STRING
        ,t1.exposed2ordered_store_ratio AS metric_value -- "数据值" DECIMAL(15,6)
        ,"跨中心仓同品类Top1品类曝光转化率" AS top_type -- ' Top类型' STRING
        ,"四级类目" AS join_type -- "关联方式" STRING
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level4_id
                ORDER BY t1.exposed2ordered_store_ratio DESC
        ) AS rnk
    FROM changsha_cat4_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        
        QUALIFY rnk = 1


    UNION


    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.merchant_id AS merchant_id
        ,t1.merchant_name AS merchant_name
        ,NULL AS sku_id
        ,NULL AS sku_name
        ,t1.exposed_store_ratio_by_mall AS metric_value
        ,"跨中心仓同品类Top1商家品类曝光占比" AS top_type
        ,"四级类目" AS join_type
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level4_id
                ORDER BY t1.exposed_store_ratio_by_mall DESC
        ) AS rnk
    FROM changsha_mct_cat4_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        
    QUALIFY rnk = 1


    UNION


    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.merchant_id
        ,t1.merchant_name
        ,NULL AS sku_id
        ,NULL AS sku_name
        ,t1.ordered_store_ratio_by_cat1 AS metric_value
        ,"跨中心仓同品类Top1商家品类日活覆盖率" AS top_type
        ,"四级类目" AS join_type
        ,1 AS rnk
    FROM changsha_mct_cat4_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.ordered_store_ratio_by_cat1_rnk =1
        AND t1.ordered_store_ratio_by_cat1 > 0
        

    UNION 
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.merchant_id AS merchant_id
        ,t1.merchant_name AS merchant_name
        ,NULL AS sku_id
        ,NULL AS sku_name
        ,t1.exposed2ordered_store_ratio AS metric_value
        ,"跨中心仓Top1商家品类曝光转化率" AS top_type
        ,"一级类目" AS join_type
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level1_id
                ORDER BY t1.exposed2ordered_store_ratio DESC
        ) AS rnk
    FROM changsha_mct_cat4_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND INSTR(t1.category_level1_name, "水果") >0
        AND t1.exposed2ordered_store_ratio > 0
    QUALIFY rnk = 1

    UNION 
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.merchant_id AS merchant_id
        ,t1.merchant_name AS merchant_name
        ,NULL AS sku_id
        ,NULL AS sku_name
        ,t1.ordered_store_num AS metric_value
        ,"跨中心仓Top1商家品类下单店铺数" AS top_type
        ,"一级类目" AS join_type
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level1_id
                ORDER BY t1.ordered_store_num DESC
        ) AS rnk
    FROM changsha_mct_cat4_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND INSTR(t1.category_level1_name, "水果") >0
        AND t1.ordered_store_num > 0
    QUALIFY rnk = 1
    
    UNION

    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.merchant_id AS merchant_id
        ,t1.merchant_name
        ,NULL AS sku_id
        ,NULL AS sku_name
        ,t1.exposed_store_ratio_by_mall AS metric_value
        ,"跨中心仓同品类Top1商家品类曝光占商城比例" AS top_type
        ,"四级类目" AS join_type
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level4_id
                ORDER BY t1.exposed_store_ratio_by_mall DESC
        ) AS rnk
    FROM changsha_mct_cat4_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.exposed_store_ratio_by_mall > 0
        
    QUALIFY rnk = 1

    UNION

    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.merchant_id
        ,t1.merchant_name
        ,NULL AS sku_id
        ,NULL AS sku_name
        ,t1.exposed_store_ratio_by_cat4 AS metric_value
        ,"跨中心仓同品类Top1商家品类曝光占品类比例" AS top_type
        ,"四级类目" AS join_type
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level4_id
                ORDER BY t1.exposed_store_ratio_by_cat4 DESC 
        ) AS rnk
    FROM changsha_mct_cat4_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.exposed_store_ratio_by_cat4 > 0
        
    QUALIFY rnk = 1

    UNION

    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.merchant_id
        ,t1.merchant_name
        ,t1.sku_id
        ,t1.sku_name
        ,t1.ordered_store_ratio_by_cat1 AS metric_value
        ,"跨中心仓同品类Top1商品日活覆盖率" AS top_type
        ,"四级类目" AS join_type
        ,1
    FROM changsha_sku_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.ordered_store_ratio_by_cat1_rnk =1
        AND t1.ordered_store_ratio_by_cat1 > 0
        

    UNION

    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.merchant_id
        ,t1.merchant_name
        ,t1.sku_id
        ,t1.sku_name
        ,t1.exposed2ordered_store_ratio AS metric_value
        ,"跨中心仓同品类Top1商品曝光转化率" AS top_type
        ,"四级类目" AS join_type
        ,1
    FROM changsha_sku_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.exposed2ordered_store_ratio_desc_rnk_by_cat4 =1
        AND t1.exposed2ordered_store_ratio > 0
        

    UNION

    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.merchant_id
        ,t1.merchant_name
        ,t1.sku_id
        ,t1.sku_name
        ,t1.exposed2ordered_store_ratio AS metric_value
        ,"跨中心仓Top1商品曝光转化率" AS top_type
        ,"一级类目" AS join_type
        ,1
    FROM changsha_sku_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.exposed2ordered_store_ratio_desc_rnk_by_non =1
        AND t1.exposed2ordered_store_ratio > 0
        AND INSTR(t1.category_level1_name, "水果") > 0

    UNION 
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.merchant_id
        ,t1.merchant_name
        ,t1.sku_id
        ,t1.sku_name
        ,t1.ordered_store_ratio_by_cat1 AS metric_value
        ,"跨中心仓Top1商品日活覆盖率" AS top_type
        ,"一级类目" AS join_type
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level1_id
                ORDER BY t1.ordered_store_ratio_by_cat1 DESC
        ) AS rnk
    FROM changsha_sku_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.ordered_store_ratio_by_cat1 > 0
        AND INSTR(t1.category_level1_name, "水果") >0
    QUALIFY rnk = 1

    UNION

    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.merchant_id
        ,t1.merchant_name
        ,NULL AS sku_id
        ,NULL AS sku_name
        ,t1.exposed2ordered_store_ratio AS metric_value
        ,"跨中心仓同品类Top1商家品类曝光转化率" AS top_type
        ,"四级类目" AS join_type
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level4_id
                ORDER BY t1.exposed2ordered_store_ratio DESC 
        ) AS rnk
    FROM changsha_mct_cat4_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.exposed2ordered_store_ratio > 0
        
    QUALIFY rnk = 1

    UNION

    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.merchant_id
        ,t1.merchant_name
        ,NULL AS sku_id
        ,NULL AS sku_name
        ,t1.exposed_store_num AS metric_value
        ,"跨中心仓同品类Top1商家品类曝光店铺数" AS top_type
        ,"四级类目" AS join_type
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level4_id
                ORDER BY t1.exposed_store_num DESC 
        ) AS rnk
    FROM changsha_mct_cat4_stat_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.exposed_store_num > 0
        
    QUALIFY rnk = 1


)


INSERT OVERWRITE TABLE changsha_top_total_stat_daily_asc PARTITION(dt)
SELECT
	t1.mall_id -- "商城id" BIGINT
	,t1.category_level1_id -- "一级类目id" BIGINT
	,t1.category_level4_id -- "四级类目id" BIGINT
	,t1.category_level4_name -- "四级类目名称" STRING
	,t1.merchant_id -- "商家ID" BIGINT
	,t1.merchant_name -- "商家名称" STRING
	,t1.sku_id -- "商品ID" BIGINT
	,t1.sku_name -- "商品名称" STRING
	,t1.metric_value -- "数据值" DECIMAL(15,6)
	,t1.top_type -- ' Top类型' STRING
	,t1.join_type -- "关联方式" STRING
    
    ,t1.dt -- "日期"
FROM base t1
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
;
