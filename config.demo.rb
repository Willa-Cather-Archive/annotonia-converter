# change the below if you wish to write to different files / directories
$annotation_file = "#{File.dirname(__FILE__)}/annotations.txt"
$letters_in = "#{File.dirname(__FILE__)}/letters_orig"
$letters_out = "#{File.dirname(__FILE__)}/letters_new"
$warnings_file = "#{File.dirname(__FILE__)}/warnings.txt"

$flask_url = ""
$tei_ns = "http://www.tei-c.org/ns/1.0"

$tei_cases = %w(
  teiHeader fileDesc titleStmt respStm publicationStmt
  addrLine seriesStmt sourceDesc persName msDesc handDesc
  encodingDesc editorialDecl listPrefixDef placeName
  msIdentifier msContents physDesc objectDesc revisionDesc
)
