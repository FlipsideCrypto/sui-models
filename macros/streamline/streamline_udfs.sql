{% macro create_udf_bulk_rest_api_v2() %}
    CREATE
    OR REPLACE EXTERNAL FUNCTION streamline.udf_bulk_rest_api_v2(
        json OBJECT
    ) returns ARRAY {% if target.database == 'SUI' -%}
        api_integration = aws_sui_api_prod_v2 AS 'https://nqj8j7ln67.execute-api.us-east-1.amazonaws.com/prod/udf_bulk_rest_api'
    {% else %}
        api_integration = aws_sui_api_stg_v2 AS 'https://azbc07ki8d.execute-api.us-east-1.amazonaws.com/stg/udf_bulk_rest_api'
    {%- endif %}
{% endmacro %}
