{#
    rfm_score
    ---------
    Assigns a quantile score (1..buckets) to a metric using NTILE. This is
    the building block for RFM (Recency, Frequency, Monetary) segmentation:
    call it once per dimension in a model.

    Args:
        column_name : expression to score (e.g. days_since_last_order)
        order       : 'asc'  -> smaller raw value gets the HIGHER score
                              (use for recency: fewer days = better)
                      'desc' -> larger raw value gets the HIGHER score
                              (use for frequency & monetary)
        buckets     : number of quantiles, defaults to 5 (classic RFM)

    Usage:
        {{ rfm_score('days_since_last_order', order='asc') }}  as recency_score
        {{ rfm_score('order_count',           order='desc') }} as frequency_score
        {{ rfm_score('total_spend',           order='desc') }} as monetary_score

        the human explaination if you hate the formalities
        this micro or fn orders the customers tables and divide them into 5 groups and each group gets a score of 5
        for example you order customers on thier last order date ,the most recent 20% of customers will get 5 points score 
        while last 20% who hasn't order lately will get only 1 point
        
#}

{% macro rfm_score(column_name, order='desc', buckets=5) %}
    ntile({{ buckets }}) over (
        order by {{ column_name }} {{ 'asc' if order == 'asc' else 'desc' }}
    )
{% endmacro %}
