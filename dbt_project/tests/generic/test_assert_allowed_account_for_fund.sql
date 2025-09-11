{% test assert_allowed_account_for_fund(model, column_name, fund_column, allowed_accounts_map) %}
select *
from {{ model }}
where
    {% for fund, accounts in allowed_accounts_map.items() %}
        ( {{ fund_column }} = '{{ fund }}' and {{ column_name }} not in ('{{ accounts | join("', '") }}') )
        {{ "or" if not loop.last }}
    {% endfor %}
{% endtest %}