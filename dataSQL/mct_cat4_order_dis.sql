
/*
商家品类下单类型分布情况
*/
DROP TABLE IF EXISTS temp_mct_cat4_info_daily_asc;
CREATE TABLE IF NOT EXISTS temp_mct_cat4_info_daily_asc 

AS 
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
        ,t1.province_id
        ,t1.province_name
        ,t1.city_id
        ,REGEXP_REPLACE(t1.city_name, "\\d", "") AS city_name -- "市名称" STRING
        ,t1.county_id
        ,t1.county_name
        ,t2.is_login
        ,t1.use_status
        ,t2.ordered_days_30d AS ordered_cnt_30d
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



,onshelved_mct_cat4 AS(
    SELECT/*+ MAPJOIN(t0) */
        t0.dt
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.merchant_id -- "商家ID" BIGINT
        ,t1.mall_id -- "商城ID" BIGINT
        ,COUNT(DISTINCT IF(t1.is_up_today>0, t1.dt, NULL)) AS onshelved_cnt_30d -- "近30天上架商品频次" BIGINT
        
    FROM dim_dates t0
    JOIN dim_sku t1
        ON t1.dt BETWEEN DATEADD(DATE(t0.dt), - 30, "dd")
                AND DATEADD(DATE(t0.dt), - 1, "dd")
    WHERE t1.mall_id = 871
    GROUP BY t0.dt
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.merchant_id
        ,t1.mall_id -- "商城ID" BIGINT
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




,base_info AS(
    SELECT/*+ MAPJOIN(t0) */
        t0.dt
        ,t1.merchant_id -- "商家ID" BIGINT
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.customer_store_id -- "店铺ID" BIGINT
        ,t1.mall_id -- "商城ID" BIGINT
        ,SUM(t1.delivered_goods_amt) AS delivered_goods_amt_30d -- "近30天货值" DECIMAL(15,2)
        ,SUM(t1.refund_amt_by_asdt) AS refund_amt_by_asdt_30d -- "近30日自然日赔付金额" DECIMAL(10,2)
        ,COUNT(DISTINCT IF(t1.ordered_goods_num>0, t1.dt, NULL)) AS ordered_cnt_30d -- "近30天下单次数" BIGINT
        ,COUNT(DISTINCT IF(t1.after_sale_num_by_asdt>0, t1.dt, NULL)) AS applied_after_sale_cnt_30d -- "近30天申请售后次数" BIGINT
        ,COUNT(DISTINCT IF(
            t1.dt BETWEEN DATEADD(DATE(t0.dt), - 30, "dd")
                AND DATEADD(DATE(t0.dt), - 8, "dd")
            AND t1.ordered_goods_num>0, t1.dt, NULL
        )) AS ordered_cnt_m30dtm8d -- "下单次数m30dtm8d"
        ,COUNT(DISTINCT IF(
            t1.dt BETWEEN DATEADD(DATE(t0.dt),  - 7, "dd")
                AND DATEADD(DATE(t0.dt), - 1, "dd")
            AND t1.ordered_goods_num>0, t1.dt, NULL
        )) AS ordered_cnt_m7dtm1d -- "下单次数m7dtm1d"
    FROM dim_dates t0
    JOIN temp t1
        ON t1.dt BETWEEN DATEADD(DATE(t0.dt),  - 30, "dd")
                AND DATEADD(DATE(t0.dt), - 1, "dd")
                
    WHERE t1.mall_id = 871
    GROUP BY t0.dt
        ,t1.merchant_id -- "商家ID" BIGINT
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.customer_store_id -- "店铺ID" BIGINT
        ,t1.mall_id -- "商城ID" BIGINT
)




,base AS(
    SELECT
        t1.dt
        ,t1.mall_id -- "商城ID" BIGINT
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.merchant_id -- "商家ID" BIGINT
        ,t1.customer_store_id -- "店铺ID" BIGINT
        ,t1.onshelved_cnt_30d -- "近30天上架商品频次" BIGINT

        ,t2.delivered_goods_amt_30d -- "近30天货值" DECIMAL(15,2)
        ,t2.ordered_cnt_30d -- "近30天下单次数" BIGINT
        ,t2.ordered_cnt_m30dtm8d -- "下单次数m30dtm8d" BIGINT
        ,t2.ordered_cnt_m7dtm1d -- "下单次数m7dtm1d" BIGINT

    FROM(
        SELECT /*+ MAPJOIN(t1) */
            t1.dt
            ,t1.mall_id -- "商城ID" BIGINT
            ,t1.category_level1_id -- "一级类目ID" BIGINT
            ,t1.category_level4_id -- "四级类目ID" BIGINT
            ,t1.merchant_id -- "商家ID" BIGINT
            ,t2.customer_store_id -- "店铺ID" BIGINT
            ,t1.onshelved_cnt_30d -- "近30天上架商品频次" BIGINT
            
        FROM onshelved_mct_cat4 t1
        JOIN dim_store t2
            ON t2.dt = t1.dt
            AND t2.mall_id = t1.mall_id
            AND t2.ordered_cnt_30d > 0

        WHERE t1.onshelved_cnt_30d >0
    ) t1
    LEFT JOIN base_info t2
        ON t2.dt = t1.dt 
        AND t2.mall_id = t1.mall_id
        AND t2.merchant_id = t1.merchant_id
        AND t2.category_level1_id = t1.category_level1_id
        AND t2.category_level4_id = t1.category_level4_id
        AND t2.customer_store_id = t1.customer_store_id
)

,result AS(
    SELECT
        t1.dt
        ,t1.mall_id -- "商城ID" BIGINT
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.merchant_id -- "商家ID" BIGINT
        ,t1.customer_store_id -- "店铺ID" BIGINT
        ,t1.onshelved_cnt_30d -- "近30天上架商品频次" BIGINT

        ,t1.delivered_goods_amt_30d -- "近30天货值" DECIMAL(15,2)
        ,t1.ordered_cnt_30d -- "近30天下单次数" BIGINT
        ,t1.ordered_cnt_m30dtm8d -- "下单次数m30dtm8d" BIGINT
        ,t1.ordered_cnt_m7dtm1d -- "下单次数m7dtm1d" BIGINT

        ,t2.onshelved_mct_ids_30d
        ,t3.ordered_mct_ids_30d
        ,CASE
            WHEN
                ISNULL(t3.ordered_mct_ids_30d)
            THEN "未下单同品类"
            WHEN
                ISNOTNULL(t3.ordered_mct_ids_30d) AND NOT ARRAY_CONTAINS(t3.ordered_mct_ids_30d, t1.merchant_id)
            THEN "下单同品类不同商家"
            WHEN
                ISNOTNULL(t3.ordered_mct_ids_30d) AND ARRAY_CONTAINS(t3.ordered_mct_ids_30d, t1.merchant_id)
            THEN "下单同品类商家"
        END AS ordered_mct_cat4_type -- "下单同商家品类类型" STRING
        ,CASE
            WHEN
                SIZE(t2.onshelved_mct_ids_30d) = SIZE(t3.ordered_mct_ids_30d) AND SIZE(t3.ordered_mct_ids_30d) > 0
            THEN "全覆盖"
            WHEN
                SIZE(t3.ordered_mct_ids_30d) = 1 AND SIZE(t2.onshelved_mct_ids_30d)>1
            THEN "单一覆盖"
            WHEN
                SIZE(t3.ordered_mct_ids_30d) > 1 AND SIZE(t2.onshelved_mct_ids_30d)>1 
                    AND SIZE(t2.onshelved_mct_ids_30d) != SIZE(t3.ordered_mct_ids_30d)
            THEN "部分覆盖"
        END AS ordered_mct_type -- "下单商家覆盖类型" STRING
        ,IF(
            t1.ordered_cnt_m30dtm8d >0 AND NVL(t1.ordered_cnt_m7dtm1d,0) =0, "下单后流失", NULL
        ) AS loss_type -- "下单同商家品类流失类型" STRING

    FROM base t1
    LEFT JOIN (
        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.category_level1_id
            ,t1.category_level4_id
            ,COLLECT_SET(t1.merchant_id) AS onshelved_mct_ids_30d
        FROM onshelved_mct_cat4 t1
        WHERE t1.onshelved_cnt_30d > 0
        GROUP BY t1.dt
            ,t1.mall_id
            ,t1.category_level1_id
            ,t1.category_level4_id
    ) t2
        ON t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.category_level1_id = t1.category_level1_id
        AND t2.category_level4_id = t1.category_level4_id


    LEFT JOIN (
        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.category_level1_id
            ,t1.category_level4_id
            ,t1.customer_store_id
            ,COLLECT_SET(t1.merchant_id) AS ordered_mct_ids_30d
        FROM base_info t1
        WHERE t1.ordered_cnt_30d > 0
        GROUP BY t1.dt
            ,t1.mall_id
            ,t1.category_level1_id
            ,t1.category_level4_id
            ,t1.customer_store_id
    ) t3
        ON t3.dt = t1.dt
        AND t3.mall_id = t1.mall_id
        AND t3.category_level1_id = t1.category_level1_id
        AND t3.category_level4_id = t1.category_level4_id
        AND t3.customer_store_id = t1.customer_store_id

)



SELECT
    t1.mall_id -- "商城ID" BIGINT
    ,t1.merchant_id
    ,t3.merchant_name
    ,t1.category_level1_id -- "一级类目ID" BIGINT
    ,t1.category_level4_id -- "四级类目ID
    ,t2.category_level4_name

    ,SUM(t1.store_num) AS potential_store_num -- "潜在门店数" BIGINT
    ,"["
        || WM_CONCAT(
            ","
            ,"{"
                || '"下单商家品类类型": "' || NVL(t1.ordered_mct_cat4_type, "") || '",'
                || '"同品类下单商家覆盖类型":"' || NVL(t1.ordered_mct_type, "") || '",'
                || '"是否流失": "' || NVL(t1.loss_type, "") || '",'
                || '"门店数量": ' || t1.store_num
            
            ||"}"
        )
    || "]" AS ordered_mct_cat4_type_30d_info -- "近30天同品类下单商家类型详情" STRING
    ,t1.dt
FROM(
    SELECT
        t1.mall_id -- "商城ID" BIGINT
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.merchant_id -- "商家ID" BIGINT
        ,t1.ordered_mct_cat4_type -- "下单同商家品类类型" STRING
        ,t1.ordered_mct_type -- "下单商家覆盖类型" STRING
        ,t1.loss_type -- "下单同商家品类流失类型" STRING
        ,COUNT(DISTINCT t1.customer_store_id) AS store_num -- "门店数量" BIGINT
        ,t1.dt
        
    FROM result t1
    GROUP BY t1.mall_id -- "商城ID" BIGINT
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t1.merchant_id -- "商家ID" BIGINT
        ,t1.ordered_mct_cat4_type -- "下单同商家品类类型" STRING
        ,t1.ordered_mct_type -- "下单商家覆盖类型" STRING
        ,t1.loss_type -- "下单同商家品类流失类型" STRING
        ,t1.dt
) t1
LEFT JOIN datawarehouse_max.dim_category_daily_full t2
    ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") -6 -30, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 1, "dd")
    AND t2.dt = t1.dt
    AND t2.back_category_id= t1.category_level4_id
    AND t2.source_type= "OLD"
LEFT JOIN datawarehouse_max.dim_merchant_daily_full t3
    ON t3.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") -6 -30, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 1, "dd")
    AND t3.dt = t1.dt
    AND t3.merchant_id  = t1.merchant_id
    AND t3.mall_id =t1.mall_id
GROUP BY t1.mall_id -- "商城ID" BIGINT
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目ID" BIGINT
        ,t2.category_level4_name
        ,t1.merchant_id -- "商家ID" BIGINT
        ,t3.merchant_name
        ,t1.dt
;