/*
品类Top门店
*/

-- DROP TABLE IF EXISTS changsha_cat4_store_top_daily_asc;
-- CREATE TABLE IF NOT EXISTS changsha_cat4_store_top_daily_asc (
-- 	mall_id BIGINT COMMENT "商城ID"
-- 	,category_level1_id BIGINT COMMENT "一级类目ID"
-- 	,category_level1_name STRING COMMENT "一级类目名称"
-- 	,category_level4_id BIGINT COMMENT "四级类目ID"
-- 	,category_level4_name STRING COMMENT "四级类目名称"
-- 	,customer_store_id BIGINT COMMENT "店铺ID"
-- 	,customer_store_name STRING COMMENT "店铺名称"
--     ,store_type STRING COMMENT "店铺类型"
-- 	,province_id BIGINT COMMENT "省ID"
-- 	,province_name STRING COMMENT "省名称"
-- 	,city_id BIGINT COMMENT "市ID"
-- 	,city_name STRING COMMENT "市名称"
-- 	,county_id BIGINT COMMENT "区县ID"
-- 	,county_name STRING COMMENT "区县名称"
--     ,operation_type_county STRING COMMENT "区县运营类型"
--     ,grid_id BIGINT COMMENT "网格ID"
--     ,grid_name STRING COMMENT "网格名称"
--     ,bd_id BIGINT COMMENT "BDID"
--     ,bd_name STRING COMMENT "BD姓名"
-- 	,delivered_goods_amt_30d DECIMAL(15,2) COMMENT "近30天货值"
-- 	,ordered_goods_num_30d BIGINT COMMENT "近30天下单件数"
-- 	,refund_amt_by_asdt_30d DECIMAL(15,2) COMMENT "近30天售后赔付金额"
-- 	,ordered_cnt_30d BIGINT COMMENT "近30天下单次数"
-- 	,applied_after_sale_cnt_30d BIGINT COMMENT "近30天申请售后次数"
-- 	,applied_after_sale_cnt_30d_by_mct BIGINT COMMENT "近30天申请售后不同商家次数"
-- 	,after_sale_info_mct_30d STRING COMMENT "近30天商家售后表现信息"
-- 	,onselved_mct_num_30d BIGINT COMMENT "近30天上架商品商家数量"
-- 	,ordered_mct_num_30d BIGINT COMMENT "近30天下单商家数量"
-- 	,applied_after_sale_ratio_ordered DECIMAL(10,6) COMMENT "近30天申请售后次数占下单频次比"
-- 	,store_rnk BIGINT COMMENT "门店排序"
-- 	,rnk_type STRING COMMENT "排序类型:GoodsAmtTop30:货值Top30，RefundAmt30:赔付金额Top30, AppliedAfterSaleRatio30:提交售后频次占比Top30"
-- )PARTITIONED BY 
-- (
--     dt STRING COMMENT "日期"
-- )
-- TBLPROPERTIES('comment'='四级类目Top门店数据统计');



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
        ,t1.mall_id
        ,t1.sku_id
        ,t1.sku_name
        ,t1.merchant_id
        ,t1.merchant_name
        ,t1.merit
        ,CASE
            WHEN
                INSTR(t1.merchant_name, "老顽童") + INSTR(t1.merchant_name, "阿玲")>0 AND t1.mall_id = 871
            THEN "全品类商家"
            WHEN
                INSTR(t1.merchant_name, "老顽童") + INSTR(t1.merchant_name, "阿玲")=0 AND t1.mall_id = 871
            THEN "商家"
            ELSE t1.merchant_type_desc
        END AS merchant_type -- "商家类型" STRING
        ,t1.category_level1_id
        ,t1.category_level1_name
        ,t1.category_level4_id
        ,t1.category_level4_name

        ,t1.is_up_today
        ,t1.is_sku_valid
        
        ,t1.commision_rate AS commission_rate_conf -- "配置商品抽佣率" DECIMAL(10,4)
    FROM datawarehouse_max.dim_goods_daily_full t1
    
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6 -30, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")

)


,dim_dates AS(
    SELECT
        t1.dt
    FROM datawarehouse_max.dim_date_full t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
)




,dim_store AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.customer_store_id
        ,t1.customer_store_name
        ,t1.store_type_desc AS store_type
        ,t1.province_id
        ,t1.province_name
        ,t1.city_id
        ,t1.grid_id
        ,t1.grid_name
        ,t1.bd_id
        ,t1.bd_name
        ,REGEXP_REPLACE(t1.city_name, "\\d", "") AS city_name -- "市名称" STRING
        ,t1.county_id
        ,t1.county_name
        ,t2.is_login
        ,t1.use_status
        ,NVL(t3.business_model, "自营") || "区域" AS operation_type_county -- "区县运营类型" STRING
    FROM datawarehouse_max.dim_store_daily_full t1
    LEFT JOIN datawarehouse_max.ads_store_mall_store_central_warehouse_fruit_features_daily_asc  t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.customer_store_id = t1.customer_store_id 
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
    ) t3
        ON t3.dt = t1.dt
        AND t1.mall_id = t3.mall_id
        AND t3.province_name = t1.province_name
        AND t3.city_name = t1.city_name
        AND t3.county_name = t1.county_name
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
)



,temp AS (
    SELECT
        t1.dt -- "日期" STRING
        ,t2.merchant_id -- "商家ID" BIGINT
        ,t2.merchant_name -- "商家名称" STRING
        ,t2.category_level1_id -- "一级类目ID" BIGINT
        ,t2.category_level1_name
        ,t2.category_level4_id -- "四级类目ID" BIGINT
        ,t2.category_level4_name
        ,t1.customer_store_id -- "店铺ID" BIGINT
        ,t1.mall_id -- "商城ID" BIGINT
        ,SUM(t1.final_refund_amt) AS refund_amt_by_asdt -- "自然日赔付金额" DECIMAL(10,2)
        ,SUM(t1.delivered_goods_amt) AS delivered_goods_amt -- "货值" DECIMAL(10,2)
        ,SUM(t1.ordered_goods_num) AS ordered_goods_num -- "下单数量" BIGINT
        ,SUM(t1.after_sale_num) AS after_sale_num_by_asdt -- "自然日售后数量" BIGINT
        
    FROM datawarehouse_max.dws_store_mall_store_sku_base_daily_asc t1
    LEFT JOIN dim_sku t2
        ON t2.dt = t1.dt
        AND  t2.mall_id = t1.mall_id
        AND t2.sku_id = t1.sku_id
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") -6 -30, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 1, "dd")
        AND t1.mall_id = 871
        AND NVL(t1.final_refund_amt,0) + NVL(t1.delivered_goods_amt, 0)
            + NVL(t1.ordered_goods_num, 0) > 0
        AND ISNOTNULL(t1.sku_id)
        AND ISNOTNULL(t1.customer_store_id)
    GROUP BY t1.dt
        ,t2.merchant_id
        ,t2.merchant_name
        ,t2.category_level1_id
        ,t2.category_level1_name
        ,t2.category_level4_id
        ,t2.category_level4_name
        ,t1.customer_store_id
        ,t1.mall_id

)

,css_rebuy AS(
    SELECT
        t1.dt -- "日期" STRING
        ,t1.merchant_id -- "商家ID" BIGINT
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.customer_store_id -- "店铺ID" BIGINT
        ,t1.mall_id -- "商城ID" BIGINT
        ,CASE
            WHEN
                SIZE(rebuy_dt_with_same_mct_cat4) > 0
            THEN "复购同商家同品类"
            WHEN
                SIZE(rebuy_dt_with_same_mct_cat4)=0
                AND SIZE(rebuy_dt_with_same_cat4)>0
            THEN "复购同品类不同商家"
            WHEN
                SIZE(rebuy_dt_with_same_mct_cat4)=0
                AND SIZE(rebuy_dt_with_same_cat4)=0
                AND SIZE(rebuy_dt_with_same_cat1) > 0
            THEN "复购不同品类"
            ELSE "未复购水果"
        END AS rebuy_type
    FROM(
    SELECT
        t1.dt -- "日期" STRING
        ,t1.merchant_id -- "商家ID" BIGINT
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.customer_store_id -- "店铺ID" BIGINT
        ,t1.mall_id -- "商城ID" BIGINT
        ,COLLECT_SET(t2.dt) AS rebuy_dt_with_same_mct_cat4
        ,COLLECT_SET(
            "{"
                '"merchant_name": "' || t3.merchant_id || "-" || t3.merchant_name || '",'
                || '"dt": "' || t3.dt || '"'
            || "}"
        ) AS rebuy_dt_with_same_cat4
        ,COLLECT_SET(
            "{"
                '"merchant_name": "' || t4.merchant_id || "-" || t4.merchant_name || '",'
                '"category_level4_name": "' || t4.category_level4_id || "-" || t4.category_level4_name || '",'
                || '"dt": "' || t4.dt || '"'
            || "}"
        ) AS rebuy_dt_with_same_cat1
    FROM temp t1
    LEFT JOIN temp t2
        ON t2.mall_id = t1.mall_id
        AND t2.merchant_id = t1.merchant_id
        AND t2.category_level1_id = t1.category_level1_id
        AND  t2.category_level4_id = t1.category_level4_id
        AND t2.customer_store_id = t1.customer_store_id
        AND t2.dt BETWEEN DATEADD(DATE(t1.dt), 0, "dd")
            AND DATEADD(DATE(t1.dt), 7, "dd")
        AND t2.ordered_goods_num > 0
    LEFT JOIN temp t3
        ON t3.mall_id = t1.mall_id
        AND t3.category_level1_id = t1.category_level1_id
        AND  t3.category_level4_id = t1.category_level4_id
        AND t3.customer_store_id = t1.customer_store_id
        AND t3.merchant_id != t1.merchant_id
        AND t3.dt BETWEEN DATEADD(DATE(t1.dt), 0, "dd")
            AND DATEADD(DATE(t1.dt), 7, "dd")
        AND t3.ordered_goods_num > 0

    LEFT JOIN temp t4
        ON t4.mall_id = t1.mall_id
        AND t4.category_level1_id = t1.category_level1_id
        AND  t4.category_level4_id != t1.category_level4_id
        AND t4.customer_store_id = t1.customer_store_id
        AND t4.merchant_id != t1.merchant_id
        AND t4.dt BETWEEN DATEADD(DATE(t1.dt), 0, "dd")
            AND DATEADD(DATE(t1.dt), 7, "dd")
        AND t4.ordered_goods_num > 0
    WHERE t1.after_sale_num_by_asdt > 0
        AND INSTR(t1.category_level1_name, "水果") > 0
    GROUP BY t1.dt
        ,t1.merchant_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.customer_store_id
        ,t1.mall_id

    ) t1
)



,base_mct AS(
    SELECT
        t1.dt
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.customer_store_id -- "店铺ID" BIGINT
        ,t1.mall_id -- "商城ID" BIGINT
        
        ,"{"
            || WM_CONCAT(
                ",", '"' || CONCAT_WS("-", t1.merchant_id, t2.merchant_name) || '":' || "{"
                            || '"近30天货值":' || t1.delivered_goods_amt_30d || ","
                            || '"近30天自然日赔付金额":' || t1.refund_amt_by_asdt || ","
                            || '"近30天下单次数": ' || t1.ordered_cnt_30d || ","
                            || '"近30天申请售后次数": ' || t1.applied_after_sale_cnt_30d || ","
                            || '"近30日内售后七日复购相同商家品类次数": ' || t1.rebuy_same_mct_cat4_cdta6d_cnt_30d || ","
                            || '"近30日内售后七日复购相同品类次数": ' || t1.rebuy_same_cat4_cdta6d_cnt_30d || ","
                            || '"近30日内售后七日复购不同品类次数":' || t1.rebuy_same_cat1_cdta6d_cnt_30d || ","
                            || '"近30日内售后七日未复购次数":' || t1.non_rebuy_cat1_cdta6d_cnt_30d
                        || "}"
        ) || "}" AS after_sale_info_mct_30d -- "商家售后表现信息" STRING
    FROM(
        SELECT/*+ MAPJOIN(t0) */
            t0.dt
            ,t1.merchant_id -- "商家ID" BIGINT
            ,t1.category_level1_id -- "一级类目ID" BIGINT
            ,t1.category_level4_id -- "四级类目ID" BIGINT
            ,t1.customer_store_id -- "店铺ID" BIGINT
            ,t1.mall_id -- "商城ID" BIGINT
            ,SUM(t1.delivered_goods_amt) AS delivered_goods_amt_30d -- "近30天货值" DECIMAL(15,2)
            ,SUM(t1.refund_amt_by_asdt) AS refund_amt_by_asdt -- "近30日自然日赔付金额" DECIMAL(10,2)
            ,COUNT(DISTINCT IF(t1.ordered_goods_num>0, t1.dt, NULL)) AS ordered_cnt_30d -- "近30天下单次数" BIGINT
            ,COUNT(DISTINCT IF(t1.after_sale_num_by_asdt>0, t1.dt, NULL)) AS applied_after_sale_cnt_30d -- "近30天申请售后次数" BIGINT
            ,COUNT(DISTINCT IF(
                t2.rebuy_type="复购同商家同品类", t2.dt,NULL
            )) AS rebuy_same_mct_cat4_cdta6d_cnt_30d -- "近30日内售后七日复购相同商家品类次数" BIGINT
            ,COUNT(DISTINCT IF(
                t2.rebuy_type="复购同品类不同商家", t2.dt,NULL
            )) AS rebuy_same_cat4_cdta6d_cnt_30d -- "近30日内售后七日复购相同品类次数" BIGINT
            ,COUNT(DISTINCT IF(
                t2.rebuy_type="复购不同品类", t2.dt,NULL
            )) AS rebuy_same_cat1_cdta6d_cnt_30d -- "近30日内售后七日复购不同品类次数" BIGINT
            ,COUNT(DISTINCT IF(
                t2.rebuy_type="未复购水果", t2.dt,NULL
            )) AS non_rebuy_cat1_cdta6d_cnt_30d -- "近30日内售后七日复购未复购次数" BIGINT
        FROM dim_dates t0
        JOIN temp t1
            ON t1.dt BETWEEN DATEADD(DATE(t0.dt), - 30, "dd")
                    AND DATEADD(DATE(t0.dt),  - 1, "dd")
        LEFT JOIN css_rebuy t2
            ON t2.dt = t1.dt
            AND t2.mall_id = t1.mall_id
            AND t2.merchant_id = t1.merchant_id
            AND t2.category_level1_id = t1.category_level1_id
            AND t2.category_level4_id = t1.category_level4_id
            AND t2.customer_store_id = t1.customer_store_id
        WHERE t1.mall_id = 871
        GROUP BY t0.dt
            ,t1.merchant_id -- "商家ID" BIGINT
            ,t1.category_level1_id -- "一级类目ID" BIGINT
            ,t1.category_level4_id -- "四级类目ID" BIGINT
            ,t1.customer_store_id -- "店铺ID" BIGINT
            ,t1.mall_id -- "商城ID" BIGINT
    ) t1
    LEFT JOIN datawarehouse_max.dim_merchant_daily_full t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") -6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.merchant_id = t1.merchant_id
    GROUP BY  t1.dt
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.customer_store_id -- "店铺ID" BIGINT
        ,t1.mall_id -- "商城ID" BIGINT
)

,base AS(
    SELECT/*+ MAPJOIN(t0) */
        t0.dt
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.customer_store_id -- "店铺ID" BIGINT
        ,t1.mall_id -- "商城ID" BIGINT
        ,SUM(t1.delivered_goods_amt) AS delivered_goods_amt_30d -- "近30天货值" DECIMAL(15,2)
        ,SUM(t1.ordered_goods_num) AS ordered_goods_num_30d -- "近30天下单件数" BIGINT
        ,SUM(t1.refund_amt_by_asdt) AS refund_amt_by_asdt_30d -- "近30天售后赔付金额" DECIMAL(15,2)
        ,COUNT(DISTINCT IF(t1.ordered_goods_num>0, t1.dt, NULL)) AS ordered_cnt_30d -- "近30天下单次数" BIGINT
        ,COUNT(DISTINCT IF(t1.after_sale_num_by_asdt>0, t1.dt, NULL)) AS applied_after_sale_cnt_30d -- "近30天申请售后次数" BIGINT
        ,COUNT(DISTINCT IF(t1.after_sale_num_by_asdt>0, CONCAT_WS("-", t1.dt, t1.merchant_id), NULL)) AS applied_after_sale_cnt_30d_by_mct -- "近30天申请售后不同商家次数" BIGINT
        ,COLLECT_SET(IF(t1.ordered_goods_num>0, t1.merchant_id, NULL)) AS ordered_merchant_ids
        ,COUNT(DISTINCT IF(
            t1.dt BETWEEN DATEADD(DATE(t0.dt), - 30, "dd")
                AND DATEADD(DATE(t0.dt), - 7, "dd")
            ,t1.dt, NULL
        )) AS ordered_cnt_m30tm7d -- "下单次数m30tm7d" BIGINT
        ,COUNT(DISTINCT IF(
            t1.dt BETWEEN DATEADD(DATE(t0.dt), - 6, "dd")
                AND DATEADD(DATE(t0.dt), - 0, "dd")
            ,t1.dt, NULL
        )) AS ordered_cnt_m6tcd -- "下单次数m6dtcd" BIGINT
    FROM dim_dates t0
    JOIN temp t1
        ON t1.dt BETWEEN DATEADD(DATE(t0.dt), - 30, "dd")
                AND DATEADD(DATE(t0.dt), - 1, "dd")
    LEFT JOIN css_rebuy t2
        ON t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.merchant_id = t1.merchant_id
        AND t2.category_level1_id = t1.category_level1_id
        AND t2.category_level4_id = t1.category_level4_id
        AND t2.customer_store_id = t1.customer_store_id
    WHERE t1.mall_id = 871
    GROUP BY t0.dt
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.customer_store_id -- "店铺ID" BIGINT
        ,t1.mall_id -- "商城ID" BIGINT
)



,onshelved_mct AS(
    SELECT/*+ MAPJOIN(t0) */
        t0.dt
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        
        ,t1.mall_id -- "商城ID" BIGINT
        ,COLLECT_SET(IF(t1.is_up_today>0, t1.merchant_id, NULL)) AS onshelved_merchant_ids
        
    FROM dim_dates t0
    JOIN dim_sku t1
        ON t1.dt BETWEEN DATEADD(DATE(t0.dt),  - 30, "dd")
                AND DATEADD(DATE(t0.dt), - 1, "dd")
    WHERE t1.mall_id = 871
    GROUP BY t0.dt
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.mall_id -- "商城ID" BIGINT
        
)


,result AS(
    SELECT
        t1.mall_id -- "商城ID" BIGINT
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t4.category_level1_name -- "一级类目名称" STRING
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t4.category_level4_name -- "四级类目名称" STRING
        ,t1.customer_store_id -- "店铺ID" BIGINT
        ,t5.customer_store_name -- "店铺名称" STRING
        ,t5.store_type -- "门店类型" STRING
        ,t5.province_id -- "省ID" BIGINT
        ,t5.province_name -- "省名称" STRING
        ,t5.city_id -- "市ID" BIGINT
        ,t5.city_name -- "市名称" STRING
        ,t5.county_id -- "区县ID" BIGINT
        ,t5.county_name -- "区县名称" STRING
        ,t5.grid_id -- "网格ID" BIGINT
        ,t5.grid_name -- "网格名称" STRING
        ,t5.operation_type_county -- "区县运营类型" STRING
        ,t5.bd_id -- "BDID" BIGINT
        ,t5.bd_name -- "BD姓名" STRING
        ,t1.delivered_goods_amt_30d -- "近30天货值" DECIMAL(15,2)
        ,t1.ordered_goods_num_30d -- "近30天下单件数" BIGINT
        ,t1.refund_amt_by_asdt_30d -- "近30天售后赔付金额" DECIMAL(15,2)
        ,t1.ordered_cnt_30d -- "近30天下单次数" BIGINT
        ,t1.applied_after_sale_cnt_30d -- "近30天申请售后次数" BIGINT
        ,t1.applied_after_sale_cnt_30d_by_mct -- "近30天申请售后不同商家次数" BIGINT
        ,t2.after_sale_info_mct_30d -- "近30天商家售后表现信息" STRING
        ,SIZE(t3.onshelved_merchant_ids) AS onselved_mct_num_30d -- "近30天上架商品商家数量" BIGINT
        ,SIZE(t1.ordered_merchant_ids) AS ordered_mct_num_30d -- "近30天下单商家数量" BIGINT"
        ,ROUND(
            t1.applied_after_sale_cnt_30d / t1.ordered_cnt_30d, 6
        ) AS applied_after_sale_ratio_ordered -- "近30天申请售后次数占下单频次比" DECIMAL(10,6)
        ,t1.dt
    FROM base t1
    LEFT JOIN base_mct t2
        ON t2.dt = t1.dt
        AND t2.category_level1_id = t1.category_level1_id
        AND t2.category_level4_id = t1.category_level4_id
        AND t2.customer_store_id = t1.customer_store_id
        AND t2.mall_id = t1.mall_id
    LEFT JOIN onshelved_mct t3
        ON t3.dt = t1.dt
        AND t3.category_level1_id = t1.category_level1_id
        AND t3.category_level4_id = t1.category_level4_id
        AND t3.mall_id = t1.mall_id
    LEFT JOIN datawarehouse_max.dim_category_daily_full  t4
        ON t4.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t4.dt = t1.dt
        AND t4.back_category_id = t1.category_level4_id
        AND t4.source_type = "OLD"

    LEFT JOIN dim_store t5
        ON t5.dt = t1.dt
        AND t5.customer_store_id = t1.customer_store_id
        AND t5.mall_id = t1.mall_id

)


INSERT OVERWRITE TABLE changsha_cat4_store_top_daily_asc PARTITION(dt)

SELECT
	t1.mall_id -- "商城ID" BIGINT
	,t1.category_level1_id -- "一级类目ID" BIGINT
	,t1.category_level1_name -- "一级类目名称" STRING
	,t1.category_level4_id -- "四级类目ID" BIGINT
	,t1.category_level4_name -- "四级类目名称" STRING
	,t1.customer_store_id -- "店铺ID" BIGINT
	,t1.customer_store_name -- "店铺名称" STRING
    ,t1.store_type -- "门店类型" STRING
	,t1.province_id -- "省ID" BIGINT
	,t1.province_name -- "省名称" STRING
	,t1.city_id -- "市ID" BIGINT
	,t1.city_name -- "市名称" STRING
	,t1.county_id -- "区县ID" BIGINT
	,t1.county_name -- "区县名称" STRING
    ,t1.operation_type_county -- "区县运营类型" STRING
    ,t1.grid_id -- "网格ID" BIGINT
    ,t1.grid_name -- "网格名称" STRING
    ,t1.bd_id -- "BDID" BIGINT
    ,t1.bd_name -- "BD姓名" STRING
	,t1.delivered_goods_amt_30d -- "近30天货值" DECIMAL(15,2)
	,t1.ordered_goods_num_30d -- "近30天下单件数" BIGINT
	,t1.refund_amt_by_asdt_30d -- "近30天售后赔付金额" DECIMAL(15,2)
	,t1.ordered_cnt_30d -- "近30天下单次数" BIGINT
	,t1.applied_after_sale_cnt_30d -- "近30天申请售后次数" BIGINT
	,t1.applied_after_sale_cnt_30d_by_mct -- "近30天申请售后不同商家次数" BIGINT
	,t1.after_sale_info_mct_30d -- "近30天商家售后表现信息" STRING
	,t1.onselved_mct_num_30d -- "近30天上架商品商家数量" BIGINT
	,t1.ordered_mct_num_30d -- "近30天下单商家数量" BIGINT"
	,t1.applied_after_sale_ratio_ordered -- "近30天申请售后次数占下单频次比" DECIMAL(10,6)
    ,DENSE_RANK()OVER(
        PARTITION BY t1.dt, t1.mall_id, t1.category_level1_id, t1.category_level4_id
            ORDER BY t1.delivered_goods_amt_30d DESC
    ) AS store_rnk -- "门店排序" BIGINT
    ,"GoodsAmtTop30" AS rnk_type -- "排序类型" STRING
	,t1.dt

FROM result t1
QUALIFY store_rnk <= 30

UNION ALL

SELECT
	t1.mall_id -- "商城ID" BIGINT
	,t1.category_level1_id -- "一级类目ID" BIGINT
	,t1.category_level1_name -- "一级类目名称" STRING
	,t1.category_level4_id -- "四级类目ID" BIGINT
	,t1.category_level4_name -- "四级类目名称" STRING
	,t1.customer_store_id -- "店铺ID" BIGINT
	,t1.customer_store_name -- "店铺名称" STRING
    ,t1.store_type -- "门店类型" STRING
	,t1.province_id -- "省ID" BIGINT
	,t1.province_name -- "省名称" STRING
	,t1.city_id -- "市ID" BIGINT
	,t1.city_name -- "市名称" STRING
	,t1.county_id -- "区县ID" BIGINT
	,t1.county_name -- "区县名称" STRING
    ,t1.operation_type_county -- "区县运营类型" STRING
    ,t1.grid_id -- "网格ID" BIGINT
    ,t1.grid_name -- "网格名称" STRING
    ,t1.bd_id -- "BDID" BIGINT
    ,t1.bd_name -- "BD姓名" STRING
	,t1.delivered_goods_amt_30d -- "近30天货值" DECIMAL(15,2)
	,t1.ordered_goods_num_30d -- "近30天下单件数" BIGINT
	,t1.refund_amt_by_asdt_30d -- "近30天售后赔付金额" DECIMAL(15,2)
	,t1.ordered_cnt_30d -- "近30天下单次数" BIGINT
	,t1.applied_after_sale_cnt_30d -- "近30天申请售后次数" BIGINT
	,t1.applied_after_sale_cnt_30d_by_mct -- "近30天申请售后不同商家次数" BIGINT
	,t1.after_sale_info_mct_30d -- "近30天商家售后表现信息" STRING
	,t1.onselved_mct_num_30d -- "近30天上架商品商家数量" BIGINT
	,t1.ordered_mct_num_30d -- "近30天下单商家数量" BIGINT"
	,t1.applied_after_sale_ratio_ordered -- "近30天申请售后次数占下单频次比" DECIMAL(10,6)
    ,DENSE_RANK()OVER(
        PARTITION BY t1.dt, t1.mall_id, t1.category_level1_id, t1.category_level4_id
            ORDER BY t1.refund_amt_by_asdt_30d DESC
    ) AS store_rnk -- "门店排序" BIGINT
    ,"RefundAmt30" AS rnk_type -- "排序类型" STRING
	,t1.dt

FROM result t1
QUALIFY store_rnk <= 30




UNION ALL

SELECT
	t1.mall_id -- "商城ID" BIGINT
	,t1.category_level1_id -- "一级类目ID" BIGINT
	,t1.category_level1_name -- "一级类目名称" STRING
	,t1.category_level4_id -- "四级类目ID" BIGINT
	,t1.category_level4_name -- "四级类目名称" STRING
	,t1.customer_store_id -- "店铺ID" BIGINT
	,t1.customer_store_name -- "店铺名称" STRING
    ,t1.store_type -- "门店类型" STRING
	,t1.province_id -- "省ID" BIGINT
	,t1.province_name -- "省名称" STRING
	,t1.city_id -- "市ID" BIGINT
	,t1.city_name -- "市名称" STRING
	,t1.county_id -- "区县ID" BIGINT
	,t1.county_name -- "区县名称" STRING
    ,t1.operation_type_county -- "区县运营类型" STRING
    ,t1.grid_id -- "网格ID" BIGINT
    ,t1.grid_name -- "网格名称" STRING
    ,t1.bd_id -- "BDID" BIGINT
    ,t1.bd_name -- "BD姓名" STRING
	,t1.delivered_goods_amt_30d -- "近30天货值" DECIMAL(15,2)
	,t1.ordered_goods_num_30d -- "近30天下单件数" BIGINT
	,t1.refund_amt_by_asdt_30d -- "近30天售后赔付金额" DECIMAL(15,2)
	,t1.ordered_cnt_30d -- "近30天下单次数" BIGINT
	,t1.applied_after_sale_cnt_30d -- "近30天申请售后次数" BIGINT
	,t1.applied_after_sale_cnt_30d_by_mct -- "近30天申请售后不同商家次数" BIGINT
	,t1.after_sale_info_mct_30d -- "近30天商家售后表现信息" STRING
	,t1.onselved_mct_num_30d -- "近30天上架商品商家数量" BIGINT
	,t1.ordered_mct_num_30d -- "近30天下单商家数量" BIGINT"
	,t1.applied_after_sale_ratio_ordered -- "近30天申请售后次数占下单频次比" DECIMAL(10,6)
    ,DENSE_RANK()OVER(
        PARTITION BY t1.dt, t1.mall_id, t1.category_level1_id, t1.category_level4_id
            ORDER BY t1.applied_after_sale_ratio_ordered DESC
    ) AS store_rnk -- "门店排序" BIGINT
    ,"AppliedAfterSaleRatio30" AS rnk_type -- "排序类型" STRING
	,t1.dt

FROM result t1
QUALIFY store_rnk <= 30
;
