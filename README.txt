The main.tf file deploys the following on a GCP project,
    (1) Enable the necessary APIs on the project.
    (2) Create a GCS bucket and upload sample data files in it from ./datasets.
    (3) Create a BigQuery dataset and table from the sample logs data. 

The ./scripts contains BigQuery scripts for the following,
    (1) Create an index on the logs data.
    (2) Query the index.
    (3) Sample scripts. 
