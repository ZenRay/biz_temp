/*
四级类目统计
*/



-- DROP TABLE IF EXISTS changsha_cat4_stat_daily_asc;
-- CREATE TABLE IF NOT EXISTS changsha_cat4_stat_daily_asc (
-- mall_id STRING COMMENT "商城id"
-- 	,category_level1_id BIGINT COMMENT "一级类目id"
-- 	,category_level1_name STRING COMMENT "一级类目名称"
-- 	,category_level4_id BIGINT COMMENT "四级类目id"
-- 	,category_level4_name STRING COMMENT "四级类目名称"
--     ,onshelved_mct_num  BIGINT COMMENT "上架商品商家数量"
--     ,onshelved_mct_num_full_mct  BIGINT COMMENT "上架商品商家数量"
--     ,delivered_goods_amt_full_mct  DECIMAL(10,2) COMMENT "全品类商家货值"
-- 	,exposed_store_num BIGINT COMMENT "曝光店铺数"
-- 	,clicked_store_num BIGINT COMMENT "点击店铺数"
-- 	,added_store_num BIGINT COMMENT "加购店铺数"
-- 	,ordered_store_num BIGINT COMMENT "下单店铺数"
-- 	,ordered_goods_num BIGINT COMMENT "下单件数"
-- 	,delivered_goods_amt DECIMAL(10,2) COMMENT "货值"
-- 	,delivered_goods_num BIGINT COMMENT "件数"

-- 	,commission_amt DECIMAL(10,2) COMMENT "平台抽佣金额"
-- 	,subsidy_amt_plat DECIMAL(10,2) COMMENT "平台补贴费用"
        
-- 	,refund_amt_by_asdt_plat DECIMAL(10,2) COMMENT "平台承担售后赔付金额售后提交日"
-- 	,applied_store_num_by_asdt BIGINT COMMENT "提交日售后门店数"
-- 	,refund_amt DECIMAL(10,2) COMMENT "售后赔付金额"
-- 	,applied_after_sale_goods_num BIGINT COMMENT "售后商品数量"
    
-- 	,delivered_goods_amt_pg DECIMAL(10,2) COMMENT "件单价"
-- 	,ordered_goods_num_ps DECIMAL(10,1) COMMENT "客均件数"
-- 	,delivered_goods_amt_ps DECIMAL(10,2) COMMENT "客均货值"

-- 	,shared_links_cnt BIGINT COMMENT "BD分享次数"
-- 	,shared_links_store_num BIGINT COMMENT "BD分享触达店铺数"
-- 	,exposed_store_num_by_share_links BIGINT COMMENT "BD分享曝光店铺数"
-- 	,clicked_store_num_by_share_links BIGINT COMMENT "点击BD分享链接店铺数"
-- 	,ordered_store_num_by_share_links BIGINT COMMENT "有BD分享下单的店铺数"

-- 	,exposed_store_num_old_store BIGINT COMMENT "老客户曝光店铺数"
-- 	,exposed_store_num_loss_store BIGINT COMMENT "召回客户曝光店铺数"
-- 	,exposed_store_num_new_store BIGINT COMMENT "新客户曝光店铺数"
-- 	,ordered_store_num_old_store BIGINT COMMENT "老客户下单店铺数"
-- 	,ordered_store_num_loss_store BIGINT COMMENT "召回客户下单店铺数"
-- 	,ordered_store_num_new_store BIGINT COMMENT "新客户下单店铺数"
-- 	,onshelved_mall_num BIGINT COMMENT "在售中心仓数"


-- 	,store_num_by_ordered_30d_info STRING COMMENT "近30日内不同下单频次门店数详情"
-- 	,logon_store_num_by_ordered_30d_info STRING COMMENT "近30日内不同下单频次门店登陆门店数详情"
-- 	,exposed_store_num_by_ordered_30d_info STRING COMMENT "近30日内不同下单频次曝光门店数数详情"
-- 	,ordered_store_num_by_ordered_30d_info STRING COMMENT "近30日内不同下单频次下单门店数详情"

-- 	,store_num_by_exposed_30d_info STRING COMMENT "近30日内不同曝光频次门店数详情"
-- 	,logon_store_num_by_exposed_30d_info STRING COMMENT "近30日内不同曝光频次门店登陆门店数详情"
-- 	,exposed_store_num_by_exposed_30d_info STRING COMMENT "近30日内不同曝光频次曝光门店数数详情"
-- 	,ordered_store_num_by_exposed_30d_info STRING COMMENT "近30日内不同曝光频次下单门店数详情"

-- 	,exposed2ordered_store_ratio DECIMAL(10,6) COMMENT "曝光转化率"
-- 	,ordered_store_ratio_by_cat1 DECIMAL(10,6) COMMENT "日活覆盖率"
-- 	,ordered_store_ratio_by_cat1_rnk BIGINT COMMENT "日活覆盖率排名"
        
-- 	,exposed_store_num_desc_rnk_by_mall BIGINT COMMENT "曝光门店数排名"
-- 	,exposed_store_ratio_by_mall DECIMAL(10,6) COMMENT "跨仓曝光门店数占商城比例"
-- 	,exposed_store_ratio_by_mall_desc_rnk BIGINT COMMENT "跨仓曝光门店数占商城比例倒排排名"
-- )PARTITIONED BY 
-- (
--     dt STRING COMMENT "日期"
-- )
-- TBLPROPERTIES('comment'='四级类目统计');




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
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.merchant_id
        ,t1.merchant_name
        ,CASE
            WHEN
                INSTR(t1.merchant_name, "老顽童") + INSTR(t1.merchant_name, "阿玲") > 0
                    AND t1.mall_id  =871
            THEN "全品类商家"
            WHEN t1.mall_id=871 THEN "商家"
            ELSE t1.merchant_type_desc
        END AS merchant_type
        ,t1.is_up_today
    FROM datawarehouse_max.dim_goods_daily_full t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
)

,dim_store AS(
    SELECT
        t1.dt
        ,t1.customer_store_id
        ,t1.mall_id
        ,t1.is_login
    FROM datawarehouse_max.dws_store_central_warehouse_base_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
)

,subsides AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t3.category_level1_id
        ,t3.category_level4_id

        -- 优惠券
        ,SUM(
            NVL(t1.platform_market_amt_full_reduce_coupon, 0) + NVL(t1.platform_market_amt_single_goods_coupon,0)
        ) AS plat_coupon_market_fee
        -- 平台补贴
        ,SUM(t2.platform_subsidy_amount) AS plat_subsidy_amount
        ,SUM(IF(
            INSTR(t3.merchant_name, "老顽童") + INSTR(t3.merchant_name, "阿玲")>0, t1.deliveried_goods_amt, 0
        )) AS delivered_goods_amt_full_mct
    FROM datawarehouse_max.dwt_order_order_item_daily_asc t1
    LEFT JOIN datawarehouse_max.dwt_order_clearing_asc t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.order_item_id = t1.order_item_id
    LEFT JOIN dim_sku t3
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
        ,t3.category_level4_id
)


,css AS (
    SELECT
        t1.dt
        ,t2.category_level1_id
        ,t2.category_level4_id
        ,t1.mall_id
            
        ,SUM(NVL(t1.company_bear_refund_amt, 0)) AS refund_amt_by_asdt_plat -- '平台承担赔付金额
        ,COUNT(DISTINCT t1.customer_store_id) AS applied_store_num_by_asdt -- "售后门店数量" BIGINT
    FROM datawarehouse_max.dwt_order_after_sale_daily_asc t1
    LEFT JOIN dim_sku t2
        ON t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.sku_id = t1.sku_id
    
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
        AND t1.status != "CANCEL"
    GROUP BY t1.dt
        ,t2.category_level1_id
        ,t2.category_level4_id
        ,t1.mall_id

)




,recommends_stat AS(
    SELECT
        t1.dt -- `日期`
        ,t1.mall_id -- `商城ID`
        ,t3.category_level1_id
        ,t3.category_level4_id
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
    GROUP BY t1.dt -- `日期`
        ,t1.mall_id -- `商城ID`
        ,t3.category_level1_id
        ,t3.category_level4_id
)


,store_stat AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.customer_store_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,MAX(NVL(t2.is_login,0)) AS is_login
        ,CASE
            WHEN 
                NVL(MAX(t1.ordered_days_30d), 0) = 0 
            THEN "0次"
            WHEN 
                NVL(MAX(t1.ordered_days_30d), 0) = 1
            THEN "1次"
            WHEN 
                NVL(MAX(t1.ordered_days_30d), 0) = 2
            THEN "2次"
            WHEN 
                NVL(MAX(t1.ordered_days_30d), 0) = 3
            THEN "3次"
            WHEN 
                NVL(MAX(t1.ordered_days_30d), 0) = 4
            THEN "4次"
            WHEN 
                NVL(MAX(t1.ordered_days_30d), 0) = 5
            THEN "5次"
            WHEN 
                NVL(MAX(t1.ordered_days_30d), 0) = 6
            THEN "6次"
            WHEN 
                NVL(MAX(t1.ordered_days_30d), 0) >=7
            THEN "7+次"
        END  AS ordered_days_30d
                ,CASE
            WHEN 
                NVL(MAX(t1.exposed_days_30d), 0) = 0 
            THEN "0次"
            WHEN 
                NVL(MAX(t1.exposed_days_30d), 0) = 1
            THEN "1次"
            WHEN 
                NVL(MAX(t1.exposed_days_30d), 0) = 2
            THEN "2次"
            WHEN 
                NVL(MAX(t1.exposed_days_30d), 0) = 3
            THEN "3次"
            WHEN 
                NVL(MAX(t1.exposed_days_30d), 0) = 4
            THEN "4次"
            WHEN 
                NVL(MAX(t1.exposed_days_30d), 0) = 5
            THEN "5次"
            WHEN 
                NVL(MAX(t1.exposed_days_30d), 0) = 6
            THEN "6次"
            WHEN 
                NVL(MAX(t1.exposed_days_30d), 0) >=7
            THEN "7+次"
        END  AS exposed_days_30d
        ,MAX(t1.exposed_cnt) AS exposed_cnt
        ,MAX(t1.ordered_goods_num) AS ordered_goods_num
    FROM(
        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.customer_store_id
            ,t1.category_level1_id
            ,t1.category_level4_id

            ,t1.ordered_days_30d
            ,t1.exposed_days_30d
            ,NULL AS exposed_cnt
            ,NULL AS ordered_goods_num
        FROM datawarehouse_max.dws_store_mall_store_category_level4_feature_daily_asc t1
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND t1.mall_id = 871
            AND ISNOTNULL(t1.customer_store_id) AND ISNOTNULL(t1.category_level4_id)
            AND NVL(t1.ordered_days_30d,0) + NVL(t1.exposed_days_30d, 0) > 0

        UNION ALL

        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.customer_store_id
            ,t1.category_level1_id
            ,t1.category_level4_id

            ,0 AS ordered_days_30d
            ,0 AS exposed_day_30d
            ,t1.exposed_cnt
            ,t1.ordered_goods_num
        FROM datawarehouse_max.dws_store_mall_store_category_level4_base_daily_asc t1
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND t1.mall_id = 871

    ) t1
    LEFT JOIN dim_store t2
        ON t2.dt = t1.dt
        AND t2.customer_store_id = t1.customer_store_id
        AND t2.mall_id = t1.mall_id
    GROUP BY t1.dt
        ,t1.mall_id
        ,t1.customer_store_id
        ,t1.category_level1_id
        ,t1.category_level4_id
)

,ordered_store AS(
    SELECT
        t1.dt
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.mall_id
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.ordered_days_30d || '":' || t1.store_num
            ) ||
        '}' AS store_num_by_ordered_30d_info
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.ordered_days_30d || '":' || t1.logon_store_num
            ) ||
        '}' AS logon_store_num_by_ordered_30d_info
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.ordered_days_30d || '":' || t1.exposed_store_num
            ) ||
        '}' AS exposed_store_num_by_ordered_30d_info
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.ordered_days_30d || '":' || t1.ordered_store_num
            ) ||
        '}' AS ordered_store_num_by_ordered_30d_info
    FROM(
        SELECT
            t1.dt
            ,t1.category_level1_id
            ,t1.category_level4_id
            ,t1.mall_id
            ,t1.ordered_days_30d
            ,COUNT(DISTINCT t1.customer_store_id) AS store_num
            ,COUNT(DISTINCT IF(
                t1.is_login >0, t1.customer_store_id, NULL
            )) AS logon_store_num
            ,COUNT(DISTINCT IF(
                NVL(t1.exposed_cnt, 0) > 0 AND t1.is_login > 0, t1.customer_store_id, NULL
            )) AS exposed_store_num
            ,COUNT(DISTINCT IF(
                t1.ordered_goods_num > 0, t1.customer_store_id, NULL
            )) AS ordered_store_num
        FROM store_stat t1
        
        GROUP BY t1.dt
            ,t1.category_level1_id
            ,t1.category_level4_id
            ,t1.mall_id
            ,t1.ordered_days_30d
    ) t1

    GROUP BY t1.dt
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.mall_id
)


,exposed_store AS(
    SELECT
        t1.dt
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.mall_id
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.exposed_days_30d || '":' || t1.store_num
            ) ||
        '}' AS store_num_by_exposed_30d_info
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.exposed_days_30d || '":' || t1.logon_store_num
            ) ||
        '}' AS logon_store_num_by_exposed_30d_info
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.exposed_days_30d || '":' || t1.exposed_store_num
            ) ||
        '}' AS exposed_store_num_by_exposed_30d_info
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.exposed_days_30d || '":' || t1.ordered_store_num
            ) ||
        '}' AS ordered_store_num_by_exposed_30d_info
    FROM(
        SELECT
            t1.dt
            ,t1.category_level1_id
            ,t1.category_level4_id
            ,t1.mall_id
            ,t1.exposed_days_30d
            ,COUNT(DISTINCT t1.customer_store_id) AS store_num
            ,COUNT(DISTINCT IF(
                t1.is_login >0, t1.customer_store_id, NULL
            )) AS logon_store_num
            ,COUNT(DISTINCT IF(
                NVL(t1.exposed_cnt, 0) > 0 AND t1.is_login > 0, t1.customer_store_id, NULL
            )) AS exposed_store_num
            ,COUNT(DISTINCT IF(
                t1.ordered_goods_num > 0, t1.customer_store_id, NULL
            )) AS ordered_store_num
        FROM store_stat t1
        
        GROUP BY t1.dt
            ,t1.category_level1_id
            ,t1.category_level4_id
            ,t1.mall_id
            ,t1.exposed_days_30d
    ) t1

    GROUP BY t1.dt
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.mall_id
)


, base AS(
    SELECT
        t1.dt -- "日期" STRING
        ,t1.mall_id -- "商城id" STRING
        ,t1.category_level1_id -- "一级类目id" BIGINT
        ,t1.category_level1_name -- "一级类目名称" STRING
        ,t1.category_level4_id -- "四级类目id" BIGINT
        ,t1.category_level4_name -- "四级类目名称" STRING
        ,t1.exposed_store_num -- "曝光店铺数" BIGINT
        ,t1.clicked_store_num -- "点击店铺数" BIGINT
        ,t1.added_store_num -- "加购店铺数" BIGINT
        ,t1.ordered_store_num -- "下单店铺数" BIGINT
        ,t1.ordered_goods_num -- "下单件数" BIGINT
        ,t1.delivered_goods_amt -- "货值" DECIMAL(10,2)
        ,t1.delivered_goods_num -- "件数" BIGINT

        ,t1.commission_amt -- "平台抽佣金额" DECIMAL(10,2)
        ,ROUND(
            NVL(t4.plat_coupon_market_fee, 0) + NVL(t4.plat_subsidy_amount, 0), 2
        ) AS subsidy_amt_plat -- "平台补贴费用" DECIMAL(10,2)
        ,t4.delivered_goods_amt_full_mct -- "全品类商家货值" DECIMAL(10,2)
        ,NVL(t5.refund_amt_by_asdt_plat, 0) AS refund_amt_by_asdt_plat -- "平台承担售后赔付金额售后提交日" DECIMAL(10,2)
        ,t5.applied_store_num_by_asdt -- "提交日售后门店数" BIGINT
        ,t1.final_refund_amt_order_time AS refund_amt -- "售后赔付金额" DECIMAL(10,2)
        ,t1.after_sale_num_order_time AS applied_after_sale_goods_num -- "售后商品数量" BIGINT

        ,ROUND(
            t1.delivered_goods_amt / t1.ordered_goods_num, 2
        ) AS delivered_goods_amt_pg -- "件单价" DECIMAL(10,2)
        ,ROUND(
            t1.ordered_goods_num / t1.ordered_store_num, 1
        ) AS ordered_goods_num_ps -- "客均件数" DECIMAL(10,1)
        ,ROUND(
            t1.delivered_goods_amt / t1.ordered_store_num, 2
        ) AS delivered_goods_amt_ps -- "客均货值" DECIMAL(10,2)

        ,t6.shared_links_cnt -- "BD分享次数" BIGINT
        ,t6.shared_links_store_num -- "BD分享触达店铺数" BIGINT
        ,t6.exposed_store_num_by_share_links -- "BD分享曝光店铺数" BIGINT
        ,t6.clicked_store_num_by_share_links -- "点击BD分享链接店铺数" BIGINT
        ,t6.ordered_store_num_by_share_links -- "有BD分享下单的店铺数" BIGINT

        ,t1.exposed_store_num_old_user AS exposed_store_num_old_store -- "老客户曝光店铺数" BIGINT
        ,t1.exposed_store_num_loss_user AS exposed_store_num_loss_store -- "召回客户曝光店铺数" BIGINT
        ,t1.exposed_store_num_loss_user AS exposed_store_num_new_store -- "新客户曝光店铺数" BIGINT
        ,t1.ordered_store_num_old_user AS ordered_store_num_old_store -- "老客户下单店铺数" BIGINT
        ,t1.ordered_store_num_loss_user AS ordered_store_num_loss_store -- "召回客户下单店铺数" BIGINT
        ,t1.ordered_store_num_loss_user AS ordered_store_num_new_store -- "新客户下单店铺数" BIGINT
        ,COUNT(1)FILTER(WHERE t1.sku_num_onsale>0) OVER(
            PARTITION BY t1.dt, t1.category_level1_id, t1.category_level4_id
        ) AS onshelved_mall_num -- "在售中心仓数" BIGINT
        ,t9.onshelved_mct_num -- "上架商品商家数量" BIGINT
        ,t9.onshelved_mct_num_full_mct -- "全品类商家上架商品商家数量" BIGINT
        

        ,t7.store_num_by_ordered_30d_info -- "近30日内不同下单频次门店数详情" STRING
        ,t7.logon_store_num_by_ordered_30d_info -- "近30日内不同下单频次门店登陆门店数详情" STRING
        ,t7.exposed_store_num_by_ordered_30d_info -- "近30日内不同下单频次曝光门店数数详情" STRING
        ,t7.ordered_store_num_by_ordered_30d_info -- "近30日内不同下单频次下单门店数详情" STRING

        ,t8.store_num_by_exposed_30d_info -- "近30日内不同曝光频次门店数详情" STRING
        ,t8.logon_store_num_by_exposed_30d_info -- "近30日内不同曝光频次门店登陆门店数详情" STRING
        ,t8.exposed_store_num_by_exposed_30d_info -- "近30日内不同曝光频次曝光门店数数详情" STRING
        ,t8.ordered_store_num_by_exposed_30d_info -- "近30日内不同曝光频次下单门店数详情" STRING
        ,ROUND(
            t1.ordered_store_num / t1.exposed_store_num, 6
        ) AS exposed2ordered_store_ratio -- "曝光转化率" DECIMAL(10,6)
        ,ROUND(
            t1.ordered_store_num / t2.ordered_store_num, 6
        ) AS ordered_store_ratio_by_cat1 -- "日活覆盖率" DECIMAL(10,6)
        ,ROW_NUMBER()OVER(
            PARTITION BY t1.dt, t1.category_level1_id, t1.category_level4_id
            ORDER BY t1.ordered_store_num / t2.ordered_store_num DESC
        ) AS ordered_store_ratio_by_cat1_rnk -- "日活覆盖率排名" BIGINT
        
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.mall_id
                ORDER BY t1.exposed_store_num DESC
        ) AS exposed_store_num_desc_rnk_by_mall -- "曝光门店数排名" BIGINT
        ,ROUND(
            t1.exposed_store_num / t3.exposed_store_num, 6
        ) AS exposed_store_ratio_by_mall -- "跨仓曝光门店数占商城比例" DECIMAL(10,6)
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level4_id
            ORDER BY t1.exposed_store_num / t3.exposed_store_num DESC
        ) AS exposed_store_ratio_by_mall_desc_rnk -- "跨仓曝光门店数占商城比例倒排排名" BIGINT
    FROM datawarehouse_max.dws_pub_mall_category_level4_base_daily_asc t1
    JOIN mall t0
        ON t0.mall_id = t1.mall_id
    LEFT JOIN datawarehouse_max.dws_pub_mall_cate1_base_daily_asc  t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.category_level1_id = t1.category_level1_id
    LEFT JOIN datawarehouse_max.dws_pub_mall_base_daily_asc  t3
        ON t3.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t3.dt = t1.dt
        AND t3.mall_id = t1.mall_id

    LEFT JOIN subsides t4
        ON t4.dt = t1.dt
        AND t4.mall_id = t1.mall_id
        AND t4.category_level4_id = t1.category_level4_id
    LEFT JOIN css t5
        ON t5.dt = t1.dt
        AND t5.mall_id = t1.mall_id
        AND t5.category_level4_id = t1.category_level4_id
    
    LEFT JOIN recommends_stat t6
        ON t6.dt = t1.dt
        AND t6.mall_id = t1.mall_id
        AND t6.category_level4_id = t1.category_level4_id
    
    LEFT JOIN ordered_store t7
        ON t7.dt = t1.dt
        AND t7.mall_id = t1.mall_id
        AND t7.category_level4_id = t1.category_level4_id
    LEFT JOIN exposed_store t8
        ON t8.dt = t1.dt
        AND t8.mall_id = t1.mall_id
        AND t8.category_level4_id = t1.category_level4_id
    LEFT JOIN (
        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.category_level4_id
            ,COUNT(DISTINCT t1.merchant_id) AS onshelved_mct_num -- "上架商品商家数量" BIGINT
            ,COUNT(DISTINCT IF(t1.merchant_type="全品类商家", t1.merchant_id, NULL)) AS onshelved_mct_num_full_mct -- "上架商品商家数量" BIGINT
        FROM dim_sku t1
        WHERE t1.is_up_today > 0
        GROUP BY t1.dt
            ,t1.mall_id
            ,t1.category_level4_id
    ) t9
        ON t9.dt = t1.dt
        AND t9.mall_id = t1.mall_id
        AND t9.category_level4_id = t1.category_level4_id
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND ISNOTNULL(t1.category_level4_id)
        
)


INSERT OVERWRITE TABLE changsha_cat4_stat_daily_asc PARTITION(dt)

SELECT
	t1.mall_id -- "商城id" STRING
	,t1.category_level1_id -- "一级类目id" BIGINT
	,t1.category_level1_name -- "一级类目名称" STRING
	,t1.category_level4_id -- "四级类目id" BIGINT
	,t1.category_level4_name -- "四级类目名称" STRING
    ,t1.onshelved_mct_num -- "上架商品商家数量" BIGINT
    ,t1.onshelved_mct_num_full_mct -- "上架商品商家数量" BIGINT
    ,t1.delivered_goods_amt_full_mct -- "全品类商家货值" DECIMAL(10,2)
	,t1.exposed_store_num -- "曝光店铺数" BIGINT
	,t1.clicked_store_num -- "点击店铺数" BIGINT


	,t1.added_store_num -- "加购店铺数" BIGINT
	,t1.ordered_store_num -- "下单店铺数" BIGINT
	,t1.ordered_goods_num -- "下单件数" BIGINT
	,t1.delivered_goods_amt -- "货值" DECIMAL(10,2)
	,t1.delivered_goods_num -- "件数" BIGINT

	,t1.commission_amt -- "平台抽佣金额" DECIMAL(10,2)
	,t1.subsidy_amt_plat -- "平台补贴费用" DECIMAL(10,2)
        
	,t1.refund_amt_by_asdt_plat -- "平台承担售后赔付金额售后提交日" DECIMAL(10,2)
	,t1.applied_store_num_by_asdt -- "提交日售后门店数" BIGINT
	,t1.refund_amt -- "售后赔付金额" DECIMAL(10,2)
	,t1.applied_after_sale_goods_num -- "售后商品数量" BIGINT

	,t1.delivered_goods_amt_pg -- "件单价" DECIMAL(10,2)
	,t1.ordered_goods_num_ps -- "客均件数" DECIMAL(10,1)
	,t1.delivered_goods_amt_ps -- "客均货值" DECIMAL(10,2)

	,t1.shared_links_cnt -- "BD分享次数" BIGINT
	,t1.shared_links_store_num -- "BD分享触达店铺数" BIGINT
	,t1.exposed_store_num_by_share_links -- "BD分享曝光店铺数" BIGINT
	,t1.clicked_store_num_by_share_links -- "点击BD分享链接店铺数" BIGINT
	,t1.ordered_store_num_by_share_links -- "有BD分享下单的店铺数" BIGINT

	,t1.exposed_store_num_old_store -- "老客户曝光店铺数" BIGINT
	,t1.exposed_store_num_loss_store -- "召回客户曝光店铺数" BIGINT
	,t1.exposed_store_num_new_store -- "新客户曝光店铺数" BIGINT
	,t1.ordered_store_num_old_store -- "老客户下单店铺数" BIGINT
	,t1.ordered_store_num_loss_store -- "召回客户下单店铺数" BIGINT
	,t1.ordered_store_num_new_store -- "新客户下单店铺数" BIGINT
	,t1.onshelved_mall_num -- "在售中心仓数" BIGINT


	,t1.store_num_by_ordered_30d_info -- "近30日内不同下单频次门店数详情" STRING
	,t1.logon_store_num_by_ordered_30d_info -- "近30日内不同下单频次门店登陆门店数详情" STRING
	,t1.exposed_store_num_by_ordered_30d_info -- "近30日内不同下单频次曝光门店数数详情" STRING
	,t1.ordered_store_num_by_ordered_30d_info -- "近30日内不同下单频次下单门店数详情" STRING

    ,t1.store_num_by_exposed_30d_info -- "近30日内不同曝光频次门店数详情" STRING
    ,t1.logon_store_num_by_exposed_30d_info -- "近30日内不同曝光频次门店登陆门店数详情" STRING
    ,t1.exposed_store_num_by_exposed_30d_info -- "近30日内不同曝光频次曝光门店数数详情" STRING
    ,t1.ordered_store_num_by_exposed_30d_info -- "近30日内不同曝光频次下单门店数详情" STRING

	,t1.exposed2ordered_store_ratio -- "曝光转化率" DECIMAL(10,6)
	,t1.ordered_store_ratio_by_cat1 -- "日活覆盖率" DECIMAL(10,6)
	,t1.ordered_store_ratio_by_cat1_rnk -- "日活覆盖率排名" BIGINT
        
	,t1.exposed_store_num_desc_rnk_by_mall -- "曝光门店数排名" BIGINT
	,t1.exposed_store_ratio_by_mall -- "跨仓曝光门店数占商城比例" DECIMAL(10,6)
	,t1.exposed_store_ratio_by_mall_desc_rnk -- "跨仓曝光门店数占商城比例倒排排名" BIGINT
    
    
    ,t1.dt
FROM base t1

WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
-- WHERE (
--         -- 长沙仓仓内过滤
--         (
--             t1.mall_id = 871 AND (
--                 t1.exposed_store_num_desc_rnk=1 OR t1.category_level4_name IN ("秋月梨", "蜜桔", "红富士苹果")
--             )
--         )
--         -- 跨仓过滤
--             OR (
--                 t1.exposed_store_ratio_by_mall_desc_rnk =1
--                     AND t1.category_level4_name IN ("秋月梨", "蜜桔", "红富士苹果")
--             )
--     )
-- ;
;