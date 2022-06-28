WITH GLOBAL_SPINE AS (
  SELECT 
    ROW_NUMBER() OVER (
      ORDER BY 
        NULL
    ) as INTERVAL_ID, 
    DATEADD(
      'day', 
      (INTERVAL_ID - 1), 
      '2020-01-01T00:00' :: timestamp_ntz
    ) as SPINE_START, 
    DATEADD(
      'day', INTERVAL_ID, '2020-01-01T00:00' :: timestamp_ntz
    ) as SPINE_END 
  FROM 
    TABLE (
      GENERATOR(ROWCOUNT => 1097)
    )
), 
GROUPS AS (
  SELECT 
    product, 
    MIN(sales_date) AS LOCAL_START, 
    MAX(sales_date) AS LOCAL_END 
  FROM 
    My_First_Table 
  GROUP BY 
    product
), 
GROUP_SPINE AS (
  SELECT 
    product, 
    SPINE_START AS GROUP_START, 
    SPINE_END AS GROUP_END 
  FROM 
    GROUPS G CROSS 
    JOIN LATERAL (
      SELECT 
        SPINE_START, 
        SPINE_END 
      FROM 
        GLOBAL_SPINE S 
      WHERE 
        S.SPINE_START >= G.LOCAL_START
    )
) 
SELECT 
  G.product AS GROUP_BY_product, 
  GROUP_START, 
  GROUP_END, 
  T.* 
FROM 
  GROUP_SPINE G 
  LEFT JOIN My_First_Table T ON sales_date >= G.GROUP_START 
  AND sales_date < G.GROUP_END 
  AND G.product = T.product;
