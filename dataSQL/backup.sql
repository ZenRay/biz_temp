-- ********************************************************************--
-- author:UNKNOWN
-- create time:2025-04-09 15:38:30
-- ********************************************************************--

SET odps.sql.allow.fullscan = true;
SET odps.sql.select.output.showcolumntype = true;
SET odps.sql.type.system.odps2 = true;
SET odps.sql.hive.compatible = true;
SET odps.sql.window.function.newimpl=true;
SET odps.sql.python.version = cp311;

/*
    FIXED: 这个部分是优化配置
*/
-- SET odps.sql.groupby.skewindata=true;









/*
商城统计
*/


-- DROP TABLE IF EXISTS changsha_mall_stat_daily_asc;
-- CREATE TABLE IF NOT EXISTS changsha_mall_stat_daily_asc (
--     mall_id BIGINT COMMENT "商城ID"
--     ,exposed_store_num BIGINT COMMENT "曝光门店数"
--     ,delivered_goods_amt DECIMAL(10,2) COMMENT "货值"
--     ,logon_store_num BIGINT COMMENT "登录店铺数"
-- )PARTITIONED BY 
-- (
--     dt STRING COMMENT "日期"
-- )
-- TBLPROPERTIES('comment'='商城统计');



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

INSERT OVERWRITE TABLE changsha_mall_stat_daily_asc PARTITION(dt)
SELECT
    t1.mall_id -- "商城ID" BIGINT
    ,t1.exposed_store_num -- "曝光门店数" BIGINT
    ,t1.delivered_goods_amt -- "货值" DECIMAL(10,2)
    ,t2.logon_store_num -- "登录店铺数" BIGINT
    ,t1.dt -- "日期" STRING
FROM datawarehouse_max.dws_pub_mall_base_daily_asc t1
JOIN mall t0
    ON t0.mall_id = t1.mall_id

LEFT JOIN (
    SELECT
        t1.dt
        ,t1.mall_id
        ,COUNT(DISTINCT t1.customer_store_id) AS logon_store_num
    FROM datawarehouse_max.dws_store_central_warehouse_base_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.is_login > 0
    GROUP BY t1.dt
        ,t1.mall_id
) t2
    ON t2.dt = t1.dt
    AND t2.mall_id = t1.mall_id
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND ISNOTNULL(t1.mall_id)

;



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
--     ,delivered_goods_amt_with_pmf  DECIMAL(10,2) COMMENT "平台营销费用产生货值"
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

-- 	,ordered_store_num_m7d BIGINT COMMENT "周同比下单店铺数"
-- 	,delivered_goods_amt_m7d DECIMAL(10,2) COMMENT "周同比货值"
-- 	,delivered_goods_num_m7d BIGINT COMMENT "周同比件数"

-- 	,ordered_store_num_m6dtcd BIGINT COMMENT "近七日下单店铺数"
-- 	,delivered_goods_amt_m6dtcd DECIMAL(20,2) COMMENT "近七日货值"
-- 	,delivered_goods_num_m6dtcd BIGINT COMMENT "近七日件数"
-- 	,ordered_cnt_m6dtcd BIGINT COMMENT "近七日交易次数"
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



,dim_dates AS(
    SELECT
        t1.dt
    FROM datawarehouse_max.dim_date_full t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
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
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
)

,dim_store AS(
    SELECT
        t1.dt
        ,t1.customer_store_id
        ,t1.mall_id
        ,t1.is_login
    FROM datawarehouse_max.dws_store_central_warehouse_base_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
)





,cat4_store_base AS(
    SELECT
        t1.dt
        ,t1.mall_id
        
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,IF(
            NVL(t1.exposed_cnt_30d, 0)>=7, "+7次", NVL(t1.exposed_cnt_30d, 0) || "次"
        ) AS exposed_days_30d
        ,COUNT(DISTINCT t1.customer_store_id) AS store_num
        ,COUNT(DISTINCT IF( t3.is_login>0, t1.customer_store_id, NULL)) AS logon_store_num
        ,COUNT(DISTINCT IF(
            t2.exposed_cnt>0, t1.customer_store_id, NULL
        )) AS exposed_store_num
        ,COUNT(DISTINCT IF(
            t2.ordered_goods_num>0, t1.customer_store_id, NULL 
        )) AS ordered_store_num
    FROM(
        SELECT/*+ MAPJOIN(t0) */
            t0.dt
            ,t1.mall_id
            ,t1.customer_store_id
            ,t1.category_level1_id
            ,t1.category_level4_id
            ,COUNT(DISTINCT IF(
                t1.exposed_cnt>0, t1.dt, NULL
            )) AS exposed_cnt_30d
        FROM dim_dates t0
        JOIN datawarehouse_max.dws_store_mall_store_category_level4_base_daily_asc t1
            ON t1.dt BETWEEN DATEADD(TO_DATE(t0.dt), -30, "dd")
                AND DATEADD(TO_DATE(t0.dt), -1, "dd")
        WHERE t0.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")

        GROUP BY t0.dt
            ,t1.mall_id
            ,t1.customer_store_id
            ,t1.category_level1_id
            ,t1.category_level4_id
    ) t1
    LEFT JOIN datawarehouse_max.dws_store_mall_store_category_level4_base_daily_asc t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.dt = t1.dt
        AND t2.customer_store_id = t1.customer_store_id
        AND t2.mall_id = t1.mall_id
        AND t2.category_level1_id = t1.category_level1_id
        AND t2.category_level4_id = t1.category_level4_id
    
    LEFT JOIN dim_store t3
        ON t3.dt = t1.dt
        AND t3.mall_id = t1.mall_id
        AND t3.customer_store_id = t1.customer_store_id
    GROUP BY t1.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,NVL(t1.exposed_cnt_30d, 0)
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
        ,SUM(IF(
            NVL(t1.platform_market_amt_full_reduce_coupon, 0) + NVL(t1.platform_market_amt_single_goods_coupon,0)
                + NVL(t2.platform_subsidy_amount, 0) > 0
            , t1.deliveried_goods_amt, 0
        )) AS delivered_goods_amt_with_pmf
    FROM datawarehouse_max.dwt_order_order_item_daily_asc t1
    LEFT JOIN datawarehouse_max.dwt_order_clearing_asc t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.order_item_id = t1.order_item_id
    LEFT JOIN dim_sku t3
        ON t3.dt = t1.dt
        AND t3.mall_id = t1.mall_id
        AND t3.sku_id = t1.sku_id
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
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
    
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
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

        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND t1.mall_id = 871
        GROUP BY t1.dt -- "日期" STRING
            ,t1.mall_id
            ,t1.sku_id -- "商品ID" BIGINT
            ,t1.customer_store_id -- "店铺ID" BIGINT
    ) t1

    LEFT JOIN datawarehouse_max.dws_store_mall_store_sku_base_daily_asc t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
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
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
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
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
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
                t2.is_login > 0, t1.customer_store_id, NULL
            )) AS logon_store_num
            ,COUNT(DISTINCT IF(
                NVL(t1.exposed_cnt, 0) > 0, t1.customer_store_id, NULL
            )) AS exposed_store_num
            ,COUNT(DISTINCT IF(
                t1.ordered_goods_num > 0, t1.customer_store_id, NULL
            )) AS ordered_store_num
        FROM store_stat t1
        LEFT JOIN dim_store t2
            ON t2.dt = t1.dt
            AND t2.mall_id = t1.mall_id
            AND t2.customer_store_id = t1.customer_store_id
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
    FROM cat4_store_base t1

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
        ,t4.delivered_goods_amt_with_pmf -- "平台营销费用产生货值" DECIMAL(10, 2)
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
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.category_level1_id = t1.category_level1_id
    LEFT JOIN datawarehouse_max.dws_pub_mall_base_daily_asc  t3
        ON t3.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
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
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 14, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND ISNOTNULL(t1.category_level4_id)
        
)


,roll_7d AS(
    SELECT/*+ MAPJOIN(t0) */
        t0.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,SUM(t1.ordered_store_num) AS ordered_store_num_m6dtcd
        ,SUM(t1.delivered_goods_amt) AS delivered_goods_amt_m6dtcd
        ,SUM(t1.delivered_goods_num) AS delivered_goods_num_m6dtcd
        ,COUNT(DISTINCT IF(
            t1.ordered_goods_num>0, t1.dt, NULL
        )) AS ordered_cnt_m6dtcd
    FROM dim_dates t0
    JOIN base t1
        ON t1.dt BETWEEN DATEADD(DATE(t0.dt), -6, "dd")
            AND DATEADD(DATE(t0.dt), 0, "dd")
    WHERE t0.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd") 
    GROUP BY t0.dt
        ,t1.mall_id
        ,t1.category_level1_id
        ,t1.category_level4_id
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
    ,t1.delivered_goods_amt_with_pmf -- "平台营销费用产生货值" DECIMAL(10, 2)
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
    
    ,t2.ordered_store_num AS ordered_store_num_m7d -- "周同比下单店铺数" BIGINT
    ,t2.delivered_goods_amt AS delivered_goods_amt_m7d -- "周同比货值" DECIMAL(10,2)
    ,t2.delivered_goods_num AS delivered_goods_num_m7d -- "周同比件数" BIGINT

    ,t3.ordered_store_num_m6dtcd -- "近七日下单店铺数" BIGINT
    ,t3.delivered_goods_amt_m6dtcd -- "近七日货值" DECIMAL(20,2)
    ,t3.delivered_goods_num_m6dtcd -- "近七日件数" BIGINT
    ,t3.ordered_cnt_m6dtcd -- "近七日交易次数" BIGINT
    ,t1.dt

FROM base t1
LEFT JOIN base t2
    ON t2.dt = DATEADD(DATE(t1.dt), -7, "dd")
    AND t2.mall_id = t1.mall_id
    AND t2.category_level1_id = t1.category_level1_id
    AND t2.category_level4_id = t1.category_level1_id
LEFT JOIN roll_7d t3
    ON t3.dt = t1.dt
    AND t3.mall_id = t1.mall_id
    AND t3.category_level1_id = t1.category_level1_id
    AND t3.category_level4_id = t1.category_level1_id
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")

;





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




/*
商品统计
*/



-- DROP TABLE IF EXISTS changsha_sku_stat_daily_asc;
-- CREATE TABLE IF NOT EXISTS changsha_sku_stat_daily_asc (
-- 	mall_id STRING COMMENT "商城id"
-- 	,sku_id BIGINT COMMENT "商品ID"
-- 	,sku_name STRING COMMENT "商品名称"
-- 	,merchant_id BIGINT COMMENT "商家id"
-- 	,merchant_name STRING COMMENT "商家名称"
-- 	,merchant_type STRING COMMENT "商家类型"
-- 	,updated_video_gap BIGINT COMMENT "最近更新视频天数"
-- 	,updated_main_pic_gap BIGINT COMMENT "最近更新主图图片天数"
-- 	,is_updated_merit BIGINT COMMENT "是否卖点更新"
-- 	,merit STRING COMMENT "商品卖点"
-- 	,origin_place STRING COMMENT "产地"
-- 	,product_class STRING COMMENT "等级"
-- 	,product_spec STRING COMMENT "规格"
-- 	,product_variety STRING COMMENT "品种"
-- 	,brand_name STRING COMMENT "品牌"
-- 	,category_level1_id BIGINT COMMENT "一级类目id"
-- 	,category_level1_name STRING COMMENT "一级类目名称"
-- 	,category_level4_id BIGINT COMMENT "四级类目id"
-- 	,category_level4_name STRING COMMENT "四级类目名称"
--     ,is_onshelved BIGINT COMMENT "当日是否上架"
--     ,is_valid BIGINT COMMENT "是否有效SKU"
--     ,onshelved_cnt_7d BIGINT COMMENT "7日内上架天数"
--     ,commission_rate_conf  DECIMAL(10,4) COMMENT "配置商品抽佣率"
--     ,price_old  DECIMAL(10,2) COMMENT "老客价"
--     ,price_new  DECIMAL(10,2) COMMENT "新客价"
--     ,price_loss  DECIMAL(10,2) COMMENT "召回客户价"
-- 	,exposed_store_num BIGINT COMMENT "曝光店铺数"
-- 	,clicked_store_num BIGINT COMMENT "点击店铺数"
-- 	,added_store_num BIGINT COMMENT "加购店铺数"
-- 	,ordered_store_num BIGINT COMMENT "下单店铺数"
-- 	,ordered_goods_num BIGINT COMMENT "下单件数"
-- 	,delivered_goods_amt DECIMAL(10,2) COMMENT "货值"
-- 	,delivered_goods_num BIGINT COMMENT "件数"

-- 	,commission_amt DECIMAL(10,2) COMMENT "平台抽佣金额"
-- 	,subsidy_amt_plat DECIMAL(10,2) COMMENT "平台补贴费用"
--     ,applied_after_sale_ticket_num_by_asdt BIGINT COMMENT "申请售后单数量"
-- 	,refund_amt_by_asdt_plat DECIMAL(10,2) COMMENT "平台承担售后赔付金额售后提交日"
--     ,applied_after_sale_ticket_num_by_asdt_info STRING COMMENT "售后类型申请数量"
-- 	,applied_store_num_by_asdt BIGINT COMMENT "提交日售后门店数"
-- 	,rebuy_store_num_cdta6d_applied_asdt BIGINT COMMENT "售后七日复购店铺数"
-- 	,rebuy_store_num_cdta2d_applied_asdt BIGINT COMMENT "售后三日复购店铺数"
-- 	,refund_amt DECIMAL(10,2) COMMENT "售后赔付金额"
-- 	,applied_after_sale_goods_num BIGINT COMMENT "售后商品数量"
--     ,refund_amt_by_mct DECIMAL(10,2) COMMENT'商家承担赔付金额'
-- 	,delivered_goods_amt_pg DECIMAL(10,2) COMMENT "件单价"
-- 	,ordered_goods_num_ps DECIMAL(10,1) COMMENT "客均件数"
-- 	,delivered_goods_amt_ps DECIMAL(10,2) COMMENT "客均货值"

-- 	,shared_links_cnt BIGINT COMMENT "BD分享次数"
-- 	,shared_links_store_num BIGINT COMMENT "BD分享触达店铺数"
-- 	,exposed_store_num_by_share_links BIGINT COMMENT "BD分享曝光店铺数"
-- 	,clicked_store_num_by_share_links BIGINT COMMENT "点击BD分享链接店铺数"
-- 	,ordered_store_num_by_share_links BIGINT COMMENT "有BD分享下单的店铺数"

-- 	,pool_num_new_store BIGINT COMMENT "新客户池"
-- 	,pool_num_old_store BIGINT COMMENT "老客户池"
-- 	,pool_num_loss_store BIGINT COMMENT "召回客户池"
--     ,pool_num_incr_ratio_new_store  DECIMAL(10,6) COMMENT "新客户池增长率"
--     ,pool_num_incr_ratio_old_store  DECIMAL(10,6) COMMENT "老客户池增长率"
--     ,pool_num_incr_ratio_loss_store  DECIMAL(10,6) COMMENT "召回客户池增长率"
-- 	,exposed_store_num_old_store BIGINT COMMENT "老客户曝光店铺数"
-- 	,exposed_store_num_loss_store BIGINT COMMENT "召回客户曝光店铺数"
-- 	,exposed_store_num_new_store BIGINT COMMENT "新客户曝光店铺数"
-- 	,ordered_store_num_old_store BIGINT COMMENT "老客户下单店铺数"
-- 	,ordered_store_num_loss_store BIGINT COMMENT "召回客户下单店铺数"
-- 	,ordered_store_num_new_store BIGINT COMMENT "新客户下单店铺数"
-- 	,delivered_goods_amt_new_store_mmf DECIMAL(10,2) COMMENT "商家新客营销费用贡献货值"
-- 	,mct_market_fee_amt_new_store DECIMAL(10,2) COMMENT "商家新客营销费用"
-- 	,delivered_goods_amt_loss_store_mmf DECIMAL(10,2) COMMENT "商家召回客营销费用贡献货值"
-- 	,mct_market_fee_amt_loss_store DECIMAL(10,2) COMMENT "商家召回客户营销费用"
--     ,applied_as_store_num_new_store BIGINT COMMENT "新客户售后门店数"
--     ,rebuy_applied_as_store_num_cdta6d_new_store BIGINT COMMENT "新客户售后近七日复购门店数"
--     ,rebuy_applied_as_store_num_cdta2d_new_store BIGINT COMMENT "新客户售后三日复购门店数"
--     ,applied_as_store_num_loss_store BIGINT COMMENT "召回客户售后门店数"
--     ,rebuy_applied_as_store_num_cdta6d_loss_store BIGINT COMMENT "召回客户售后近七日复购门店数"
--     ,rebuy_applied_as_store_num_cdta2d_loss_store BIGINT COMMENT "召回客户售后三日复购门店数"
--     ,applied_as_store_num_old_store BIGINT COMMENT "老客户售后门店数"
--     ,rebuy_applied_as_store_num_cdta6d_old_store BIGINT COMMENT "老客户售后近七日复购门店数"
--     ,rebuy_applied_as_store_num_cdta2d_old_store BIGINT COMMENT "老客户售后三日复购门店数"
-- 	,invalid_sku_type STRING COMMENT "无效SKU类型"
-- 	,potential_sku_type STRING COMMENT "潜力SKU类型"
        
-- 	,store_num_by_ordered_30d_info STRING COMMENT "近30天不同下单频次店铺数"
-- 	,logon_store_num_by_ordered_30d_info STRING COMMENT "近30天不同下单频次登陆店铺数"
-- 	,exposed_store_num_by_ordered_30d_info STRING COMMENT "近30天不同下单频次曝光店铺数"
-- 	,ordered_store_num_by_ordered_30d_info STRING COMMENT "近30天不同下单频次下单店铺数"
-- 	,store_num_by_exposed_30d_info STRING COMMENT "近30天曝光不同频次门店数"
-- 	,logon_store_num_by_exposed_30d_info STRING COMMENT "近30天曝光不同频次登陆门店数"
-- 	,exposed_store_num_by_exposed_30d_info STRING COMMENT "近30天曝光不同频次曝光门店数"
-- 	,ordered_store_num_by_exposed_30d_info STRING COMMENT "近30天曝光不同频次下单门店数"
--     ,delivered_goods_amt_with_pmf  DECIMAL(10,2) COMMENT "平台营销费用产生货值"
--     ,exposed2ordered_store_ratio_new_store_rnk_by_mall_cat4  BIGINT COMMENT "同品类新客户曝光转化率排名"
--     ,ordered_item_ticket_num  BIGINT COMMENT "明细订单数量"
--     ,attach_detail  STRING COMMENT "附件信息"
-- 	,delivered_goods_amt_desc_rnk_by_mall_cat4 BIGINT COMMENT "同商城同品类货值排名"
-- 	,ordered_store_num_desc_rnk_by_mall_cat4 BIGINT COMMENT "同商城同品类下单店铺数排名"
-- 	,ordered_store_ratio_by_cat1 DECIMAL(10,6) COMMENT "日活覆盖率"
-- 	,ordered_store_ratio_by_cat1_rnk BIGINT COMMENT "日活覆盖率排名"
-- 	,exposed_store_num_desc_rnk_by_mall BIGINT COMMENT "曝光门店数降序排名"
-- 	,exposed2ordered_store_ratio DECIMAL(10,6) COMMENT "曝光转化率"
-- 	,exposed2ordered_store_ratio_desc_rnk_by_mall BIGINT COMMENT "曝光转化率降序排名"
-- 	,exposed2ordered_store_ratio_desc_rnk_by_mall_cat4 BIGINT COMMENT "同品类曝光转化率降序排名"
-- 	,exposed2ordered_store_ratio_desc_rnk_by_mall_cat4_mct BIGINT COMMENT "同品类同商家曝光转化率降序排名"
-- 	,exposed2ordered_store_ratio_desc_rnk_by_cat4 BIGINT COMMENT "跨中心仓同品类曝光转化率降序排名"
-- 	,exposed2ordered_store_ratio_desc_rnk_by_non BIGINT COMMENT "跨中心仓曝光转化率降序排名"

-- 	,exposed_store_ratio_by_mall DECIMAL(10,6) COMMENT "曝光门店数占商城比例"
-- 	,exposed_store_ratio_by_mall_desc_rnk_by_cat4 BIGINT COMMENT "跨仓曝光门店数占商城比例降序排名"
-- 	,exposed_store_ratio_by_cat4 DECIMAL(10,6) COMMENT "曝光门店数占四级类目比例"
-- 	,exposed_store_ratio_by_cat4_desc_rnk_by_mall_cat4 BIGINT COMMENT "同品类曝光门店数占四级类目比例降序排名"
-- 	,exposed_store_ratio_by_cat4_desc_rnk_by_cat4 BIGINT COMMENT "同品类曝光门店数占四级类目比例降序排名"
-- )PARTITIONED BY 
-- (
--     dt STRING COMMENT "日期"
-- )
-- TBLPROPERTIES('comment'='商品统计');




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



,dim_dates AS(
    SELECT
        t1.dt
    FROM datawarehouse_max.dim_date_full t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6 - 7, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
)


, dim_sku_prop AS(
    SELECT
        t1.sku_id 
        ,t1.mall_id 
        ,t1.dt
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.property_name || '": "' || t1.property_value || '"'
            ) ||
        '}' AS property_item_json
        ,MAP_AGG( STRING(t1.property_name) , t1.property_value) AS property_item
        
    FROM(
        SELECT
            t1.goods_id AS sku_id 
            ,t2.company_id AS mall_id 
            ,t1.goods_prop_base_id AS property_id 
            ,t1.property_name
            ,t1.property_value_id 
            ,t1.property_value 
            
            ,t1.create_time 
            ,t1.dt
            ,ROW_NUMBER() OVER(PARTITION BY t1.dt,t1.goods_id, t1.property_name ORDER BY t1.create_time DESC) AS rnk

        FROM datawarehouse_max.ods_demeter_demeter_goods_prop_full t1
        LEFT JOIN datawarehouse_max.ods_demeter_demeter_goods_full t2
            ON DATE(TO_DATE(t2.pt, "yyyyMMdd000000")) BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6 , "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND DATE(TO_DATE(t2.pt, "yyyyMMdd000000")) = t1.dt

            
            AND t2.id = t1.goods_id
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND t2.company_id = 871
            AND INSTR(t1.property_name, "产地") + INSTR(t1.property_name, "品种") 
                + INSTR(t1.property_name, "品牌") + INSTR(t1.property_name, "等级")
                + INSTR(t1.property_name, "规格") + INSTR(t1.property_name, "大小") 
                + INSTR(t1.property_name, "果径") > 0
        QUALIFY rnk = 1
    ) t1
    GROUP BY t1.sku_id 
        ,t1.mall_id 
        ,t1.dt
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

        ,t3.property_item["产地"] AS origin_place -- "产地" STRING
        ,COALESCE(
            NULLIF(t3.property_item["等级"], "无")
            ,t3.property_item["商品等级"] 
        ) AS product_class -- "等级" STRING
        ,COALESCE(
            t3.property_item["规格"]
            ,t3.property_item["单果大小"] 
            ,t3.property_item["果径"] 
            ,t3.property_item["果径【新】"] 
        ) AS product_spec -- "规格" STRING
        
        ,COALESCE(
            t3.property_item["品种"]
            ,t3.property_item["小品种"] 
        ) AS product_variety -- "品种" STRING
        ,COALESCE(
            t3.property_item["品牌"]
            ,t3.property_item["水果品牌"]
        ) AS brand_name -- "品牌" STRING
        ,t3.property_item_json
        ,t1.is_up_today
        ,t1.is_sku_valid
        ,SUM(t1.is_up_today) OVER(PARTITION BY t1.sku_id, t1.mall_id) AS onshelved_cnt_7d -- "7日内上架销售天数" BIGINT
        ,t1.commision_rate AS commission_rate_conf -- "配置商品抽佣率" DECIMAL(10,4)
    FROM datawarehouse_max.dim_goods_daily_full t1
    LEFT JOIN dim_sku_prop t3
        ON t3.dt = t1.dt
        AND t3.skU_id = t1.sku_id
        AND t3.mall_id = t1.mall_id
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6 -1, "dd")
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




, materials_temp AS(
    SELECT
        t1.*
        ,DECODE(
            t1.attach_type
            ,"MAIN_LIST", NVL(t1.media_type, "PICTURE") || "-"
            ,"DETAIL_MAIN", NVL(t1.media_type, "PICTURE") || "-"
            ,"DETAIL_DESC", NVL(t1.media_type, "PICTURE") || "-"
            ,"MAIN_VIDEO", NVL(t1.media_type, "VIDEO") || "-"
            ,"MAIN_VIDEO_IMG", NVL(t1.media_type, "PICTURE") || "-"
            ,"BRANCH_VIDEO", NVL(t1.media_type, "VIDEO") || "-"
            ,"BRANCH_VIDEO_IMG", NVL(t1.media_type, "PICTURE") || "-"
            ,"AFTERMARKET_VIDEO", NVL(t1.media_type, "VIDEO") || "-"
            ,"AFTERMARKET_VIDEO_COVER", NVL(t1.media_type, "PICTURE") || "-"
            ,"AFTERMARKET_PICTURE", NVL(t1.media_type, "PICTURE") || "-"
            ,"SALE_ADVICE_VIDEO", NVL(t1.media_type, "VIDEO") || "-"
            ,"SALE_ADVICE_VIDEO_COVER", NVL(t1.media_type, "PICTURE") || "-"
            ,"SALE_ADVICE_PICTURE", NVL(t1.media_type, "PICTURE") || "-"
            ,NVL(t1.media_type || "-", "")
        ) || t1.attach_type AS raw_real_attach_type
        ,CASE
            WHEN
                NVL(t1.media_type, "PICTURE")="PICTURE" AND t1.attach_type = "MAIN_LIST"
            THEN "主图列表图片"
            WHEN
                NVL(t1.media_type, "PICTURE") = "PICTURE" AND t1.attach_type = "DETAIL_MAIN"
            THEN "详情主图图片"
            WHEN
                NVL(t1.media_type, "PICTURE") = "PICTURE" AND t1.attach_type = "DETAIL_DESC"
            THEN "详情描述图片"
            WHEN
                NVL(t1.media_type, "VIDEO") = "VIDEO" AND t1.attach_type = "MAIN_VIDEO"
            THEN "主视频"
            WHEN
                NVL(t1.media_type, "PICTURE") = "PICTURE" AND t1.attach_type = "MAIN_VIDEO_IMG"
            THEN "主视频图片"
            WHEN
                NVL(t1.media_type, "VIDEO") = "VIDEO" AND t1.attach_type = "BRANCH_VIDEO"
            THEN "视频分区"
            WHEN
                NVL(t1.media_type, "PICTURE") = "PICTURE" AND t1.attach_type = "BRANCH_VIDEO_IMG"
            THEN "视频分区图片"
            WHEN
                NVL(t1.media_type, "VIDEO") = "VIDEO" AND t1.attach_type = "AFTERMARKET_VIDEO"
            THEN "售后视频"
            WHEN
                NVL(t1.media_type, "PICTURE")="PICTURE" AND t1.attach_type="AFTERMARKET_VIDEO_COVER"
                THEN "售后视频封面"
            WHEN
                NVL(t1.media_type, "PICTURE")="PICTURE" AND t1.attach_type="AFTERMARKET_PICTURE"
                THEN "售后图片"
            WHEN
                NVL(t1.media_type, "VIDEO")="VIDEO" AND t1.attach_type="SALE_ADVICE_VIDEO"
                THEN "销售建议视频"
            WHEN
                NVL(t1.media_type, "PICTURE")="PICTURE" AND t1.attach_type="SALE_ADVICE_VIDEO_COVER"
                THEN "销售建议视频封面"
            WHEN
                NVL(t1.media_type, "PICTURE")="PICTURE" AND t1.attach_type="SALE_ADVICE_PICTURE"
                THEN "销售建议视频图片"
        END AS real_attach_type
    FROM(
        SELECT
            t1.dt
            ,t1.goods_id AS sku_id
            ,t2.company_id AS mall_id
            ,t1.media_type
            ,t1.attach_type
            ,"http://ugc-pro.biaoguoworks.com" || t1.attach_url AS attach_url
            ,t1.update_time
            ,t1.sort_no
            ,t2.merit
        FROM datawarehouse_max.ods_demeter_demeter_goods_attach_full t1
        JOIN datawarehouse_max.ods_demeter_demeter_goods_full t2
            ON DATE(TO_DATE(t2.pt, "yyyyMMdd000000")) BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND t2.id = t1.goods_id
            AND DATE(TO_DATE(t2.pt, "yyyyMMdd000000")) = t1.dt
            AND t2.killed = 0
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND t2.company_id = 871
    ) t1

)


,materails AS(
    SELECT
        t1.dt -- '日期'
        ,t1.mall_id -- '商城id' BIGINT
        ,t1.sku_id -- '商品id' BIGINT
        ,MAX(t1.merit) AS merit
        ,MAX(IF(
            t1.real_attach_type="主视频", t1.attach_url, NULL
        )) AS main_video_url -- '主视频地址' STRING

        ,MAX(IF(
            t1.real_attach_type="主视频", t1.update_time, NULL
        )) AS main_video_update_time -- '主视频更新时间' DATETIME
        ,MAX(IF(
            t1.real_attach_type="主视频图片", t1.attach_url, NULL
        )) AS main_video_pic_url -- '主视频图片地址' STRING
        ,MAX(IF(
            t1.real_attach_type="主视频图片", t1.update_time, NULL
        )) AS main_video_pic_update_time -- '主视频图片最近更新时间' DATETIME
        ,'[' || WM_CONCAT(
            ", ", '{"' || t1.real_attach_type || '": ' || t1.record  || "}"
        ) || ']' AS attach_detail -- '附件详情信息' STRING
    FROM(
        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.sku_id
            ,t1.real_attach_type
            -- ,'"' || t1.real_attach_type '": {' ||
            ,WM_CONCAT(", ", t1.attach_url) AS attach_url
            ,MAX(t1.update_time) AS update_time
            ,'{ "URL": "' || WM_CONCAT(", ", t1.attach_url) || '", ' ||
                '"最近更新时间": "' ||  MAX(t1.update_time) || '", ' ||
                '"附件类型": "' || t1.raw_real_attach_type || '"' 
            || '}' AS record
            ,MAX(t1.merit) AS merit
        FROM materials_temp t1
        GROUP BY t1.dt
            ,t1.mall_id
            ,t1.sku_id
            ,t1.real_attach_type
            ,t1.raw_real_attach_type
            
    ) t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    GROUP BY t1.dt -- '日期'
        ,t1.mall_id -- '商城id' BIGINT
        ,t1.sku_id -- '商品id' BIGINT
)

,subsidies_temp AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.sku_id
        ,t1.customer_store_id
        ,COUNT(DISTINCT t1.order_item_id) AS ordered_item_ticket_num -- "明细订单数量" BIGINT
        -- 优惠券
        ,SUM(
            NVL(t1.platform_market_amt_full_reduce_coupon, 0) + NVL(t1.platform_market_amt_single_goods_coupon,0)
        ) AS plat_coupon_market_fee
        ,SUM(IF(
            NVL(t1.platform_market_amt_full_reduce_coupon, 0) + NVL(t1.platform_market_amt_single_goods_coupon,0)>0
                ,t1.deliveried_goods_amt, 0
        )) AS delivered_goods_amt_with_pcmf -- "优惠券产生货值" DECIMAL(10,2)
        -- 平台补贴
        ,SUM(t2.platform_subsidy_amount) AS plat_subsidy_amount
        ,SUM(IF(
            t2.platform_subsidy_amount>0, t1.deliveried_goods_amt, 0
        )) AS delivered_goods_amt_with_psmf -- "补贴产生货值" DECIMAL(10,2)

        -- 营销费用产生货值
        ,SUM(IF(
            NVL(t1.platform_market_amt_full_reduce_coupon, 0) + NVL(t1.platform_market_amt_single_goods_coupon,0)
                + NVL(t2.platform_subsidy_amount, 0)>0, t1.deliveried_goods_amt, 0
        )) AS delivered_goods_amt_with_pmf -- "平台营销费用产生货值" DECIMAL(10,2)
    FROM datawarehouse_max.dwt_order_order_item_daily_asc t1
    LEFT JOIN datawarehouse_max.dwt_order_clearing_asc t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6 - 7, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.order_item_id = t1.order_item_id
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6 - 7, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
        AND t1.status != "CANCEL"

    GROUP BY t1.dt
        ,t1.mall_id
        ,t1.sku_id
        ,t1.customer_store_id
)


,subsidies AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.sku_id
        -- 优惠券
        ,SUM(
            NVL(t1.plat_coupon_market_fee, 0)
        ) AS plat_coupon_market_fee
        -- 平台补贴
        ,SUM(t1.plat_subsidy_amount) AS plat_subsidy_amount
        ,SUM(
            NVL(t1.delivered_goods_amt_with_pcmf, 0)
        ) AS delivered_goods_amt_with_pcmf-- "优惠券产生货值" DECIMAL(10,2)
        ,SUM(
            NVL(t1.delivered_goods_amt_with_psmf, 0)
        ) AS delivered_goods_amt_with_psmf-- "补贴产生货值" DECIMAL(10,2)
        ,SUM(t1.ordered_item_ticket_num) AS ordered_item_ticket_num -- "明细订单数量" BIGINT
        ,SUM(t1.delivered_goods_amt_with_pmf) AS delivered_goods_amt_with_pmf -- "平台营销费用产生货值" DECIMAL(10,2)
    FROM subsidies_temp t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")

    GROUP BY t1.dt
        ,t1.mall_id
        ,t1.sku_id
)






,css AS (
    SELECT
        DATE(t1.order_create_time) AS dt
        ,t1.mall_id
        ,t1.sku_id
            
        ,SUM(NVL(t1.seller_bear_refund_amt, 0)) AS refund_amt_by_mct -- '商家承担赔付金额' DECIMAL(10,2)
        ,COUNT(DISTINCT t1.customer_store_id) AS applied_store_num_by -- "售后门店数量" BIGINT
    FROM datawarehouse_max.dwt_order_after_sale_daily_asc t1
    
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND DATE(t1.order_create_time) BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
        AND t1.status != "CANCEL"
    GROUP BY DATE(t1.order_create_time)
        ,t1.mall_id
        ,t1.sku_id
)




,css_temp_asdt AS (
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.sku_id
        ,t1.customer_store_id
            
        ,SUM(NVL(t1.company_bear_refund_amt, 0)) AS refund_amt_by_asdt_plat -- '平台承担赔付金额
        ,SUM(NVL(t1.seller_bear_refund_amt,0)) AS refund_amt_by_asdt_mct
        ,COUNT(DISTINCT t1.after_sale_no) AS applied_after_sale_ticket_num_by_asdt -- "申请售后单数量" BIGINT
    FROM datawarehouse_max.dwt_order_after_sale_daily_asc t1
    
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6 - 7, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
        AND t1.status != "CANCEL"
    GROUP BY t1.dt
        ,t1.sku_id
        ,t1.mall_id
        ,t1.customer_store_id
)




,css_asdt AS(
    SELECT
        t1.dt
        ,t1.sku_id
        ,t1.mall_id
        
        ,SUM(t1.refund_amt_by_asdt_plat) AS refund_amt_by_asdt_plat -- '平台承担赔付金额
        ,SUM(NVL(t1.refund_amt_by_asdt_mct, 0)) AS refund_amt_by_asdt_mct -- '商家承担赔付金额' DECIMAL(10,2)
        ,COUNT(DISTINCT t1.customer_store_id) AS applied_store_num_by_asdt -- "售后门店数量" BIGINT
        ,SUM(t1.applied_after_sale_ticket_num_by_asdt) AS applied_after_sale_ticket_num_by_asdt -- "申请售后单数量" BIGINT
    FROM css_temp_asdt t1
    GROUP BY t1.dt
        ,t1.mall_id
        ,t1.sku_id
)



,recommends_stat AS(
    SELECT
        t1.dt -- `日期`
        ,t1.mall_id -- `商城ID`
        ,t1.sku_id
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
    GROUP BY t1.dt -- `日期`
        ,t1.mall_id -- `商城ID`
        ,t1.sku_id
)



,css_type AS(
    SELECT 
        t1.dt -- `日期`
        ,t1.mall_id -- `商城ID`
        ,t1.sku_id
        -- ,CONCAT_WS(":", t1.after_sale_type, after_sale_type_problem_title) AS 
        ,t1.after_sale_type_problem_title AS after_sale_type
        ,COUNT(DISTINCT t1.after_sale_no) AS applied_after_sale_ticket_num
    FROM(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.sku_id

        
        ,t1.after_sale_no
        ,t1.after_sale_type_problem_title
    FROM datawarehouse_max.dwt_order_after_sale_daily_asc t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
        AND t1.status != "CANCEL"
    ) t1
    GROUP BY t1.dt -- `日期`
            ,t1.mall_id -- `商城ID`
            ,t1.sku_id
            ,t1.after_sale_type_problem_title

)



,store_sku_base AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.customer_store_id
        ,t1.sku_id
        
        ,t1.exposed_cnt
        ,t1.ordered_goods_num
    FROM datawarehouse_max.dws_store_mall_store_sku_base_daily_asc  t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 30, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
)



,store_stat AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.customer_store_id
        ,t1.sku_id
        ,NVL(t2.is_login,0) AS is_login
        ,IF(
            NVL(t1.ordered_days_30d,0)>=7, "7+次", NVL(t1.ordered_days_30d, 0) || "次"
        ) AS ordered_days_30d
        ,IF(
            NVL(t1.exposed_days_30d,0)>=7, "7+次", NVL(t1.exposed_days_30d, 0) || "次"
        ) AS exposed_days_30d
        ,t3.exposed_cnt
        ,t3.ordered_goods_num
    FROM(

        SELECT /*+ MAPJOIN(t0) */
            t0.dt
            ,t1.mall_id
            ,t1.sku_id
            ,t1.customer_store_id

            ,COUNT(DISTINCT IF(
                t1.exposed_cnt>0, t1.dt, NULL
            )) AS exposed_days_30d
            ,COUNT(DISTINCT IF(
                t1.ordered_goods_num>0, t1.dt, NULL
            )) AS ordered_days_30d
        FROM store_sku_base t1
        JOIN dim_dates t0
            ON t1.dt BETWEEN DATEADD(DATE(t0.dt), -30, "dd")
                AND DATEADD(DATE(t0.dt),-1, "dd")

        WHERE t0.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        GROUP BY t0.dt
            ,t1.mall_id
            ,t1.sku_id
            ,t1.customer_store_id

    ) t1
    LEFT JOIN dim_store t2
        ON t2.dt = t1.dt
        AND t2.customer_store_id = t1.customer_store_id
        AND t2.mall_id = t1.mall_id
    LEFT JOIN store_sku_base t3
        ON t3.dt = t1.dt
        AND t3.mall_id = t1.mall_id
        AND t3.customer_store_id = t1.customer_store_id
        AND t3.sku_id = t1.sku_id
)

,ordered_store AS(
    SELECT
        t1.dt
        ,t1.sku_id
        ,t1.mall_id
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.ordered_days_30d || '":' || t1.store_num
            ) ||
        '}' AS store_num_by_ordered_30d_info -- "近30天不同下单频次店铺数" STRING
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.ordered_days_30d || '":' || t1.logon_store_num
            ) ||
        '}' AS logon_store_num_by_ordered_30d_info -- "近30天不同下单频次登陆店铺数" STRING
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.ordered_days_30d || '":' || t1.exposed_store_num
            ) ||
        '}' AS exposed_store_num_by_ordered_30d_info -- "近30天不同下单频次曝光店铺数" STRING
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.ordered_days_30d || '":' || t1.ordered_store_num
            ) ||
        '}' AS ordered_store_num_by_ordered_30d_info -- "近30天不同下单频次下单店铺数" STRING
    FROM(
        SELECT
            t1.dt
            ,t1.sku_id
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
            ,t1.sku_id
            ,t1.mall_id
            ,t1.ordered_days_30d
    ) t1

    GROUP BY t1.dt
        ,t1.sku_id
        ,t1.mall_id
)


,exposed_store AS(
    SELECT
        t1.dt
        ,t1.sku_id
        ,t1.mall_id
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.exposed_days_30d || '":' || t1.store_num
            ) ||
        '}' AS store_num_by_exposed_30d_info -- "近30天曝光不同频次门店数" STRING
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.exposed_days_30d || '":' || t1.logon_store_num
            ) ||
        '}' AS logon_store_num_by_exposed_30d_info -- "近30天曝光不同频次登陆门店数" STRING
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.exposed_days_30d || '":' || t1.exposed_store_num
            ) ||
        '}' AS exposed_store_num_by_exposed_30d_info -- "近30天曝光不同频次曝光门店数" STRING
        ,'{' ||
            WM_CONCAT(
                ","
                ,'"' || t1.exposed_days_30d || '":' || t1.ordered_store_num
            ) ||
        '}' AS ordered_store_num_by_exposed_30d_info -- "近30天曝光不同频次下单门店数" STRING
    FROM(
        SELECT
            t1.dt
            ,t1.sku_id
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
            ,t1.sku_id
            ,t1.mall_id
            ,t1.exposed_days_30d
    ) t1

    GROUP BY t1.dt
        ,t1.sku_id
        ,t1.mall_id
)

,store_tag AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.sku_id
        ,t1.customer_store_id
        ,NVL(MAX(t1.customer_store_tag), "new") AS customer_store_tag
    FROM(
        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.sku_id
            ,t1.customer_store_id
            ,t1.customer_store_tag
            ,NULL AS is_on
        FROM datawarehouse_max.dws_pub_mall_sku_customer_tag_daily_asc t1
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6 - 7, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND t1.mall_Id = 871
        UNION
        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.sku_id
            ,t1.customer_store_id
            ,NULL AS customer_store_tag

            ,1 AS is_on
        FROM datawarehouse_max.dws_store_mall_store_sku_base_daily_asc t1
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6 - 7, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND t1.mall_id = 871
            AND NVL(t1.exposed_cnt, 0) + NVL(t1.ordered_goods_num,0) + NVL(t1.after_sale_num, 0) 
                + NVL(t1.clicked_cnt,0) + NVL(t1.added_cnt, 0) > 0
    ) t1
    GROUP BY t1.dt
        ,t1.mall_id
        ,t1.sku_id
        ,t1.customer_store_id
)

,pool_store AS(
SELECT
    t1.dt
    ,t1.mall_id
    ,t1.sku_id
    ,COUNT(DISTINCT IF(INSTR(t1.customer_store_tag, "new")>0, t1.customer_store_id, NULL)) AS pool_num_new_store
    ,COUNT(DISTINCT IF(INSTR(t1.customer_store_tag, "loss")>0, t1.customer_store_id, NULL)) AS pool_num_loss_store
    ,COUNT(DISTINCT IF(INSTR(t1.customer_store_tag, "old")>0, t1.customer_store_id, NULL)) AS pool_num_old_store
FROM store_tag t1
GROUP BY t1.dt
    ,t1.mall_id
    ,t1.sku_id
)


,css_rebuy_tag AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.sku_id
        ,t1.customer_store_id
        ,NVL(t2.customer_store_tag, "new") AS customer_store_tag
        ,t1.ordered_cnt_cdta6d
        ,t1.ordered_cnt_cdta2d
    FROM (
        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.sku_id
            ,t1.customer_store_id
            ,COUNT(DISTINCT IF(
                t2.dt BETWEEN DATEADD(DATE(t1.dt), 0, "dd")
                    AND DATEADD(DATE(t1.dt), 6, "dd")
                , t2.dt, NULL
            )) AS ordered_cnt_cdta6d
            ,COUNT(DISTINCT IF(
                t2.dt BETWEEN DATEADD(DATE(t1.dt), 0, "dd")
                    AND DATEADD(DATE(t1.dt), 2, "dd")
                , t2.dt, NULL
            )) AS ordered_cnt_cdta2d
        FROM css_temp_asdt t1
        LEFT JOIN subsidies_temp t2
            ON t2.mall_id = t1.mall_id
            AND t2.customer_store_id = t1.customer_store_id
            AND t2.sku_id = t1.sku_id
            AND t2.dt BETWEEN DATEADD(DATE(t1.dt), 0, "dd")
                AND DATEADD(DATE(t1.dt), 6, "dd")

        GROUP BY t1.dt
            ,t1.mall_id
            ,t1.sku_id
            ,t1.customer_store_id
    ) t1
    LEFT JOIN store_tag t2
        ON t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.sku_id = t1.sku_id
        AND t2.customer_store_id = t1.customer_store_id
)


,css_tag_rebuy_stat AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.sku_id
        ,COUNT(DISTINCT IF(
            INSTR(t1.customer_store_tag,"new")>0, t1.customer_store_id, NULL
        )) AS applied_as_store_num_new_store -- "新客户售后门店数" BIGINT
        ,COUNT(DISTINCT IF(
            INSTR(t1.customer_store_tag,"new")>0 AND t1.ordered_cnt_cdta6d>0, t1.customer_store_id, NULL
        )) AS rebuy_applied_as_store_num_cdta6d_new_store -- "新客户售后近七日复购门店数" BIGINT
        ,COUNT(DISTINCT IF(
            INSTR(t1.customer_store_tag,"new")>0 AND t1.ordered_cnt_cdta2d>0, t1.customer_store_id, NULL
        )) AS rebuy_applied_as_store_num_cdta2d_new_store -- "新客户售后三日复购门店数" BIGINT
        
        ,COUNT(DISTINCT IF(
            INSTR(t1.customer_store_tag,"loss")>0, t1.customer_store_id, NULL
        )) AS applied_as_store_num_loss_store -- "召回客户售后门店数" BIGINT
        ,COUNT(DISTINCT IF(
            INSTR(t1.customer_store_tag,"loss")>0 AND t1.ordered_cnt_cdta6d>0, t1.customer_store_id, NULL
        )) AS rebuy_applied_as_store_num_cdta6d_loss_store -- "召回客户售后近七日复购门店数" BIGINT
        ,COUNT(DISTINCT IF(
            INSTR(t1.customer_store_tag,"loss")>0 AND t1.ordered_cnt_cdta2d>0, t1.customer_store_id, NULL
        )) AS rebuy_applied_as_store_num_cdta2d_loss_store -- "召回客户售后三日复购门店数" BIGINT

        ,COUNT(DISTINCT IF(
            INSTR(t1.customer_store_tag,"old")>0, t1.customer_store_id, NULL
        )) AS applied_as_store_num_old_store -- "老客户售后门店数" BIGINT
        ,COUNT(DISTINCT IF(
            INSTR(t1.customer_store_tag,"old")>0 AND t1.ordered_cnt_cdta6d>0, t1.customer_store_id, NULL
        )) AS rebuy_applied_as_store_num_cdta6d_old_store -- "老客户售后近七日复购门店数" BIGINT
        ,COUNT(DISTINCT IF(
            INSTR(t1.customer_store_tag,"old")>0 AND t1.ordered_cnt_cdta2d>0, t1.customer_store_id, NULL
        )) AS rebuy_applied_as_store_num_cdta2d_old_store -- "老客户售后三日复购门店数" BIGINT    
    FROM css_rebuy_tag t1
    GROUP BY  t1.dt
        ,t1.mall_id
        ,t1.sku_id
)

, base AS(
    SELECT
        
        t1.mall_id -- "商城id" STRING
        ,t1.sku_id -- "商品ID" BIGINT
        ,t001.sku_name -- "商品名称" STRING
        ,t001.merchant_id -- "商家id" BIGINT
        ,t001.merchant_name -- "商家名称" STRING
        ,t001.merchant_type -- "商家类型" STRING
        ,DATEDIFF(DATETIME(t1.dt || " 00:00:00"), DATETIME(t10.main_video_update_time), "dd") AS updated_video_gap -- "最近更新视频天数" BIGINT
        ,DATEDIFF(DATETIME(t1.dt || " 00:00:00"), DATETIME(t10.main_video_pic_update_time), "dd") AS updated_main_pic_gap -- "最近更新主图图片天数" BIGINT
        ,t10.attach_detail -- "附件信息" STRING
        ,IF(NVL(t001.merit, "") != NVL(t002.merit, "") AND LENGTH(NVL(t001.merit, ""))>0, 1, 0) AS is_updated_merit -- "是否卖点更新" BIGINT
        ,t001.merit -- "商品卖点" STRING
        ,t001.origin_place -- "产地" STRING
        ,t001.product_class -- "等级" STRING
        ,t001.product_spec -- "规格" STRING
        ,t001.product_variety -- "品种" STRING
        ,t001.brand_name -- "品牌" STRING
        ,t001.category_level1_id -- "一级类目id" BIGINT
        ,t001.category_level1_name -- "一级类目名称" STRING
        ,t001.category_level4_id -- "四级类目id" BIGINT
        ,t001.category_level4_name -- "四级类目名称" STRING
        ,t001.is_up_today AS is_onshelved -- "当日是否上架" BIGINT
        ,t001.is_sku_valid AS is_valid -- "是否有效SKU" BIGINT
        ,t001.commission_rate_conf -- "配置商品抽佣率" DECIMAL(10,4)
        
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
        ,ROUND(
            t4.delivered_goods_amt_with_pmf, 2
        ) AS delivered_goods_amt_with_pmf -- "平台营销费用产生货值" DECIMAL(10,2)
        ,t4.ordered_item_ticket_num -- "明细订单数量" BIGINT
        ,t5.applied_after_sale_ticket_num_by_asdt -- "申请售后单数量" BIGINT
        ,NVL(t5.refund_amt_by_asdt_plat, 0) AS refund_amt_by_asdt_plat -- "平台承担售后赔付金额售后提交日" DECIMAL(10,2)
        ,t9.applied_after_sale_ticket_num_by_asdt_info -- "售后类型申请数量" STRING
        ,t5.applied_store_num_by_asdt -- "提交日售后门店数" BIGINT
        ,t05.rebuy_store_num_cdta6d_applied_asdt -- "售后七日复购店铺数" BIGINT
        ,t05.rebuy_store_num_cdta2d_applied_asdt -- "售后三日复购店铺数" BIGINT
        ,t1.final_refund_amt_order_time AS refund_amt -- "售后赔付金额" DECIMAL(10,2)
        ,t1.after_sale_num_order_time AS applied_after_sale_goods_num -- "售后商品数量" BIGINT
        ,t11.refund_amt_by_mct -- '商家承担赔付金额' DECIMAL(10,2)
        
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

        ,t7.pool_num_new_store -- "新客户池" BIGINT
        ,t7.pool_num_old_store -- "老客户池" BIGINT
        ,t7.pool_num_loss_store -- "召回客户池" BIGINT
        ,ROUND(t7.pool_num_new_store / t07.pool_num_new_store - 1, 6) AS pool_num_incr_ratio_new_store -- "新客户池增长率" DECIMAL(10,6)
        ,ROUND(t7.pool_num_old_store / t07.pool_num_old_store - 1, 6) AS pool_num_incr_ratio_old_store -- "老客户池增长率" DECIMAL(10,6)
        ,ROUND(t7.pool_num_loss_store / t07.pool_num_loss_store - 1, 6) AS pool_num_incr_ratio_loss_store -- "召回客户池增长率" DECIMAL(10,6)
        ,t1.exposed_store_num_old_user AS exposed_store_num_old_store -- "老客户曝光店铺数" BIGINT
        ,t1.exposed_store_num_loss_user AS exposed_store_num_loss_store -- "召回客户曝光店铺数" BIGINT
        ,t1.exposed_store_num_new_user AS exposed_store_num_new_store -- "新客户曝光店铺数" BIGINT
        ,t1.ordered_store_num_old_user AS ordered_store_num_old_store -- "老客户下单店铺数" BIGINT
        ,t1.ordered_store_num_loss_user AS ordered_store_num_loss_store -- "召回客户下单店铺数" BIGINT
        ,t1.ordered_store_num_new_user AS ordered_store_num_new_store -- "新客户下单店铺数" BIGINT
        ,t8.delivered_goods_amt_new_store_mmf -- "商家新客营销费用贡献货值" DECIMAL(10,2)
        ,t8.mct_market_fee_amt_new_store -- "商家新客营销费用" DECIMAL(10,2)
        ,t8.delivered_goods_amt_loss_store_mmf -- "商家召回客营销费用贡献货值" DECIMAL(10,2)
        ,t8.mct_market_fee_amt_loss_store -- "商家召回客户营销费用" DECIMAL(10,2)
        ,ROW_NUMBER() OVER(
            PARTITION BY t1.dt, t1.mall_id, t1.category_level4_id
                ORDER BY t1.exposed_store_num_new_user / t1.exposed_store_num_new_user DESC
        ) AS exposed2ordered_store_ratio_new_store_rnk_by_mall_cat4 -- "同品类新客户曝光转化率排名" BIGINT

        ,CONCAT_WS(
            ","
            ,IF(t8.is_high_exposed_low_inversion>0, "高曝光低转化", NULL)
            ,IF(
                t1.exposed_store_num < PERCENTILE(t1.exposed_store_num, 0.1)FILTER(WHERE t001.is_up_today>0) OVER(PARTITION BY t1.dt, t1.mall_id, t1.category_level4_id)
                    AND t001.is_up_today>0
                , "低曝光", NULL
            )
            ,IF(NVL(t1.ordered_goods_num, 0)=0 AND t001.is_up_today>0, "零动销", NULL)
        ) AS invalid_sku_type -- "无效SKU类型" STRING
        ,CONCAT_WS(
            ","
            ,IF(
                t1.exposed_store_num <= PERCENTILE(t1.exposed_store_num, 0.75)FILTER(WHERE t001.is_up_today>0) OVER(PARTITION BY t1.dt, t1.mall_id,t1.category_level4_id)
                AND t1.exposed_store_num >= PERCENTILE(t1.exposed_store_num, 0.50)FILTER(WHERE t001.is_up_today>0) OVER(PARTITION BY t1.dt, t1.mall_id, t1.category_level4_id)
                    AND BIGINT(t1.ordered_store_num/t1.exposed_store_num * 1E6) >= PERCENTILE(BIGINT(t1.ordered_store_num/t1.exposed_store_num * 1E6), 0.80)FILTER(WHERE t001.is_up_today>0) OVER(PARTITION BY t1.dt, t1.mall_id, t1.category_level4_id)
                    AND t001.is_up_today>0, "同品类中等曝光高转化", NULL
            )
            ,IF(
                t1.exposed_store_num <= PERCENTILE(t1.exposed_store_num, 0.75)FILTER(WHERE t001.is_up_today>0) OVER(PARTITION BY t1.dt, t1.mall_id)
                AND t1.exposed_store_num >= PERCENTILE(t1.exposed_store_num, 0.50)FILTER(WHERE t001.is_up_today>0) OVER(PARTITION BY t1.dt, t1.mall_id)
                    AND BIGINT(t1.ordered_store_num/t1.exposed_store_num * 1E6) >= PERCENTILE(BIGINT(t1.ordered_store_num/t1.exposed_store_num * 1E6), 0.80)FILTER(WHERE t001.is_up_today>0) OVER(PARTITION BY t1.dt, t1.mall_id)
                    AND t001.is_up_today>0, "中心仓中等曝光高转化", NULL
            )
        ) AS potential_sku_type -- "潜力SKU类型" STRING

        ,t12.store_num_by_ordered_30d_info -- "近30天不同下单频次店铺数" STRING
        ,t12.logon_store_num_by_ordered_30d_info -- "近30天不同下单频次登陆店铺数" STRING
        ,t12.exposed_store_num_by_ordered_30d_info -- "近30天不同下单频次曝光店铺数" STRING
        ,t12.ordered_store_num_by_ordered_30d_info -- "近30天不同下单频次下单店铺数" STRING
        
        ,t13.store_num_by_exposed_30d_info -- "近30天曝光不同频次门店数" STRING
        ,t13.logon_store_num_by_exposed_30d_info -- "近30天曝光不同频次登陆门店数" STRING
        ,t13.exposed_store_num_by_exposed_30d_info -- "近30天曝光不同频次曝光门店数" STRING
        ,t13.ordered_store_num_by_exposed_30d_info -- "近30天曝光不同频次下单门店数" STRING
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.mall_id, t1.category_level4_id
                ORDER BY t1.delivered_goods_amt DESC
        ) AS delivered_goods_amt_desc_rnk_by_mall_cat4 -- "同商城同品类货值排名" BIGINT
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.mall_id, t1.category_level4_id
                ORDER BY t1.ordered_store_num DESC
        ) AS ordered_store_num_desc_rnk_by_mall_cat4 -- "同商城同品类下单店铺数排名" BIGINT
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
        ) AS exposed_store_num_desc_rnk_by_mall -- "曝光门店数降序排名" BIGINT
        ,ROUND(
            t1.ordered_store_num / t1.exposed_store_num, 6
        ) AS exposed2ordered_store_ratio -- "曝光转化率" DECIMAL(10,6)
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.mall_id
            ORDER BY NVL(t1.ordered_store_num / t1.exposed_store_num, 0) DESC
        ) AS exposed2ordered_store_ratio_desc_rnk_by_mall -- "曝光转化率降序排名" BIGINT
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.mall_id, t1.category_level4_id
            ORDER BY NVL(t1.ordered_store_num / t1.exposed_store_num, 0) DESC
        ) AS exposed2ordered_store_ratio_desc_rnk_by_mall_cat4 -- "同品类曝光转化率降序排名" BIGINT
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.mall_id, t1.category_level4_id, t1.merchant_id
            ORDER BY NVL(t1.ordered_store_num / t1.exposed_store_num, 0) DESC
        ) AS exposed2ordered_store_ratio_desc_rnk_by_mall_cat4_mct -- "同品类同商家曝光转化率降序排名" BIGINT
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level4_id
            ORDER BY t1.ordered_store_num / t1.exposed_store_num DESC
        ) AS exposed2ordered_store_ratio_desc_rnk_by_cat4 -- "跨中心仓同品类曝光转化率降序排名" BIGINT
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level1_id
            ORDER BY t1.ordered_store_num / t1.exposed_store_num DESC
        ) AS exposed2ordered_store_ratio_desc_rnk_by_non -- "跨中心仓曝光转化率降序排名" BIGINT

        ,ROUND(
            t1.exposed_store_num / t3.exposed_store_num, 6
        ) AS exposed_store_ratio_by_mall -- "曝光门店数占商城比例" BIGINT
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level4_id
            ORDER BY t1.exposed_store_num / t3.exposed_store_num DESC
        ) AS exposed_store_ratio_by_mall_desc_rnk_by_cat4 -- "跨仓曝光门店数占商城比例降序排名" BIGINT
        ,ROUND(
            t1.exposed_store_num / t02.exposed_store_num, 6
        ) AS exposed_store_ratio_by_cat4 -- "曝光门店数占四级类目比例" BIGINT
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.mall_id, t1.category_level4_id
            ORDER BY t1.exposed_store_num / t02.exposed_store_num DESC
        ) AS exposed_store_ratio_by_cat4_desc_rnk_by_mall_cat4 -- "同品类曝光门店数占四级类目比例降序排名" BIGINT
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level4_id
            ORDER BY t1.exposed_store_num / t02.exposed_store_num DESC
        ) AS exposed_store_ratio_by_cat4_desc_rnk_by_cat4 -- "同品类曝光门店数占四级类目比例降序排名" BIGINT
        
        ,t1.dt -- "日期" STRING
    FROM datawarehouse_max.dws_pub_mall_sku_base_daily_asc t1
    JOIN mall t0
        ON t0.mall_id = t1.mall_id
    JOIN dim_sku t001
        ON t001.dt = t1.dt
        AND t001.mall_id = t1.mall_id
        AND t001.sku_id = t1.sku_id
    LEFT JOIN dim_sku t002
        ON t002.dt = t1.dt
        AND t002.mall_id = t1.mall_id
        AND t002.sku_id = t1.sku_id
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
    LEFT JOIN datawarehouse_max.dws_pub_mall_category_level4_base_daily_asc t02
        ON t02.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t02.dt = t1.dt
        AND t02.mall_id = t1.mall_id
        AND t02.category_level4_id = t1.category_level4_id
    LEFT JOIN subsidies t4
        ON t4.dt = t1.dt
        AND t4.mall_id = t1.mall_id
        AND t4.sku_id = t1.sku_id
    LEFT JOIN css_asdt t5
        ON t5.dt = t1.dt
        AND t5.mall_id = t1.mall_id
        AND t5.sku_id = t1.sku_id
    
    LEFT JOIN (
        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.sku_id
            ,COUNT(DISTINCT IF(
                t2.dt BETWEEN DATEADD(DATE(t1.dt), 0, "dd") AND DATEADD(DATE(t1.dt), 6, "dd"), 
                    t2.customer_store_id, NULL
            )) AS rebuy_store_num_cdta6d_applied_asdt -- "售后七日复购店铺数" BIGINT
            ,COUNT(DISTINCT IF(
                t2.dt BETWEEN DATEADD(DATE(t1.dt), 0, "dd") AND DATEADD(DATE(t1.dt), 2, "dd"), 
                    t2.customer_store_id, NULL
            )) AS rebuy_store_num_cdta2d_applied_asdt -- "售后三日复购店铺数" BIGINT
        FROM css_temp_asdt t1
        LEFT JOIN subsidies_temp t2
            ON t2.dt BETWEEN DATEADD(DATE(t1.dt), 0, "dd")
                AND DATEADD(DATE(t1.dt), 6, "dd")
            AND t2.mall_id = t1.mall_id
            AND t2.sku_id = t1.sku_id
            AND t2.customer_store_id = t1.customer_store_id
        GROUP BY t1.dt
            ,t1.mall_id
            ,t1.sku_id
    ) t05
        ON t05.dt = t1.dt
        AND t05.mall_id = t1.mall_id
        AND t05.sku_id = t1.sku_id
    
    LEFT JOIN recommends_stat t6
        ON t6.dt = t1.dt
        AND t6.mall_id = t1.mall_id
        AND t6.sku_id = t1.sku_id
    
    LEFT JOIN pool_store t7
        ON t7.dt = t1.dt
        AND t7.mall_id = t1.mall_id
        AND t7.sku_id = t1.sku_id
    LEFT JOIN pool_store t07
        ON t07.dt = DATEADD(DATE(t1.dt), -7, "dd")
        AND t07.mall_id = t1.mall_id
        AND t07.sku_id = t1.sku_id
    
    LEFT JOIN (
        SELECT
            t1.dt
            ,goods_id AS sku_id
            ,871 AS mall_id

            ,t1.new_amount AS delivered_goods_amt_new_store_mmf -- "商家新客营销费用贡献货值" DECIMAL(10,2)
            ,t1.new_market_fee AS mct_market_fee_amt_new_store -- "商家新客营销费用" DECIMAL(10,2)

            ,t1.recall_amount AS delivered_goods_amt_loss_store_mmf -- "商家召回客营销费用贡献货值"
            ,t1.recall_market_fee AS mct_market_fee_amt_loss_store -- "商家召回客户营销费用" DECIMAL(10,2)
            ,t1.is_high_exposed_low_inversion
        FROM datawarehouse_max.ads_changsha_sku_dashboard_daily_asc t1
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    ) t8
        ON t8.dt = t1.dt
        AND t8.mall_id = t1.mall_id
        AND t8.sku_id = t1.sku_id
    LEFT JOIN (
        SELECT
            t1.dt
            ,t1.sku_id
            ,t1.mall_id
            ,'{' ||
                WM_CONCAT(
                    ","
                    ,'"' || t1.after_sale_type || '":' || t1.applied_after_sale_ticket_num
                ) ||
            '}' AS applied_after_sale_ticket_num_by_asdt_info
        FROM css_type t1
        GROUP BY t1.dt
                ,t1.sku_id
                ,t1.mall_id
    ) t9
        ON t9.dt = t1.dt
        AND t9.mall_id = t1.mall_id
        AND t9.sku_id = t1.sku_id

    LEFT JOIN materails t10
        ON t10.dt = t1.dt
        AND t10.sku_id = t1.sku_id
        AND t10.mall_id = t1.mall_id
    LEFT JOIN css t11
        ON t11.dt = t1.dt
        AND t11.mall_id = t1.mall_id 
        AND t11.sku_id = t1.sku_id
    LEFT JOIN ordered_store t12
        ON t12.dt = t1.dt
        AND t12.sku_id = t1.sku_id
        AND t12.mall_id = t1.mall_id
    
    LEFT JOIN exposed_store t13
        ON t13.dt = t1.dt
        AND t13.mall_id = t1.mall_id
        AND t13.sku_id = t1.sku_id
    
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND ISNOTNULL(t1.sku_id)
        AND t1.mall_id = 871
        
)

INSERT OVERWRITE TABLE changsha_sku_stat_daily_asc PARTITION(dt)

SELECT
	t1.mall_id -- "商城id" STRING
	,t1.sku_id -- "商品ID" BIGINT
	,t1.sku_name -- "商品名称" STRING
	,t1.merchant_id -- "商家id" BIGINT
	,t1.merchant_name -- "商家名称" STRING
	,t1.merchant_type -- "商家类型" STRING
	,t1.updated_video_gap -- "最近更新视频天数" BIGINT
	,t1.updated_main_pic_gap -- "最近更新主图图片天数" BIGINT
	,t1.is_updated_merit -- "是否卖点更新" BIGINT
	,t1.merit -- "商品卖点" STRING
	,t1.origin_place -- "产地" STRING
	,t1.product_class -- "等级" STRING
	,t1.product_spec -- "规格" STRING
	,t1.product_variety -- "品种" STRING
	,t1.brand_name -- "品牌" STRING
	,t1.category_level1_id -- "一级类目id" BIGINT
	,t1.category_level1_name -- "一级类目名称" STRING
	,t1.category_level4_id -- "四级类目id" BIGINT
	,t1.category_level4_name -- "四级类目名称" STRING
    ,t1.is_onshelved -- "当日是否上架" BIGINT
    ,t1.is_valid -- "是否有效SKU" BIGINT
    ,t2.onshelved_cnt_7d -- "7日内上架天数" BIGINT
    ,t1.commission_rate_conf -- "配置商品抽佣率" DECIMAL(10,4)

	,CAST(t3.avg_base_price AS DECIMAL(10,2)) AS price_old -- "老客价" DECIMAL(10,2)
	,CAST(t3.avg_new_customer_price AS DECIMAL(10,2)) AS price_new -- "新客价" DECIMAL(10,2)
	,CAST(t3.avg_recall_customer_price AS DECIMAL(10,2)) AS price_loss -- "召回客户价" DECIMAL(10,2)
	,t1.exposed_store_num -- "曝光店铺数" BIGINT
	,t1.clicked_store_num -- "点击店铺数" BIGINT
	,t1.added_store_num -- "加购店铺数" BIGINT
	,t1.ordered_store_num -- "下单店铺数" BIGINT
	,t1.ordered_goods_num -- "下单件数" BIGINT
	,t1.delivered_goods_amt -- "货值" DECIMAL(10,2)
	,t1.delivered_goods_num -- "件数" BIGINT

	,t1.commission_amt -- "平台抽佣金额" DECIMAL(10,2)
	,t1.subsidy_amt_plat -- "平台补贴费用" DECIMAL(10,2)
    ,t1.applied_after_sale_ticket_num_by_asdt -- "申请售后单数量" BIGINT
	,t1.refund_amt_by_asdt_plat -- "平台承担售后赔付金额售后提交日" DECIMAL(10,2)
    ,t1.applied_after_sale_ticket_num_by_asdt_info -- "售后类型申请数量" STRING
	,t1.applied_store_num_by_asdt -- "提交日售后门店数" BIGINT
	,t1.rebuy_store_num_cdta6d_applied_asdt -- "售后七日复购店铺数" BIGINT
	,t1.rebuy_store_num_cdta2d_applied_asdt -- "售后三日复购店铺数" BIGINT
	,t1.refund_amt -- "售后赔付金额" DECIMAL(10,2)
	,t1.applied_after_sale_goods_num -- "售后商品数量" BIGINT
    ,t1.refund_amt_by_mct -- '商家承担赔付金额' DECIMAL(10,2)

	,t1.delivered_goods_amt_pg -- "件单价" DECIMAL(10,2)
	,t1.ordered_goods_num_ps -- "客均件数" DECIMAL(10,1)
	,t1.delivered_goods_amt_ps -- "客均货值" DECIMAL(10,2)

	,t1.shared_links_cnt -- "BD分享次数" BIGINT
	,t1.shared_links_store_num -- "BD分享触达店铺数" BIGINT
	,t1.exposed_store_num_by_share_links -- "BD分享曝光店铺数" BIGINT
	,t1.clicked_store_num_by_share_links -- "点击BD分享链接店铺数" BIGINT
	,t1.ordered_store_num_by_share_links -- "有BD分享下单的店铺数" BIGINT

	,t1.pool_num_new_store -- "新客户池" BIGINT
	,t1.pool_num_old_store -- "老客户池" BIGINT
	,t1.pool_num_loss_store -- "召回客户池" BIGINT
    ,t1.pool_num_incr_ratio_new_store -- "新客户池增长率" DECIMAL(10,6)
    ,t1.pool_num_incr_ratio_old_store -- "老客户池增长率" DECIMAL(10,6)
    ,t1.pool_num_incr_ratio_loss_store -- "召回客户池增长率" DECIMAL(10,6)
	,t1.exposed_store_num_old_store -- "老客户曝光店铺数" BIGINT
	,t1.exposed_store_num_loss_store -- "召回客户曝光店铺数" BIGINT
	,t1.exposed_store_num_new_store -- "新客户曝光店铺数" BIGINT
	,t1.ordered_store_num_old_store -- "老客户下单店铺数" BIGINT
	,t1.ordered_store_num_loss_store -- "召回客户下单店铺数" BIGINT
	,t1.ordered_store_num_new_store -- "新客户下单店铺数" BIGINT
	,t1.delivered_goods_amt_new_store_mmf -- "商家新客营销费用贡献货值" DECIMAL(10,2)
	,t1.mct_market_fee_amt_new_store -- "商家新客营销费用" DECIMAL(10,2)
	,t1.delivered_goods_amt_loss_store_mmf -- "商家召回客营销费用贡献货值" DECIMAL(10,2)
	,t1.mct_market_fee_amt_loss_store -- "商家召回客户营销费用" DECIMAL(10,2)

    ,t4.applied_as_store_num_new_store -- "新客户售后门店数" BIGINT
    ,t4.rebuy_applied_as_store_num_cdta6d_new_store -- "新客户售后近七日复购门店数" BIGINT
    ,t4.rebuy_applied_as_store_num_cdta2d_new_store -- "新客户售后三日复购门店数" BIGINT
    ,t4.applied_as_store_num_loss_store -- "召回客户售后门店数" BIGINT
    ,t4.rebuy_applied_as_store_num_cdta6d_loss_store -- "召回客户售后近七日复购门店数" BIGINT
    ,t4.rebuy_applied_as_store_num_cdta2d_loss_store -- "召回客户售后三日复购门店数" BIGINT
    ,t4.applied_as_store_num_old_store -- "老客户售后门店数" BIGINT
    ,t4.rebuy_applied_as_store_num_cdta6d_old_store -- "老客户售后近七日复购门店数" BIGINT
    ,t4.rebuy_applied_as_store_num_cdta2d_old_store -- "老客户售后三日复购门店数" BIGINT
	,t1.invalid_sku_type -- "无效SKU类型" STRING
	,t1.potential_sku_type -- "潜力SKU类型" STRING
    ,t1.store_num_by_ordered_30d_info -- "近30天不同下单频次店铺数" STRING
    ,t1.logon_store_num_by_ordered_30d_info -- "近30天不同下单频次登陆店铺数" STRING
    ,t1.exposed_store_num_by_ordered_30d_info -- "近30天不同下单频次曝光店铺数" STRING
    ,t1.ordered_store_num_by_ordered_30d_info -- "近30天不同下单频次下单店铺数" STRING
    ,t1.store_num_by_exposed_30d_info -- "近30天曝光不同频次门店数" STRING
    ,t1.logon_store_num_by_exposed_30d_info -- "近30天曝光不同频次登陆门店数" STRING
    ,t1.exposed_store_num_by_exposed_30d_info -- "近30天曝光不同频次曝光门店数" STRING
    ,t1.ordered_store_num_by_exposed_30d_info -- "近30天曝光不同频次下单门店数" STRING
    
    ,t1.delivered_goods_amt_with_pmf -- "平台营销费用产生货值" DECIMAL(10,2)
    ,t1.exposed2ordered_store_ratio_new_store_rnk_by_mall_cat4 -- "同品类新客户曝光转化率排名" BIGINT
    ,t1.ordered_item_ticket_num -- "明细订单数量" BIGINT
    ,t1.attach_detail -- "附件信息" STRING
    
	,t1.delivered_goods_amt_desc_rnk_by_mall_cat4 -- "同商城同品类货值排名" BIGINT
	,t1.ordered_store_num_desc_rnk_by_mall_cat4 -- "同商城同品类下单店铺数排名" BIGINT
	,t1.ordered_store_ratio_by_cat1 -- "日活覆盖率" DECIMAL(10,6)
	,t1.ordered_store_ratio_by_cat1_rnk -- "日活覆盖率排名" BIGINT
	,t1.exposed_store_num_desc_rnk_by_mall -- "曝光门店数降序排名" BIGINT
	,t1.exposed2ordered_store_ratio -- "曝光转化率" DECIMAL(10,6)
	,t1.exposed2ordered_store_ratio_desc_rnk_by_mall -- "曝光转化率降序排名" BIGINT
	,t1.exposed2ordered_store_ratio_desc_rnk_by_mall_cat4 -- "同品类曝光转化率降序排名" BIGINT
	,t1.exposed2ordered_store_ratio_desc_rnk_by_mall_cat4_mct -- "同品类同商家曝光转化率降序排名" BIGINT
	,t1.exposed2ordered_store_ratio_desc_rnk_by_cat4 -- "跨中心仓同品类曝光转化率降序排名" BIGINT
	,t1.exposed2ordered_store_ratio_desc_rnk_by_non -- "跨中心仓曝光转化率降序排名" BIGINT

	,t1.exposed_store_ratio_by_mall -- "曝光门店数占商城比例" BIGINT
	,t1.exposed_store_ratio_by_mall_desc_rnk_by_cat4 -- "跨仓曝光门店数占商城比例降序排名" BIGINT
	,t1.exposed_store_ratio_by_cat4 -- "曝光门店数占四级类目比例" BIGINT
	,t1.exposed_store_ratio_by_cat4_desc_rnk_by_mall_cat4 -- "同品类曝光门店数占四级类目比例降序排名" BIGINT
	,t1.exposed_store_ratio_by_cat4_desc_rnk_by_cat4 -- "同品类曝光门店数占四级类目比例降序排名" BIGINT
    ,t1.dt
FROM base t1
LEFT JOIN (
    SELECT
        t1.mall_id
        ,t1.sku_id
        ,COUNT(DISTINCT t1.dt) AS onshelved_cnt_7d -- "7日内上架天数" BIGINT
    FROM datawarehouse_max.dim_goods_daily_full t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), -6, "dd")
        AND DATEADD(TO_DATE("${dt}"),0, "dd")
        AND t1.mall_id  = 871
        AND t1.is_up_today>0
    GROUP BY t1.mall_id
        ,t1.sku_id
) t2
    ON t2.mall_id = t1.mall_id
    AND t2.sku_id = t1.sku_id
LEFT JOIN datawarehouse_max.ads_changsha_sku_dashboard_daily_asc t3
    ON t3.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND t3.dt = t1.dt
    AND t3.goods_id = t1.sku_id
    AND t1.mall_id = 871

LEFT JOIN css_tag_rebuy_stat t4
    ON t4.dt = t1.dt
    AND t4.mall_id = t1.mall_id
    AND t4.sku_id = t1.sku_id
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND t1.mall_id = 871
;








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





/*
区县统计
*/

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
--     ,delivered_goods_amt DECIMAL(10,2) COMMENT "货值"
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


,base AS(
    SELECT
        t1.mall_id -- "商城ID" BIGINT
        ,t2.province_id -- "省ID" BIGINT
        ,t2.province_name -- "省名称" STRING
        ,t2.city_id -- "市ID" BIGINT
        ,REGEXP_REPLACE(t2.city_name, "\\d", "") AS city_name -- "市名称" STRING -- "市名称" STRING
        ,t2.county_id -- "区县ID" BIGINT
        ,t2.county_name -- "区县名称" STRING
        ,COUNT(DISTINCT IF(t1.ordered_goods_num>0, t1.customer_store_id, NULL)) AS ordered_store_num -- "下单门店数" BIGINT
        ,SUM(t1.delivered_goods_amt) AS delivered_goods_amt -- "货值" DECIMAL(10,2)

        ,t1.dt
    FROM datawarehouse_max.dws_store_mall_store_sku_base_daily_asc t1
    LEFT JOIN datawarehouse_max.dim_store_daily_full t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.customer_store_id = t1.customer_store_id
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
        AND INSTR(t1.category_level1_name, "水果") > 0
    GROUP BY t1.mall_id -- "商城ID" BIGINT
        ,t2.province_id -- "省ID" BIGINT
        ,t2.province_name -- "省名称" STRING
        ,t2.city_id -- "市ID" BIGINT
        ,REGEXP_REPLACE(t2.city_name, "\\d", "")
        ,t2.county_id -- "区县ID" BIGINT
        ,t2.county_name -- "区县名称" STRING
        ,t1.dt

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
    ,t1.delivered_goods_amt -- "货值" DECIMAL(10,2)
    ,IF(
        t2.visited_store_num>0, t2.visited_item_info, NULL
    ) AS visited_item_info -- "BD拜访详情" STRING
    ,t2.visited_store_num -- "拜访门店数量" BIGINT

    ,t1.dt
FROM base t1
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

;


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
-- TBLPROPERTIES('comment'='商家四级类目区县统计');





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



,store_tag AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.merchant_id
        ,t1.category_level4_id
        ,t02.category_level1_id
        ,t1.customer_store_id
        ,t2.province_id
        ,t2.city_id
        ,t2.county_id
        ,t1.customer_store_tag
    FROM datawarehouse_max.dws_pub_mall_merchant_cate4_customer_tag_daily_asc t1
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
        ,t1.merchant_id -- "商家ID" BIGINT
        ,t1.merchant_name -- "商家名称" STRING
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
            ,NVL(t4.customer_store_tag, "new") AS customer_store_tag
            ,t1.ordered_goods_num
            
            ,t1.delivered_goods_amt
            ,t1.delivered_goods_num
            ,t1.deliveried_gross_wgt
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
        LEFT JOIN store_tag t4
            ON t4.dt = t1.dt
            AND t4.mall_id = t1.mall_id
            AND t4.customer_store_id = t1.customer_store_id
            AND t4.category_level1_id = t1.category_level1_id
            AND t4.category_level4_id = t1.category_level4_id
            AND t4.merchant_id = t2.merchant_id

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




,recommends_stat AS(
    SELECT
        t1.dt -- `日期`
        ,t1.mall_id -- `商城ID`
        ,t3.category_level1_id
        ,t3.category_level4_id
        ,t3.merchant_id
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
        AND t4.mall_id = t1.mall_id
        AND t4.customer_store_id = t1.customer_store_id
    GROUP BY t1.dt -- `日期`
        ,t1.mall_id -- `商城ID`
        ,t3.category_level1_id
        ,t3.category_level4_id
        ,t3.merchant_id
        ,t4.province_id
        ,t4.city_id
        ,t4.county_id
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
            ,t1.merchant_id
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
            ,t1.merchant_id
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
        AND  t3.merchant_id = t1.merchant_id
        AND t3.category_level1_id = t1.category_level1_id
        AND t3.category_level4_id = t1.category_level4_id

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
    AND t2.merchant_id = t1.merchant_id
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
        -- ,t2.merchant_name -- "商家名称" STRING
        ,t2.category_level1_id -- "一级类目ID" BIGINT
        -- ,t2.category_level1_name
        ,t2.category_level4_id -- "四级类目ID" BIGINT
        -- ,t2.category_level4_name
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
        -- ,t2.category_level1_name
        ,t2.category_level4_id
        -- ,t2.category_level4_name
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
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") , "dd")
    AND t2.dt = t1.dt
    AND t2.back_category_id= t1.category_level4_id
    AND t2.source_type= "OLD"
LEFT JOIN datawarehouse_max.dim_merchant_daily_full t3
    ON t3.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") -6 -30, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
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




/*
商家品类Top门店
*/

-- DROP TABLE IF EXISTS changsha_mct_cat4_store_top_daily_asc;
-- CREATE TABLE IF NOT EXISTS changsha_mct_cat4_store_top_daily_asc (
-- 	mall_id BIGINT COMMENT "商城id"
-- 	,category_level1_id BIGINT COMMENT "一级类目ID"
-- 	,category_level4_id BIGINT COMMENT "四级类目id"
-- 	,category_level4_name STRING COMMENT "四级类目名称"
-- 	,merchant_id BIGINT COMMENT "商家id"
-- 	,merchant_name STRING COMMENT "商家名称"
-- 	,customer_store_id BIGINT COMMENT "店铺id"
-- 	,customer_store_name STRING COMMENT "店铺名称"
--     ,store_type  STRING COMMENT "门店类型"
-- 	,province_id BIGINT COMMENT "省id"
-- 	,province_name STRING COMMENT "省名称"
-- 	,city_id BIGINT COMMENT "市id"
-- 	,city_name STRING COMMENT "市名称"
-- 	,county_id BIGINT COMMENT "区县id"
-- 	,county_name STRING COMMENT "区县名称"
-- 	,grid_id BIGINT COMMENT "网格ID"
-- 	,grid_name STRING COMMENT "网格名称"
-- 	,bd_id BIGINT COMMENT "BDID"
-- 	,bd_name STRING COMMENT "BD姓名"
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
-- TBLPROPERTIES('comment'='商家四级类目Top门店数据统计');



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


,dim_dates AS(
    SELECT
        t1.dt
    FROM datawarehouse_max.dim_date_full t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
)


,temp AS (

    SELECT /*+ MAPJOIN(t0) */
        DATEADD(DATE(t0.dt), + 1, "dd") AS dt
        ,t1.merchant_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.customer_store_id
        ,t1.mall_id
        ,SUM(IF(
            t1.dt BETWEEN DATEADD(DATE(t0.dt), - 30, "dd")
                AND DATEADD(DATE(t0.dt), - 1, "dd")
            ,t1.refund_amt_by_asdt, 0
        )) AS refund_amt_30d_by_asdt
        ,COUNT(DISTINCT IF(
            t1.dt BETWEEN DATEADD(DATE(t0.dt), - 30, "dd")
                AND DATEADD(DATE(t0.dt), - 1, "dd")
                AND t1.after_sale_num_by_asdt > 0
            , t1.dt, NULL
        )) AS applied_after_sale_cnt_30d_by_asdt
        ,SUM(IF(
            t1.dt BETWEEN DATEADD(DATE(t0.dt),- 30, "dd")
                AND DATEADD(DATE(t0.dt),- 1, "dd")
            ,t1.delivered_goods_amt, 0
        )) AS delivered_goods_amt_30d
        ,COUNT(IF(
            t1.dt BETWEEN DATEADD(DATE(t0.dt),- 30, "dd")
                AND DATEADD(DATE(t0.dt), - 1, "dd")
                AND t1.ordered_goods_num > 0
            ,t1.dt, NULL
        )) AS ordered_cnt_30d
    FROM(
        SELECT
            t1.dt
            ,t2.merchant_id
            ,t1.category_level1_id
            ,t1.category_level4_id
            ,t1.customer_store_id
            ,t1.mall_id
            ,t1.final_refund_amt AS refund_amt_by_asdt
            ,t1.delivered_goods_amt
            ,t1.ordered_goods_num
            ,t1.after_sale_num AS after_sale_num_by_asdt
        FROM datawarehouse_max.dws_store_mall_store_sku_base_daily_asc t1
        LEFT JOIN datawarehouse_max.dim_goods_daily_full t2
            ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") -6 -30, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 1, "dd")
            AND t2.dt = t1.dt
            AND t2.mall_id = t1.mall_id
            AND t2.sku_id = t1.sku_id
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") -6 -30, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 1, "dd")
            AND t1.mall_id = 871
            AND NVL(t1.final_refund_amt,0) + NVL(t1.delivered_goods_amt, 0)
                + NVL(t1.ordered_goods_num, 0) > 0
            AND ISNOTNULL(t1.sku_id)
            AND ISNOTNULL(t1.customer_store_id)
    ) t1
    JOIN dim_dates  t0
        ON t1.dt BETWEEN DATEADD(DATE(t0.dt), - 30, "dd")
            AND DATEADD(DATE(t0.dt),  - 1, "dd")

    GROUP BY DATEADD(DATE(t0.dt), + 1, "dd")
        ,t1.merchant_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.customer_store_id
        ,t1.mall_id

)

,base AS(
    SELECT
        t1.mall_id -- "商城id" BIGINT
        ,t1.category_level1_id -- "一级类目ID" BIGINT
        ,t1.category_level4_id -- "四级类目id" BIGINT
        ,t02.category_level4_name -- "四级类目名称" STRING
        ,t1.merchant_id -- "商家id" BIGINT
        ,t01.merchant_name -- "商家名称" STRING
        ,t1.customer_store_id -- "店铺id" BIGINT
        ,t2.customer_store_name -- "店铺名称" STRING
        ,t2.store_type_desc AS store_type -- "门店类型" STRING
        ,t2.province_id -- "省id" BIGINT
        ,t2.province_name -- "省名称" STRING
        ,t2.city_id -- "市id" BIGINT
        ,REGEXP_REPLACE(t2.city_name, "\\d", "") AS city_name -- "市名称" STRING
        ,t2.county_id -- "区县id" BIGINT
        ,t2.county_name -- "区县名称" STRING
        ,t2.grid_id -- "网格ID" BIGINT
        ,t2.grid_name -- "网格名称" STRING
        ,t2.bd_id -- "BDID" BIGINT
        ,t2.bd_name -- "BD姓名" STRING
        
        ,t1.ordered_cnt_30d -- "近30天下单频次" BIGINT
        ,t1.delivered_goods_amt_30d-- "近30天货值" DECIMAL(10,2)
        ,t1.applied_after_sale_cnt_30d_by_asdt AS applied_after_sale_cnt_30d -- "近30天售后频次" BIGINT
        ,t1.refund_amt_30d_by_asdt -- "近30天赔付金额" DECIMAL(10,2)
        ,ROUND(
            t1.applied_after_sale_cnt_30d_by_asdt / t1.ordered_cnt_30d, 6
        ) AS applied_after_sale_ratio_by_ordered -- "近30天售后频次占比" DECIMAL(10,6)

        ,ROW_NUMBER()OVER(
            PARTITION BY t1.dt, t1.mall_id, t1.category_level1_id, t1.category_level4_id, t1.merchant_id
                ORDER BY t1.applied_after_sale_cnt_30d_by_asdt / t1.ordered_cnt_30d DESC
        ) applied_after_sale_ratio_by_ordered_desc_rnk -- "售后频次占比倒序排名" BIGINT
        ,ROW_NUMBER()OVER(
            PARTITION BY t1.dt, t1.mall_id, t1.category_level1_id, t1.category_level4_id, t1.merchant_id
                ORDER BY t1.delivered_goods_amt_30d DESC
        ) AS delivered_goods_amt_30d_desc_cnk -- "总货值倒序排名" BIGINT
        ,t1.dt
    FROM temp t1
    LEFT JOIN datawarehouse_max.dim_store_daily_full t2
        ON t2.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.customer_store_id = t1.customer_store_id
    LEFT JOIN datawarehouse_max.dim_merchant_daily_full  t01
        ON t01.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t01.dt = t1.dt
        AND t01.merchant_id = t1.merchant_id
        AND t01.mall_id = t1.mall_id
    LEFT JOIN datawarehouse_max.dim_category_daily_full t02
        ON t02.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t02.dt = t1.dt
        AND t02.back_category_id = t1.category_level4_id
        AND t02.source_type= "OLD"

    WHERE 
        t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
        
)

INSERT OVERWRITE TABLE changsha_mct_cat4_store_top_daily_asc PARTITION (dt)
SELECT
	t1.mall_id -- "商城id" BIGINT
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

FROM base t1
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND t1.delivered_goods_amt_30d_desc_cnk <= 20
    AND t1.mall_id = 871

UNION ALL

SELECT
	t1.mall_id -- "商城id" BIGINT
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

	,t1.applied_after_sale_ratio_by_ordered_desc_rnk AS store_rnk -- "排名" BIGINT
    ,"ASTop20" AS top_type -- "头部类型" STRING
    ,t1.dt

FROM base t1
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND t1.applied_after_sale_ratio_by_ordered_desc_rnk <= 20
    AND t1.mall_id = 871

;





/*
商家四级类目统计
*/



-- DROP TABLE IF EXISTS changsha_mct_cat4_stat_daily_asc;
-- CREATE TABLE IF NOT EXISTS changsha_mct_cat4_stat_daily_asc (
-- mall_id STRING COMMENT "商城id"
-- 	,merchant_id BIGINT COMMENT "商家id"
-- 	,merchant_name STRING COMMENT "商家名称"
-- 	,merchant_type STRING COMMENT "商家类型"
-- 	,category_level1_id BIGINT COMMENT "一级类目id"
-- 	,category_level1_name STRING COMMENT "一级类目名称"
-- 	,category_level4_id BIGINT COMMENT "四级类目id"
-- 	,category_level4_name STRING COMMENT "四级类目名称"
--     ,onshelved_sku_num BIGINT COMMENT "上架商品数量"
-- 	,exposed_store_num BIGINT COMMENT "曝光店铺数"
-- 	,clicked_store_num BIGINT COMMENT "点击店铺数"
-- 	,added_store_num BIGINT COMMENT "加购店铺数"
-- 	,ordered_store_num BIGINT COMMENT "下单店铺数"
-- 	,ordered_goods_num BIGINT COMMENT "下单件数"
-- 	,delivered_goods_amt DECIMAL(10,2) COMMENT "货值"
-- 	,delivered_goods_num BIGINT COMMENT "件数"
-- 	,commission_amt DECIMAL(10,2) COMMENT "平台抽佣金额"
-- 	,subsidy_amt_plat DECIMAL(10,2) COMMENT "平台补贴费用"
--     ,applied_after_sale_ticket_num_by_asdt BIGINT COMMENT "提交售后单数量"
-- 	,refund_amt_by_asdt_plat DECIMAL(10,2) COMMENT "平台承担售后赔付金额售后提交日"
--     ,applied_after_sale_ticket_num_by_asdt_info STRING COMMENT "提交售后类型售后单数量" 
--     ,applied_after_sale_type_info STRING COMMENT "售后问题类型详情"
-- 	,applied_store_num_by_asdt BIGINT COMMENT "提交日售后门店数"
-- 	,rebuy_store_num_cdta26d_applied_asdt BIGINT COMMENT "售后七日复购店铺数"
-- 	,rebuy_store_num_cdta2d_applied_asdt BIGINT COMMENT "售后三日复购店铺数"
-- 	,refund_amt DECIMAL(10,2) COMMENT "售后赔付金额"
-- 	,applied_after_sale_goods_num BIGINT COMMENT "售后商品数量"
--     ,refund_amt_by_mct DECIMAL(10,2) COMMENT'商家承担赔付金额'
-- 	,delivered_goods_amt_pg DECIMAL(10,2) COMMENT "件单价"
-- 	,ordered_goods_num_ps DECIMAL(10,1) COMMENT "客均件数"
-- 	,delivered_goods_amt_ps DECIMAL(10,2) COMMENT "客均货值"
-- 	,shared_links_cnt BIGINT COMMENT "BD分享次数"
-- 	,shared_links_store_num BIGINT COMMENT "BD分享触达店铺数"
-- 	,exposed_store_num_by_share_links BIGINT COMMENT "BD分享曝光店铺数"
-- 	,clicked_store_num_by_share_links BIGINT COMMENT "点击BD分享链接店铺数"
-- 	,ordered_store_num_by_share_links BIGINT COMMENT "有BD分享下单的店铺数"
-- 	,pool_num_new_store BIGINT COMMENT "新客户池"
-- 	,pool_num_old_store BIGINT COMMENT "老客户池"
-- 	,pool_num_loss_store BIGINT COMMENT "召回客户池"
-- 	,exposed_store_num_old_store BIGINT COMMENT "老客户曝光店铺数"
-- 	,exposed_store_num_loss_store BIGINT COMMENT "召回客户曝光店铺数"
-- 	,exposed_store_num_new_store BIGINT COMMENT "新客户曝光店铺数"
-- 	,ordered_store_num_old_store BIGINT COMMENT "老客户下单店铺数"
-- 	,ordered_store_num_loss_store BIGINT COMMENT "召回客户下单店铺数"
-- 	,ordered_store_num_new_store BIGINT COMMENT "新客户下单店铺数"
-- 	,delivered_goods_amt_new_store_mmf DECIMAL(10,2) COMMENT "商家新客营销费用贡献货值"
-- 	,mct_market_fee_amt_new_store DECIMAL(10,2) COMMENT "商家新客营销费用"
-- 	,delivered_goods_amt_loss_store_mmf DECIMAL(10,2) COMMENT "商家召回客营销费用贡献货值"
-- 	,mct_market_fee_amt_loss_store DECIMAL(10,2) COMMENT "商家召回客户营销费用"
-- 	,ordered_store_ratio_by_cat1 DECIMAL(10,6) COMMENT "日活覆盖率"
-- 	,ordered_store_ratio_by_cat1_rnk BIGINT COMMENT "日活覆盖率排名"
-- 	,exposed_store_num_desc_rnk_by_mall BIGINT COMMENT "曝光门店数降序排名"
-- 	,exposed2ordered_store_ratio DECIMAL(10,6) COMMENT "曝光转化率"
-- 	,exposed2ordered_store_ratio_desc_rnk_by_mall BIGINT COMMENT "曝光转化率降序排名"
-- 	,exposed2ordered_store_ratio_desc_rnk_by_mall_cat4 BIGINT COMMENT "同品类曝光转化率降序排名"
-- 	,exposed2ordered_store_ratio_desc_rnk_by_cat4 BIGINT COMMENT "跨中心仓同品类曝光转化率降序排名"
-- 	,exposed2ordered_store_ratio_desc_rnk_by_non BIGINT COMMENT "跨中心仓曝光转化率降序排名"
-- 	,exposed_store_ratio_by_mall DECIMAL(10,6) COMMENT "曝光门店数占商城比例"
-- 	,exposed_store_ratio_by_mall_desc_rnk_by_cat4 BIGINT COMMENT "跨仓曝光门店数占商城比例降序排名"
-- 	,exposed_store_ratio_by_cat4 DECIMAL(10,6) COMMENT "曝光门店数占四级类目比例"
-- 	,exposed_store_ratio_by_cat4_desc_rnk_by_mall_cat4 BIGINT COMMENT "同品类曝光门店数占四级类目比例降序排名"
-- 	,exposed_store_ratio_by_cat4_desc_rnk_by_cat4 BIGINT COMMENT "同品类曝光门店数占四级类目比例降序排名"
-- )PARTITIONED BY 
-- (
--     dt STRING COMMENT "日期"
-- )
-- TBLPROPERTIES('comment'='商家四级类目统计');






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
        ,t1.merchant_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.category_level4_name
        ,t1.is_up_today
        ,CASE
            WHEN
                INSTR(t1.merchant_name, "老顽童") + INSTR(t1.merchant_name, "阿玲")>0 AND t1.mall_id = 871
            THEN "全品类商家"
            WHEN
                INSTR(t1.merchant_name, "老顽童") + INSTR(t1.merchant_name, "阿玲")=0 AND t1.mall_id = 871
            THEN "商家"
            ELSE t1.merchant_type_desc
        END AS merchant_type -- "商家类型" STRING

    FROM datawarehouse_max.dim_goods_daily_full t1
    JOIN mall t0
        ON t0.mall_id = t1.mall_id
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


,subsidies_temp AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t3.merchant_id
        ,t3.category_level1_id
        ,t3.category_level4_id
        ,t1.customer_store_id
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
        ,t3.merchant_id
        ,t3.category_level1_id
        ,t3.category_level4_id
        ,t1.customer_store_id
)
,subsides AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.merchant_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        -- 优惠券
        ,SUM(
            NVL(t1.plat_coupon_market_fee, 0)
        ) AS plat_coupon_market_fee
        -- 平台补贴
        ,SUM(t1.plat_subsidy_amount) AS plat_subsidy_amount
    FROM subsidies_temp t1
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")

    GROUP BY t1.dt
        ,t1.mall_id
        ,t1.merchant_id
        ,t1.category_level1_id
        ,t1.category_level4_id
)


,css_base AS(
    SELECT
        t1.dt
        ,t2.category_level1_id
        ,t2.category_level4_id
        ,t1.mall_id
        ,t2.merchant_id
        ,t1.customer_store_id
        ,t1.after_sale_no
        ,t1.company_bear_refund_amt
        ,t1.seller_bear_refund_amt
        ,t1.after_sale_type_problem_title
    FROM datawarehouse_max.dwt_order_after_sale_daily_asc t1
    LEFT JOIN dim_sku t2
        ON t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.sku_id = t1.sku_id
    
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
        AND t1.status != "CANCEL"

)

,css_type_info AS(
    SELECT
        t1.dt
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.mall_id
        ,t1.merchant_id
        , "[" || WM_CONCAT(", ", t1.applied_after_sale_type_item) || "]" AS applied_after_sale_type_info
    FROM(
        SELECT
            t1.dt
            ,t1.category_level1_id
            ,t1.category_level4_id
            ,t1.mall_id
            ,t1.merchant_id
            ,t1.after_sale_type_problem_title

            ,COUNT(DISTINCT t1.after_sale_no) AS applied_after_sale_ticket_num_asdt
            ,SUM(t1.company_bear_refund_amt) AS company_bear_refund_amt
            ,SUM(t1.seller_bear_refund_amt) AS seller_bear_refund_amt
            ,"{"
                || '"售后问题类型": "' || t1.after_sale_type_problem_title || '",'
                || '"提交售后单数量": ' || COUNT(DISTINCT t1.after_sale_no) || ","
                || '"商家承担售后赔付金额": ' || SUM(t1.seller_bear_refund_amt)
            || "}" AS applied_after_sale_type_item
        FROM css_base t1
        GROUP BY t1.dt
            ,t1.category_level1_id
            ,t1.category_level4_id
            ,t1.mall_id
            ,t1.merchant_id
            ,t1.after_sale_type_problem_title
    ) t1
    GROUP BY t1.dt
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.mall_id
        ,t1.merchant_id
)

,css_temp AS (
    SELECT
        t1.dt
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.mall_id
        ,t1.merchant_id
        ,t1.customer_store_id
        ,COUNT(DISTINCT t1.after_sale_no) AS applied_after_sale_ticket_num_by_asdt -- "申请售后单量" BIGINT
        ,SUM(NVL(t1.company_bear_refund_amt, 0)) AS refund_amt_by_asdt_plat -- '平台承担赔付金额
        
    FROM css_base t1
    GROUP BY t1.dt
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.merchant_id
        ,t1.mall_id
        ,t1.customer_store_id


)


,css AS(
    SELECT
        t1.dt
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.mall_id
        ,t1.merchant_id
        ,SUM(t1.applied_after_sale_ticket_num_by_asdt) AS applied_after_sale_ticket_num_by_asdt -- "提交售后单数量" BIGINT
        ,SUM(t1.refund_amt_by_asdt_plat) AS refund_amt_by_asdt_plat -- '平台承担赔付金额
        ,COUNT(DISTINCT t1.customer_store_id) AS applied_store_num_by_asdt -- "售后门店数量" BIGINT
    FROM css_temp t1
    GROUP BY t1.dt
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.mall_id
        ,t1.merchant_id
)

,dt_css AS(
    SELECT
        DATE(t1.order_create_time) AS dt
        ,t1.mall_id
        ,t2.merchant_id
        ,t2.category_level1_id
        ,t2.category_level4_id
            
        ,SUM(NVL(t1.seller_bear_refund_amt, 0)) AS refund_amt_by_mct -- '商家承担赔付金额' DECIMAL(10,2)
        ,COUNT(DISTINCT t1.customer_store_id) AS applied_store_num -- "售后门店数量" BIGINT
    FROM datawarehouse_max.dwt_order_after_sale_daily_asc t1
    LEFT JOIN dim_sku t2
        ON t2.dt = t1.dt
        AND t2.sku_id = t1.sku_id
        AND t2.mall_id = t1.mall_id
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND DATE(t1.order_create_time) BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
            AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
        AND t1.status != "CANCEL"
    GROUP BY DATE(t1.order_create_time)
        ,t1.mall_id
        ,t2.merchant_id
        ,t2.category_level1_id
        ,t2.category_level4_id

)




,recommends_stat AS(
    SELECT
        t1.dt -- `日期`
        ,t1.mall_id -- `商城ID`
        ,t3.merchant_id
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
        ,t3.merchant_id
        ,t3.category_level1_id
        ,t3.category_level4_id
)



,css_type AS(
    SELECT 
        t1.dt -- `日期`
        ,t1.mall_id -- `商城ID`
        ,t1.merchant_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        -- ,CONCAT_WS(":", t1.after_sale_type, after_sale_type_problem_title) AS 
        ,t1.after_sale_type_problem_title AS after_sale_type
        ,COUNT(DISTINCT t1.after_sale_no) AS applied_after_sale_ticked_num
    FROM(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.sku_id

        ,t2.merchant_id
        ,t2.category_level1_id
        ,t2.category_level4_id
        
        ,t1.after_sale_no
        ,t1.after_sale_type_problem_title
    FROM datawarehouse_max.dwt_order_after_sale_daily_asc t1
    LEFT JOIN dim_sku t2
        ON  t2.dt = t1.dt
        AND t2.mall_id = t1.mall_id
        AND t2.sku_id = t1.sku_id
    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t1.mall_id = 871
        AND t1.status != "CANCEL"
    ) t1
    GROUP BY t1.dt -- `日期`
            ,t1.mall_id -- `商城ID`
            ,t1.merchant_id
            ,t1.category_level1_id
            ,t1.category_level4_id
            -- ,CONCAT_WS(":", t1.after_sale_type, after_sale_type_problem_title)
            ,t1.after_sale_type_problem_title

)


, base AS(
    SELECT
        t1.mall_id -- "商城id" STRING
        ,t1.merchant_id -- "商家id" BIGINT
        ,t1.merchant_name -- "商家名称" STRING
        ,IF(
            INSTR(t1.merchant_name, "老顽童") + INSTR(t1.merchant_name, "阿玲")>0, "全品类商家", "商家"
        ) AS merchant_type -- "商家类型" STRING
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
        
        ,t5.applied_after_sale_ticket_num_by_asdt -- "提交售后单数量" BIGINT
        ,NVL(t5.refund_amt_by_asdt_plat, 0) AS refund_amt_by_asdt_plat -- "平台承担售后赔付金额售后提交日" DECIMAL(10,2)
        ,t5.applied_store_num_by_asdt -- "提交日售后门店数" BIGINT
        ,t9.applied_after_sale_ticket_num_by_asdt_info -- "提交售后类型售后单数量" STRING
        ,t05.rebuy_store_num_cdta26d_applied_asdt -- "售后七日复购店铺数" BIGINT
        ,t05.rebuy_store_num_cdta2d_applied_asdt -- "售后三日复购店铺数" BIGINT
        ,t1.final_refund_amt_order_time AS refund_amt -- "售后赔付金额" DECIMAL(10,2)
        ,t1.after_sale_num_order_time AS applied_after_sale_goods_num -- "售后商品数量" BIGINT
        ,t10.refund_amt_by_mct -- '商家承担赔付金额' DECIMAL(10,2)

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

        ,t7.pool_num_new_store -- "老客户池" BIGINT
        ,t7.pool_num_old_store -- "新客户池" BIGINT
        ,t7.pool_num_loss_store -- "召回客户池" BIGINT
        ,t1.exposed_store_num_old_user AS exposed_store_num_old_store -- "老客户曝光店铺数" BIGINT
        ,t1.exposed_store_num_loss_user AS exposed_store_num_loss_store -- "召回客户曝光店铺数" BIGINT
        ,t1.exposed_store_num_loss_user AS exposed_store_num_new_store -- "新客户曝光店铺数" BIGINT
        ,t1.ordered_store_num_old_user AS ordered_store_num_old_store -- "老客户下单店铺数" BIGINT
        ,t1.ordered_store_num_loss_user AS ordered_store_num_loss_store -- "召回客户下单店铺数" BIGINT
        ,t1.ordered_store_num_loss_user AS ordered_store_num_new_store -- "新客户下单店铺数" BIGINT
        ,t8.delivered_goods_amt_new_store_mmf -- "商家新客营销费用贡献货值" DECIMAL(10,2)
        ,t8.mct_market_fee_amt_new_store -- "商家新客营销费用" DECIMAL(10,2)
        ,t8.delivered_goods_amt_loss_store_mmf -- "商家召回客营销费用贡献货值" DECIMAL(10,2)
        ,t8.mct_market_fee_amt_loss_store -- "商家召回客户营销费用" DECIMAL(10,2)

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
        ) AS exposed_store_num_desc_rnk_by_mall -- "曝光门店数降序排名" BIGINT
        ,ROUND(
            t1.ordered_store_num / t1.exposed_store_num, 6
        ) AS exposed2ordered_store_ratio -- "曝光转化率" DECIMAL(10,6)
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.mall_id
            ORDER BY NVL(t1.ordered_store_num / t1.exposed_store_num, 0) DESC
        ) AS exposed2ordered_store_ratio_desc_rnk_by_mall -- "曝光转化率降序排名" BIGINT
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.mall_id, t1.category_level4_id
            ORDER BY NVL(t1.ordered_store_num / t1.exposed_store_num, 0) DESC
        ) AS exposed2ordered_store_ratio_desc_rnk_by_mall_cat4 -- "同品类曝光转化率降序排名" BIGINT
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level4_id
            ORDER BY t1.ordered_store_num / t1.exposed_store_num DESC
        ) AS exposed2ordered_store_ratio_desc_rnk_by_cat4 -- "跨中心仓同品类曝光转化率降序排名" BIGINT
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level1_id
            ORDER BY t1.ordered_store_num / t1.exposed_store_num DESC
        ) AS exposed2ordered_store_ratio_desc_rnk_by_non -- "跨中心仓曝光转化率降序排名" BIGINT

        ,ROUND(
            t1.exposed_store_num / t3.exposed_store_num, 6
        ) AS exposed_store_ratio_by_mall -- "曝光门店数占商城比例" DECIMAL(10,6)
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level4_id
            ORDER BY t1.exposed_store_num / t3.exposed_store_num DESC
        ) AS exposed_store_ratio_by_mall_desc_rnk_by_cat4 -- "跨仓曝光门店数占商城比例降序排名" BIGINT
        ,ROUND(
            t1.exposed_store_num / t02.exposed_store_num, 6
        ) AS exposed_store_ratio_by_cat4 -- "曝光门店数占四级类目比例" BIGINT
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.mall_id, t1.category_level4_id
            ORDER BY t1.exposed_store_num / t02.exposed_store_num DESC
        ) AS exposed_store_ratio_by_cat4_desc_rnk_by_mall_cat4 -- "同品类曝光门店数占四级类目比例降序排名" BIGINT
        ,DENSE_RANK()OVER(
            PARTITION BY t1.dt, t1.category_level4_id
            ORDER BY t1.exposed_store_num / t02.exposed_store_num DESC
        ) AS exposed_store_ratio_by_cat4_desc_rnk_by_cat4 -- "同品类曝光门店数占四级类目比例降序排名" BIGINT
        ,t1.dt
    FROM datawarehouse_max.dws_pub_mall_merchant_category_level4_base_daily_asc t1
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
    LEFT JOIN datawarehouse_max.dws_pub_mall_category_level4_base_daily_asc t02
        ON t02.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND t02.dt = t1.dt
        AND t02.mall_id = t1.mall_id
        AND t02.category_level4_id = t1.category_level4_id
    LEFT JOIN subsides t4
        ON t4.dt = t1.dt
        AND t4.mall_id = t1.mall_id
        AND t4.category_level4_id = t1.category_level4_id
        AND t4.merchant_id = t1.merchant_id
    LEFT JOIN css t5
        ON t5.dt = t1.dt
        AND t5.mall_id = t1.mall_id
        AND t5.category_level4_id = t1.category_level4_id
        AND t5.merchant_id = t1.merchant_id
    
    LEFT JOIN (
        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.merchant_id
            ,t1.category_level4_id
            ,t1.category_level1_id
            ,COUNT(DISTINCT IF(
                t2.dt BETWEEN DATEADD(DATE(t1.dt), 0, "dd") AND DATEADD(DATE(t1.dt), 6, "dd"), 
                    t2.customer_store_id, NULL
            )) AS rebuy_store_num_cdta26d_applied_asdt -- "售后七日复购店铺数" BIGINT
            ,COUNT(DISTINCT IF(
                t2.dt BETWEEN DATEADD(DATE(t1.dt), 0, "dd") AND DATEADD(DATE(t1.dt), 2, "dd"), 
                    t2.customer_store_id, NULL
            )) AS rebuy_store_num_cdta2d_applied_asdt -- "售后三日复购店铺数" BIGINT
        FROM css_temp t1
        LEFT JOIN subsidies_temp t2
            ON t2.dt BETWEEN DATEADD(DATE(t1.dt), 0, "dd")
                AND DATEADD(DATE(t1.dt), 6, "dd")
            AND t2.mall_id = t1.mall_id
            AND t2.merchant_id = t1.merchant_id
            AND t2.category_level4_id = t1.category_level4_id
            AND t2.customer_store_id = t1.customer_store_id
        GROUP BY t1.dt
            ,t1.mall_id
            ,t1.merchant_id
            ,t1.category_level4_id
            ,t1.category_level1_id
    ) t05
        ON t05.dt = t1.dt
        AND t05.mall_id = t1.mall_id
        AND t05.merchant_id = t1.merchant_id
        AND t05.category_level4_id = t1.category_level4_id
    
    LEFT JOIN recommends_stat t6
        ON t6.dt = t1.dt
        AND t6.mall_id = t1.mall_id
        AND t6.category_level4_id = t1.category_level4_id
        AND t6.merchant_id = t1.merchant_id
    
    LEFT JOIN (
        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.category_level4_id
            ,t1.merchant_id

            ,COUNT(
                DISTINCT IF(INSTR(NVL(t1.customer_store_tag, "new"), "new")>0, t1.customer_store_id, NULL )
            ) AS pool_num_new_store
            ,COUNT(
                DISTINCT IF(INSTR(NVL(t1.customer_store_tag, "new"), "old")>0, t1.customer_store_id, NULL )
            ) AS pool_num_old_store
            ,COUNT(
                DISTINCT IF(INSTR(NVL(t1.customer_store_tag, "new"), "loss")>0, t1.customer_store_id, NULL )
            ) AS pool_num_loss_store
        FROM datawarehouse_max.dws_pub_mall_merchant_cate4_customer_tag_daily_asc t1
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        GROUP BY t1.dt
            ,t1.mall_id
            ,t1.category_level4_id
            ,t1.merchant_id
    ) t7
        ON t7.dt = t1.dt
        AND t7.mall_id = t1.mall_id
        AND t7.category_level4_id = t1.category_level4_id
        AND t7.merchant_id = t1.merchant_id
    
    LEFT JOIN (
        SELECT
            t1.dt
            ,t2.category_level1_id
            ,t2.category_level4_id
            ,t2.merchant_id
            ,871 AS mall_id

            ,SUM(t1.new_amount) AS delivered_goods_amt_new_store_mmf -- "商家新客营销费用贡献货值" DECIMAL(10,2)
            ,SUM(t1.new_market_fee) AS mct_market_fee_amt_new_store -- "商家新客营销费用" DECIMAL(10,2)

            ,SUM(t1.recall_amount) AS delivered_goods_amt_loss_store_mmf -- "商家召回客营销费用贡献货值"
            ,SUM(t1.recall_market_fee) AS mct_market_fee_amt_loss_store -- "商家召回客户营销费用" DECIMAL(10,2)
        FROM datawarehouse_max.ads_changsha_sku_dashboard_daily_asc t1
        
        LEFT JOIN dim_sku t2
            ON t2.dt = t1.dt
            AND t2.sku_id = t1.goods_id
            AND t2.mall_id = 871
        
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        GROUP BY t1.dt
            ,t2.category_level1_id
            ,t2.category_level4_id
            ,t2.merchant_id
    ) t8
        ON t8.dt = t1.dt
        AND t8.mall_id = t1.mall_id
        AND t8.category_level4_id = t1.category_level4_id
        AND t8.merchant_id = t1.merchant_id
        AND t8.category_level1_id = t1.category_level1_id
    LEFT JOIN (
        SELECT
            t1.dt
            ,t1.category_level1_id
            ,t1.category_level4_id
            ,t1.merchant_id
            ,t1.mall_id
            ,'{' ||
                WM_CONCAT(
                    ","
                    ,'"' || t1.after_sale_type || '":' || t1.applied_after_sale_ticked_num
                ) ||
            '}' AS applied_after_sale_ticket_num_by_asdt_info
        FROM css_type t1
        GROUP BY t1.dt
                ,t1.category_level1_id
                ,t1.category_level4_id
                ,t1.mall_id
                ,t1.merchant_id
    ) t9
        ON t9.dt = t1.dt
        AND t9.mall_id = t1.mall_id
        AND t9.merchant_id = t1.merchant_id
        AND t9.category_level4_id = t1.category_level4_id
    
    LEFT JOIN dt_css t10
        ON t10.dt = t1.dt
        AND t10.mall_id = t1.mall_id
        AND t10.merchant_id =t1.merchant_id
        AND t10.category_level4_id = t1.category_level4_id

    WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        AND ISNOTNULL(t1.category_level4_id)
        
)



INSERT OVERWRITE TABLE changsha_mct_cat4_stat_daily_asc PARTITION(dt)

SELECT
    t1.mall_id -- "商城id" STRING
	,t1.merchant_id -- "商家id" BIGINT
	,t1.merchant_name -- "商家名称" STRING
	,t1.merchant_type -- "商家类型" STRING
	,t1.category_level1_id -- "一级类目id" BIGINT
	,t1.category_level1_name -- "一级类目名称" STRING
	,t1.category_level4_id -- "四级类目id" BIGINT
	,t1.category_level4_name -- "四级类目名称" STRING
    ,t2.onshelved_sku_num -- "上架商品数量" BIGINT
	,t1.exposed_store_num -- "曝光店铺数" BIGINT
	,t1.clicked_store_num -- "点击店铺数" BIGINT
	,t1.added_store_num -- "加购店铺数" BIGINT
	,t1.ordered_store_num -- "下单店铺数" BIGINT
	,t1.ordered_goods_num -- "下单件数" BIGINT
	,t1.delivered_goods_amt -- "货值" DECIMAL(10,2)
	,t1.delivered_goods_num -- "件数" BIGINT
	,t1.commission_amt -- "平台抽佣金额" DECIMAL(10,2)
	,t1.subsidy_amt_plat -- "平台补贴费用" DECIMAL(10,2)
    ,t1.applied_after_sale_ticket_num_by_asdt -- "提交售后单数量" BIGINT
	,t1.refund_amt_by_asdt_plat -- "平台承担售后赔付金额售后提交日" DECIMAL(10,2)
    ,t1.applied_after_sale_ticket_num_by_asdt_info -- "提交售后类型售后单数量" STRING
    ,t3.applied_after_sale_type_info -- "售后问题类型详情" STRING
	,t1.applied_store_num_by_asdt -- "提交日售后门店数" BIGINT
	,t1.rebuy_store_num_cdta26d_applied_asdt -- "售后七日复购店铺数" BIGINT
	,t1.rebuy_store_num_cdta2d_applied_asdt -- "售后三日复购店铺数" BIGINT
	,t1.refund_amt -- "售后赔付金额" DECIMAL(10,2)
	,t1.applied_after_sale_goods_num -- "售后商品数量" BIGINT
    ,t1.refund_amt_by_mct -- '商家承担赔付金额' DECIMAL(10,2)

	,t1.delivered_goods_amt_pg -- "件单价" DECIMAL(10,2)
	,t1.ordered_goods_num_ps -- "客均件数" DECIMAL(10,1)
	,t1.delivered_goods_amt_ps -- "客均货值" DECIMAL(10,2)

	,t1.shared_links_cnt -- "BD分享次数" BIGINT
	,t1.shared_links_store_num -- "BD分享触达店铺数" BIGINT
	,t1.exposed_store_num_by_share_links -- "BD分享曝光店铺数" BIGINT
	,t1.clicked_store_num_by_share_links -- "点击BD分享链接店铺数" BIGINT
	,t1.ordered_store_num_by_share_links -- "有BD分享下单的店铺数" BIGINT

	,t1.pool_num_new_store -- "新客户池" BIGINT
	,t1.pool_num_old_store -- "老客户池" BIGINT
	,t1.pool_num_loss_store -- "召回客户池" BIGINT
	,t1.exposed_store_num_old_store -- "老客户曝光店铺数" BIGINT
	,t1.exposed_store_num_loss_store -- "召回客户曝光店铺数" BIGINT
	,t1.exposed_store_num_new_store -- "新客户曝光店铺数" BIGINT
	,t1.ordered_store_num_old_store -- "老客户下单店铺数" BIGINT
	,t1.ordered_store_num_loss_store -- "召回客户下单店铺数" BIGINT
	,t1.ordered_store_num_new_store -- "新客户下单店铺数" BIGINT
	,t1.delivered_goods_amt_new_store_mmf -- "商家新客营销费用贡献货值" DECIMAL(10,2)
	,t1.mct_market_fee_amt_new_store -- "商家新客营销费用" DECIMAL(10,2)
	,t1.delivered_goods_amt_loss_store_mmf -- "商家召回客营销费用贡献货值" DECIMAL(10,2)
	,t1.mct_market_fee_amt_loss_store -- "商家召回客户营销费用" DECIMAL(10,2)

	,t1.ordered_store_ratio_by_cat1 -- "日活覆盖率" DECIMAL(10,6)
	,t1.ordered_store_ratio_by_cat1_rnk -- "日活覆盖率排名" BIGINT
	,t1.exposed_store_num_desc_rnk_by_mall -- "曝光门店数降序排名" BIGINT
	,t1.exposed2ordered_store_ratio -- "曝光转化率" DECIMAL(10,6)
	,t1.exposed2ordered_store_ratio_desc_rnk_by_mall -- "曝光转化率降序排名" BIGINT
	,t1.exposed2ordered_store_ratio_desc_rnk_by_mall_cat4 -- "同品类曝光转化率降序排名" BIGINT
	,t1.exposed2ordered_store_ratio_desc_rnk_by_cat4 -- "跨中心仓同品类曝光转化率降序排名" BIGINT
	,t1.exposed2ordered_store_ratio_desc_rnk_by_non -- "跨中心仓曝光转化率降序排名" BIGINT

	,t1.exposed_store_ratio_by_mall -- "曝光门店数占商城比例" DECIMAL(10,6)
	,t1.exposed_store_ratio_by_mall_desc_rnk_by_cat4 -- "跨仓曝光门店数占商城比例降序排名" BIGINT
	,t1.exposed_store_ratio_by_cat4 -- "曝光门店数占四级类目比例" DECIMAL(10,6)
	,t1.exposed_store_ratio_by_cat4_desc_rnk_by_mall_cat4 -- "同品类曝光门店数占四级类目比例降序排名" BIGINT
	,t1.exposed_store_ratio_by_cat4_desc_rnk_by_cat4 -- "同品类曝光门店数占四级类目比例降序排名" BIGINT
    
    ,t1.dt
FROM base t1
LEFT JOIN (
    SELECT
        t1.dt
        ,t1.merchant_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.mall_id
        ,COUNT(DISTINCT IF(t1.is_up_today>0, t1.sku_id, NULL)) AS onshelved_sku_num -- "上架商品数量" BIGINT
    FROM dim_sku t1
    GROUP BY t1.dt
        ,t1.merchant_id
        ,t1.category_level1_id
        ,t1.category_level4_id
        ,t1.mall_id
) t2
    ON t2.dt = t1.dt
    AND t2.mall_id = t1.mall_id
    AND t2.category_level1_id = t1.category_level1_id
    AND t2.category_level4_id = t1.category_level4_id
    AND t2.merchant_id = t1.merchant_id
LEFT JOIN css_type_info t3
    ON t3.dt = t1.dt
    AND t3.mall_id = t1.mall_id
    AND t3.category_level1_id = t1.category_level1_id
    AND t3.category_level4_id = t1.category_level4_id
    AND t3.merchant_id = t1.merchant_id
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
;



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
