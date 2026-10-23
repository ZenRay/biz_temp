/*
ads_mall_daily
*/

SELECT
    t1.*
FROM changsha_mall_stat_daily_asc t1

WHERE t1.dt BETWEEN DATEADD(${date_param}, ${start_offset} , "dd")
            AND DATEADD(${date_param},  ${end_offset}, "dd")
    AND t1.mall_id = 871
    
;


/*
ads_mall_cat1_daily
*/

SELECT
    t1.*
FROM changsha_mall_cat1_stat_daily_asc t1
WHERE t1.dt BETWEEN DATEADD(${date_param}, ${start_offset} , "dd")
            AND DATEADD(${date_param},  ${end_offset}, "dd")
    AND t1.mall_id = 871
    AND INSTR(t1.category_level1_name, "水果") > 0
;



/*
ads_category_daily
*/
SELECT
    t1.*
FROM changsha_cat4_stat_daily_asc t1
WHERE t1.dt BETWEEN DATEADD(${date_param}, ${start_offset} , "dd")
            AND DATEADD(${date_param},  ${end_offset}, "dd")
    AND t1.mall_id = 871
    AND INSTR(t1.category_level1_name, "水果") > 0
;



/*
ads_merchant_category_daily
*/

SELECT
    t1.*
FROM changsha_mct_cat4_stat_daily_asc t1
WHERE t1.dt BETWEEN DATEADD(${date_param}, ${start_offset} , "dd")
            AND DATEADD(${date_param},  ${end_offset}, "dd")
    AND t1.mall_id = 871
    AND INSTR(t1.category_level1_name, "水果") > 0
    AND t1.onshelved_sku_num > 0
;


/*
ads_top_store_sku_daily
*/

SELECT
    t1.*
FROM changsha_sku_top_daily_asc t1
WHERE t1.dt BETWEEN DATEADD(${date_param}, ${end_offset} - 1 , "dd")
            AND DATEADD(${date_param},  ${end_offset}, "dd")
    AND  t1.mall_id = 871
    AND t1.store_rnk <= 20

;



/*
ads_sku_daily
*/
SELECT
    t1.*
FROM changsha_sku_stat_daily_asc t1
WHERE t1.dt BETWEEN DATEADD(${date_param}, ${start_offset} , "dd")
            AND DATEADD(${date_param},  ${end_offset}, "dd")
    AND t1.mall_id = 871
    AND t1.category_level4_name IN ("秋月梨", "蜜桔", "红富士苹果")
    
;


/*
ads_sku_county_daily
*/
SELECT
    t1.*
FROM changsha_sku_county_stat_daily_asc t1
WHERE t1.dt BETWEEN DATEADD(${date_param}, ${end_offset}- 1, "dd")
            AND DATEADD(${date_param},  ${end_offset}, "dd")
    AND t1.mall_id = 871
    AND t1.category_level4_name IN ("秋月梨","蜜桔", "红富士苹果")
    -- AND t1.onshelved_cnt_7d > 0
;




/*
ads_top_all_daily
*/
SELECT
    t1.*
FROM changsha_top_total_stat_daily_asc t1
WHERE t1.dt BETWEEN DATEADD(${date_param}, ${start_offset} , "dd")
            AND DATEADD(${date_param},  ${end_offset}, "dd")
    AND t1.mall_id = 871
;


/*
ads_county_daily
*/

SELECT
    t1.*
FROM changsha_county_daily_asc t1
WHERE t1.dt BETWEEN DATEADD(${date_param}, ${end_offset} - 1 , "dd")
            AND DATEADD(${date_param},  ${end_offset}, "dd")
    AND t1.mall_id = 871

;


/*
ads_merchant_category_daily
*/
SELECT
    t1.*
FROM changsha_mct_cat4_county_stat_daily_asc t1
WHERE t1.dt BETWEEN DATEADD(${date_param}, ${end_offset} - 1, "dd")
            AND DATEADD(${date_param},  ${end_offset}, "dd")
    AND t1.mall_id = 871
;


/*
ads_category_county_daily
*/
SELECT
    t1.*
FROM changsha_cat4_county_stat_daily_asc t1
WHERE t1.dt BETWEEN DATEADD(${date_param}, ${end_offset} - 1 , "dd")
            AND DATEADD(${date_param},  ${end_offset}, "dd")
    AND t1.mall_id = 871
;