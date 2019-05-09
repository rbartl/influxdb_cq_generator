# influxdb_cq_generator

Creates various Continous Queries and also backfills Data from a Database into another Database.
In each case (src -> DEST) the retention policy default is used.

WATCH OUT as this will DROP the destination Database when run.

Works in my case for a DB filled with telegraf data.
when the CQ are created this will allow to just switch from a finer to a more granular view in grafana.

only MEAN calculations are used.
