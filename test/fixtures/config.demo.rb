# change the below if you wish to write to different files / directories
# should be in fixtures directory already
$annotation_file = "#{File.dirname(__FILE__)}/annotations.xml"
$letters_in = "#{File.dirname(__FILE__)}/letters_orig"
$letters_in_selected = "#{File.dirname(__FILE__)}/letters_selected.txt"
$letters_out = "#{File.dirname(__FILE__)}/letters_new"
$warnings_file = "#{File.dirname(__FILE__)}/warnings.txt"

$flask_url = "server.unl.edu:port/search?limit=2000"
$anno_store_url = "server.unl.edu/annostore/annotations/"
$tei_ns = "http://www.tei-c.org/ns/1.0"

$allowed_statuses = ["Complete", "Needs Correction", "Published"]

$tei_cases = %w(
  teiHeader fileDesc titleStmt respStm publicationStmt
  addrLine seriesStmt sourceDesc persName msDesc handDesc
  encodingDesc editorialDecl listPrefixDef placeName
  msIdentifier msContents physDesc objectDesc revisionDesc
)
