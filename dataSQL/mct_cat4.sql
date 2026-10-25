
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
