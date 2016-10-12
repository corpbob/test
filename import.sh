export JVM_OPTS="-Xmx1024m -Xms1024m -XX:-UseConcMarkSweepGC" 
json_dir="../ofis-slush-new-json"
/usr/local/mlcp/bin/mlcp.sh import --host localhost --port 30041 --username admin --password admin --input_file_type sequencefile --input_file_path seq_output -sequencefile_key_class    com.marklogic.contentpump.examples.SimpleSequenceFileKey -sequencefile_value_class com.marklogic.contentpump.examples.SimpleSequenceFileValue -sequencefile_value_type Text -output_collections "latest" -document_type JSON
