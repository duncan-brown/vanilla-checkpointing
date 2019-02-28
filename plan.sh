#!/bin/bash

mkdir -p output

pegasus-plan -Dpegasus.workflow.root.uuid=cdf2d39d-a15b-4399-8160-8f02301bd271 \
  -Dpegasus.catalog.transformation.file=tc.txt \
  -Dpegasus.dir.storage.mapper.replica=File \
  -Dpegasus.dir.storage.mapper.replica.file=main.map \
  --conf pegasus.properties \
  --dir `pwd` \
  --relative-dir ./test_condorio-main_ID0000001
  --relative-submit-dir ./test_condorio-main_ID0000001 \
  --sites local 
  --cluster label,horizontal
  --output-site local --cleanup none --verbose  --verbose  --verbose  \
  --deferred --group pegasus --dax testworkflow.dax
