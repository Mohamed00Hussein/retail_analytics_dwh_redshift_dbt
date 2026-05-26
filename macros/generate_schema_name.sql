{#
    Overrides dbt's default schema-naming behaviour.

    Default dbt: <target_schema>_<custom_schema>  (e.g. dwh_staging)
    This version: <custom_schema> exactly         (e.g. staging)

    When a model sets +schema (custom_schema_name), that name is used as-is.
    When a model sets no custom schema, it falls back to the target schema
    from your profile (e.g. dwh).
#}
{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%} {{ default_schema }}

    {%- else -%} {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
