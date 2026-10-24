/*
商品统计
*/



DROP TABLE IF EXISTS changsha_sku_stat_daily_asc;
CREATE TABLE IF NOT EXISTS changsha_sku_stat_daily_asc (
	mall_id STRING COMMENT "商城id"
	,sku_id BIGINT COMMENT "商品ID"
	,sku_name STRING COMMENT "商品名称"
	,merchant_id BIGINT COMMENT "商家id"
	,merchant_name STRING COMMENT "商家名称"
	,merchant_type STRING COMMENT "商家类型"
	,updated_video_gap BIGINT COMMENT "最近更新视频天数"
	,updated_main_pic_gap BIGINT COMMENT "最近更新主图图片天数"
	,is_updated_merit BIGINT COMMENT "是否卖点更新"
	,merit STRING COMMENT "商品卖点"
	,origin_place STRING COMMENT "产地"
	,product_class STRING COMMENT "等级"
	,product_spec STRING COMMENT "规格"
	,product_variety STRING COMMENT "品种"
	,brand_name STRING COMMENT "品牌"
	,category_level1_id BIGINT COMMENT "一级类目id"
	,category_level1_name STRING COMMENT "一级类目名称"
	,category_level4_id BIGINT COMMENT "四级类目id"
	,category_level4_name STRING COMMENT "四级类目名称"
    ,is_onshelved BIGINT COMMENT "当日是否上架"
    ,is_valid BIGINT COMMENT "是否有效SKU"
    ,onshelved_cnt_7d BIGINT COMMENT "7日内上架天数"
    ,commission_rate_conf  DECIMAL(10,4) COMMENT "配置商品抽佣率"
    ,price_old  DECIMAL(10,2) COMMENT "老客价"
    ,price_new  DECIMAL(10,2) COMMENT "新客价"
    ,price_loss  DECIMAL(10,2) COMMENT "召回客户价"
	,exposed_store_num BIGINT COMMENT "曝光店铺数"
	,clicked_store_num BIGINT COMMENT "点击店铺数"
	,added_store_num BIGINT COMMENT "加购店铺数"
	,ordered_store_num BIGINT COMMENT "下单店铺数"
	,ordered_goods_num BIGINT COMMENT "下单件数"
	,delivered_goods_amt DECIMAL(10,2) COMMENT "货值"
	,delivered_goods_num BIGINT COMMENT "件数"

	,commission_amt DECIMAL(10,2) COMMENT "平台抽佣金额"
	,subsidy_amt_plat DECIMAL(10,2) COMMENT "平台补贴费用"
    ,applied_after_sale_ticket_num_by_asdt BIGINT COMMENT "申请售后单数量"
	,refund_amt_by_asdt_plat DECIMAL(10,2) COMMENT "平台承担售后赔付金额售后提交日"
    ,applied_after_sale_ticket_num_by_asdt_info STRING COMMENT "售后类型申请数量"
	,applied_store_num_by_asdt BIGINT COMMENT "提交日售后门店数"
	,rebuy_store_num_cdta6d_applied_asdt BIGINT COMMENT "售后七日复购店铺数"
	,rebuy_store_num_cdta2d_applied_asdt BIGINT COMMENT "售后三日复购店铺数"
	,refund_amt DECIMAL(10,2) COMMENT "售后赔付金额"
	,applied_after_sale_goods_num BIGINT COMMENT "售后商品数量"
    ,refund_amt_by_mct DECIMAL(10,2) COMMENT'商家承担赔付金额'
	,delivered_goods_amt_pg DECIMAL(10,2) COMMENT "件单价"
	,ordered_goods_num_ps DECIMAL(10,1) COMMENT "客均件数"
	,delivered_goods_amt_ps DECIMAL(10,2) COMMENT "客均货值"

	,shared_links_cnt BIGINT COMMENT "BD分享次数"
	,shared_links_store_num BIGINT COMMENT "BD分享触达店铺数"
	,exposed_store_num_by_share_links BIGINT COMMENT "BD分享曝光店铺数"
	,clicked_store_num_by_share_links BIGINT COMMENT "点击BD分享链接店铺数"
	,ordered_store_num_by_share_links BIGINT COMMENT "有BD分享下单的店铺数"

	,pool_num_new_store BIGINT COMMENT "新客户池"
	,pool_num_old_store BIGINT COMMENT "老客户池"
	,pool_num_loss_store BIGINT COMMENT "召回客户池"
	,exposed_store_num_old_store BIGINT COMMENT "老客户曝光店铺数"
	,exposed_store_num_loss_store BIGINT COMMENT "召回客户曝光店铺数"
	,exposed_store_num_new_store BIGINT COMMENT "新客户曝光店铺数"
	,ordered_store_num_old_store BIGINT COMMENT "老客户下单店铺数"
	,ordered_store_num_loss_store BIGINT COMMENT "召回客户下单店铺数"
	,ordered_store_num_new_store BIGINT COMMENT "新客户下单店铺数"
	,delivered_goods_amt_new_store_mmf DECIMAL(10,2) COMMENT "商家新客营销费用贡献货值"
	,mct_market_fee_amt_new_store DECIMAL(10,2) COMMENT "商家新客营销费用"
	,delivered_goods_amt_loss_store_mmf DECIMAL(10,2) COMMENT "商家召回客营销费用贡献货值"
	,mct_market_fee_amt_loss_store DECIMAL(10,2) COMMENT "商家召回客户营销费用"
    ,applied_as_store_num_new_store BIGINT COMMENT "新客户售后门店数"
    ,rebuy_applied_as_store_num_cdta6d_new_store BIGINT COMMENT "新客户售后近七日复购门店数"
    ,rebuy_applied_as_store_num_cdta2d_new_store BIGINT COMMENT "新客户售后三日复购门店数"
    ,applied_as_store_num_loss_store BIGINT COMMENT "召回客户售后门店数"
    ,rebuy_applied_as_store_num_cdta6d_loss_store BIGINT COMMENT "召回客户售后近七日复购门店数"
    ,rebuy_applied_as_store_num_cdta2d_loss_store BIGINT COMMENT "召回客户售后三日复购门店数"
    ,applied_as_store_num_old_store BIGINT COMMENT "老客户售后门店数"
    ,rebuy_applied_as_store_num_cdta6d_old_store BIGINT COMMENT "老客户售后近七日复购门店数"
    ,rebuy_applied_as_store_num_cdta2d_old_store BIGINT COMMENT "老客户售后三日复购门店数"
	,invalid_sku_type STRING COMMENT "无效SKU类型"
	,potential_sku_type STRING COMMENT "潜力SKU类型"
        
	,store_num_by_ordered_30d_info STRING COMMENT "近30天不同下单频次店铺数"
	,logon_store_num_by_ordered_30d_info STRING COMMENT "近30天不同下单频次登陆店铺数"
	,exposed_store_num_by_ordered_30d_info STRING COMMENT "近30天不同下单频次曝光店铺数"
	,ordered_store_num_by_ordered_30d_info STRING COMMENT "近30天不同下单频次下单店铺数"
	,store_num_by_exposed_30d_info STRING COMMENT "近30天曝光不同频次门店数"
	,logon_store_num_by_exposed_30d_info STRING COMMENT "近30天曝光不同频次登陆门店数"
	,exposed_store_num_by_exposed_30d_info STRING COMMENT "近30天曝光不同频次曝光门店数"
	,ordered_store_num_by_exposed_30d_info STRING COMMENT "近30天曝光不同频次下单门店数"
    ,delivered_goods_amt_with_pmf  DECIMAL(10,2) COMMENT "平台营销费用产生货值"
    ,exposed2ordered_store_ratio_new_store_rnk_by_mall_cat4  BIGINT COMMENT "同品类新客户曝光转化率排名"
    ,ordered_item_ticket_num  BIGINT COMMENT "明细订单数量"
    ,attach_detail  STRING COMMENT "附件信息"
	,delivered_goods_amt_desc_rnk_by_mall_cat4 BIGINT COMMENT "同商城同品类货值排名"
	,ordered_store_num_desc_rnk_by_mall_cat4 BIGINT COMMENT "同商城同品类下单店铺数排名"
	,ordered_store_ratio_by_cat1 DECIMAL(10,6) COMMENT "日活覆盖率"
	,ordered_store_ratio_by_cat1_rnk BIGINT COMMENT "日活覆盖率排名"
	,exposed_store_num_desc_rnk_by_mall BIGINT COMMENT "曝光门店数降序排名"
	,exposed2ordered_store_ratio DECIMAL(10,6) COMMENT "曝光转化率"
	,exposed2ordered_store_ratio_desc_rnk_by_mall BIGINT COMMENT "曝光转化率降序排名"
	,exposed2ordered_store_ratio_desc_rnk_by_mall_cat4 BIGINT COMMENT "同品类曝光转化率降序排名"
	,exposed2ordered_store_ratio_desc_rnk_by_mall_cat4_mct BIGINT COMMENT "同品类同商家曝光转化率降序排名"
	,exposed2ordered_store_ratio_desc_rnk_by_cat4 BIGINT COMMENT "跨中心仓同品类曝光转化率降序排名"
	,exposed2ordered_store_ratio_desc_rnk_by_non BIGINT COMMENT "跨中心仓曝光转化率降序排名"

	,exposed_store_ratio_by_mall DECIMAL(10,6) COMMENT "曝光门店数占商城比例"
	,exposed_store_ratio_by_mall_desc_rnk_by_cat4 BIGINT COMMENT "跨仓曝光门店数占商城比例降序排名"
	,exposed_store_ratio_by_cat4 DECIMAL(10,6) COMMENT "曝光门店数占四级类目比例"
	,exposed_store_ratio_by_cat4_desc_rnk_by_mall_cat4 BIGINT COMMENT "同品类曝光门店数占四级类目比例降序排名"
	,exposed_store_ratio_by_cat4_desc_rnk_by_cat4 BIGINT COMMENT "同品类曝光门店数占四级类目比例降序排名"
)PARTITIONED BY 
(
    dt STRING COMMENT "日期"
)
TBLPROPERTIES('comment'='商品统计');




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
            ON DATE(TO_DATE(t2.pt, "yyyyMMdd000000")) BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
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


,store_stat AS(
    SELECT
        t1.dt
        ,t1.mall_id
        ,t1.customer_store_id
        ,t1.sku_id
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
            ,t1.sku_id
            ,t1.ordered_days_30d
            ,t1.exposed_days_30d
            ,NULL AS exposed_cnt
            ,NULL AS ordered_goods_num
        FROM datawarehouse_max.dws_store_mall_store_sku_feature_daily_asc t1
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
            AND t1.mall_id = 871
            AND ISNOTNULL(t1.customer_store_id) AND ISNOTNULL(t1.sku_id)
            AND NVL(t1.ordered_days_30d,0) + NVL(t1.exposed_days_30d, 0) > 0

        UNION

        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.customer_store_id
            ,t1.sku_id
            
            ,0 AS ordered_days_30d
            ,0 AS exposed_day_30d
            ,t1.exposed_cnt
            ,t1.ordered_goods_num
        FROM datawarehouse_max.dws_store_mall_store_sku_base_daily_asc  t1
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
        ,t1.sku_id
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
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
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
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
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


,css_tag_rebuy AS(
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
    FROM css_tag t1
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
    
    LEFT JOIN (
        SELECT
            t1.dt
            ,t1.mall_id
            ,t1.sku_id
            ,COUNT(
                DISTINCT IF(INSTR(NVL(t1.customer_store_tag, "new"), "new")>0, t1.customer_store_id, NULL )
            ) AS pool_num_new_store
            ,COUNT(
                DISTINCT IF(INSTR(NVL(t1.customer_store_tag, "new"), "old")>0, t1.customer_store_id, NULL )
            ) AS pool_num_old_store
            ,COUNT(
                DISTINCT IF(INSTR(NVL(t1.customer_store_tag, "new"), "loss")>0, t1.customer_store_id, NULL )
            ) AS pool_num_loss_store
        FROM store_tag t1
        WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
                    AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
        GROUP BY  t1.dt
            ,t1.mall_id
            ,t1.sku_id
        

    ) t7
        ON t7.dt = t1.dt
        AND t7.mall_id = t1.mall_id
        AND t7.sku_id = t1.sku_id
    
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

LEFT JOIN css_tag_rebuy t4
    ON t4.dt = t1.dt
    AND t4.mall_id = t1.mall_id
    AND t4.sku_id = t1.sku_id
WHERE t1.dt BETWEEN DATEADD(TO_DATE("${dt}"), BIGINT("${offset}") - 6, "dd")
        AND DATEADD(TO_DATE("${dt}"), BIGINT("${offset}"), "dd")
    AND t1.mall_id = 871
;