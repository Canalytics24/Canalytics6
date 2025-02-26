WITH repayments_master AS (
  SELECT loan_id,
         payment_status,
         COUNT(DISTINCT repayment_id) AS no_of_payments,
         COALESCE(SUM(amount_paid),0) AS amount_paid
  FROM repayments
  GROUP By loan_id, payment_status
), pre_final AS ( 
  SELECT loans.customer_id,
       customers.customer_name,
       loans.loan_id,
       loan_term_months,
       CASE WHEN payment_status = 'Missed' THEN SUM(no_of_payments) ELSE 0 END AS no_missd_payments,
       COALESCE(SUM(loan_amount),0) AS total_loan_amount,
       COALESCE(SUM(amount_paid),0) AS amount_paid
  FROM loans LEFT JOIN customers ON customers.customer_id = loans.customer_id
  LEFT JOIN repayments_master ON loans.loan_id = repayments_master.loan_id
  GROUP BY loans.customer_id, customers.customer_name, loans.loan_id, loan_term_months, payment_status
)
SELECT customer_id,
       customer_name,
       loan_id,
       loan_term_months,
       COALESCE(SUM(total_loan_amount),0) AS total_loan_amount,
       COALESCE(SUM(amount_paid),0) AS amount_paid,
       COALESCE(SUM(total_loan_amount),0) - COALESCE(SUM(amount_paid),0) AS outstanding_amount,
       ROUND(((COALESCE(SUM(total_loan_amount),0) - COALESCE(SUM(amount_paid),0))/NULLIF(SUM(total_loan_amount),0))*100,2) AS percent
FROM pre_final
WHERE loan_term_months > 12
GROUP BY customer_id, customer_name, loan_id, loan_term_months
HAVING ROUND(((COALESCE(SUM(total_loan_amount),0) - COALESCE(SUM(amount_paid),0))/NULLIF(SUM(total_loan_amount),0))*100,2) > 50
AND SUM(no_missd_payments) >= 2
