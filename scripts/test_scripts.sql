SELECT * from bigsearch_demo.log_data limit 1000

SELECT * from bigsearch_demo.log_data where SEARCH(Message,'218.188.2.4')