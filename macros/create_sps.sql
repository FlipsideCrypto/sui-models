{% macro create_sps() %}
    {% if target.database == 'SUI' %}
        CREATE schema IF NOT EXISTS _internal;
{{ sp_create_prod_clone('_internal') }};
    {% endif %}
{% endmacro %}

{% macro enable_search_optimization(
        schema_name,
        table_name,
        condition = ''
    ) %}
    {% if target.database == 'SUI' %}
    ALTER TABLE
        {{ schema_name }}.{{ table_name }}
    ADD
        search optimization {{ condition }}
    {% endif %}
{% endmacro %}
