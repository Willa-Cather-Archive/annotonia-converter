# change the below if you wish to write to different files / directories
$annotation_file = "#{File.dirname(__FILE__)}/annotations.xml"

# switch this path in if you wish to use letters already
# loaded into the annotonia project
# $letters_in = "/var/local/www/cocoon/annotonia/xml/letters"
$letters_in = "#{File.dirname(__FILE__)}/letters_orig"
$letters_in_selected = "#{File.dirname(__FILE__)}/letters_selected.txt"
$letters_out = "#{File.dirname(__FILE__)}/letters_new"
$warnings_file = "#{File.dirname(__FILE__)}/warnings.txt"

# If limit changed, must also change:
# RESULTS_MAX_SIZE in annotator-store/annotator/elasticsearch.py
# $flask_results_max in annotonia-status/env/config.php
$flask_limit = 10000
$flask_url = "path?limit=#{$flask_limit}"
$anno_store_url = "server/annostore/annotations/"
$tei_ns = "http://www.tei-c.org/ns/1.0"

$allowed_statuses = ["Complete", "Needs Correction", "Published"]

$tei_cases = %w(
  teiHeader fileDesc titleStmt respStm publicationStmt
  addrLine seriesStmt sourceDesc persName msDesc handDesc
  encodingDesc editorialDecl listPrefixDef placeName
  msIdentifier msContents physDesc objectDesc revisionDesc
)
