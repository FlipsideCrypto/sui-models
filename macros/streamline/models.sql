{% macro streamline_external_table_query(
        model,
        partition_function
) %}
WITH meta AS (
    SELECT
        job_created_time AS _inserted_timestamp,
        file_name,
        {{ partition_function }} AS partition_key
    FROM
        TABLE(
            information_schema.external_table_file_registration_history(
                start_time => DATEADD('day', -3, CURRENT_TIMESTAMP()),
                table_name => '{{ source( "bronze_streamline", model) }}')
            ) A
)
SELECT
    s.*,
    b.file_name,
    b._inserted_timestamp
FROM
    {{ source(
        "bronze_streamline",
        model
    ) }}
    s
JOIN 
    meta b
    ON b.file_name = metadata$filename
    AND b.partition_key = s.partition_key
WHERE
    b.partition_key = s.partition_key
    
{% endmacro %}

{% macro streamline_external_table_query_fr(
        model,
        partition_function
) %}
WITH meta AS (
    SELECT
       registered_on AS _inserted_timestamp,
        file_name,
        {{ partition_function }} AS partition_key
    FROM
        TABLE(
            information_schema.external_table_files(
                table_name => '{{ source( "bronze_streamline", model) }}'
            )
        ) A
)
SELECT
    s.*,
    b.file_name,
    b._inserted_timestamp
FROM
    {{ source(
        "bronze_streamline",
        model
    ) }}
    s
JOIN 
    meta b
    ON b.file_name = metadata$filename
    AND b.partition_key = s.partition_key
WHERE
    b.partition_key = s.partition_key
    
{% endmacro %}