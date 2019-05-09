# influxdb_cq_generator

Creates various Continous Queries and also backfills Data from a Database into another Database.
In each case (src -> DEST) the retention policy default is used.

WATCH OUT as this will DROP the destination Database when run.
