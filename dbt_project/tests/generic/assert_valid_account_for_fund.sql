{#
    Custom generic test to assert that, for specific fund codes, only certain
    account codes are allowed. dbt passes `column_name` automatically for
    column-level tests; accept it here (unused) to avoid kwarg errors.
#}
{% test assert_valid_account_for_fund(model, fund_business_key_column, account_business_key_column, allowed_mappings, column_name=None) %}
select *
from {{ model }}
where
{% for fund_code, allowed_accounts in allowed_mappings.items() %}
(
    {{ fund_business_key_column }} = '{{ fund_code }}'
    and {{ account_business_key_column }} not in (
        {% for account in allowed_accounts %}
            '{{ account }}'{% if not loop.last %}, {% endif %}
        {% endfor %}
    )
)
{% if not loop.last %}or{% endif %}
{% endfor %}
{% endtest %}