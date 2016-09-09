require 'fileutils'
require 'nokogiri'

class TeiDocument
  attr_reader :annotations
  attr_reader :tei_content

  def initialize(annotations)
    @annotations = annotations
  end

  def date
    return Time.now.strftime("%Y-%m-%d")
  end

  def wrap
    tei = Nokogiri::XML(tei_wrapper(date), &:noblanks)
    div = tei.at_css("div[type='annotations']")
    annotations.each do |anno|
      div.add_child(anno.at_css("note").to_s)
    end
    @tei_content = tei
    return @tei_content
  end

  def tei_wrapper(change_date)
    return %{
      <?oxygen RNGSchema="http://cather.unl.edu/cat.letters.rng" type="xml"?>
      <TEI xmlns="http://www.tei-c.org/ns/1.0">
        <teiHeader>
          <fileDesc>
            <titleStmt>
              <title type="main">Individual Letter Annotations for the Complete Letters of Willa Cather</title>
              <editor role="co-editor" xml:id="awj">Andrew Jewell</editor>
              <editor role="co-editor" xml:id="ja_st">Janis Stout</editor>
              <editor role="associate_editor" xml:id="me_ho">Melissa Homestead</editor>
              <respStmt>
                <resp>Editorial Assistant</resp>
                <name xml:id="ga_ki">Gabi Kirilloff</name>
              </respStmt>
              <respStmt>
                <resp>Editorial Assistant</resp>
                <name xml:id="ca_be">Caterina Bernardini</name>
              </respStmt>
              <respStmt>
                <resp>Editorial Assistant</resp>
                <name xml:id="je_te">Jessica Tebo</name>
              </respStmt>
              <respStmt>
                <resp>Editorial Assistant</resp>
                <name xml:id="lo_ne">Lori Nevole</name>
              </respStmt>
              <respStmt>
                <resp>Editorial Assistant</resp>
                <name xml:id="em_ra">Emily Rau</name>
              </respStmt>
            </titleStmt>
            <publicationStmt>
              <authority>The Willa Cather Archive</authority>
              <idno>cat.let.ind-annotations</idno>
              <address>
                <addrLine>http://cather.unl.edu</addrLine>
              </address>
              <publisher>University of Nebraska-Lincoln</publisher>
              <distributor>
                <name>Center for Digital Research in the Humanities</name>
                <address>
                  <addrLine>319 Love Library</addrLine>
                  <addrLine>University of Nebraska-Lincoln</addrLine>
                  <addrLine>Lincoln, NE 68588-4100</addrLine>
                  <addrLine>http://cdrh.unl.edu</addrLine>
                </address>
              </distributor>
              <date>2018</date>
              <availability>
                <p>The Willa Cather Archive is freely distributed by the Center for Digital Research in the Humanities at the University of Nebraska-Lincoln and licensed under a Creative Commons Attribution-Noncommercial-Share Alike 3.0 United States License</p>
              </availability>
            </publicationStmt>
            <seriesStmt>
              <title level="m">The Complete Letters of Willa Cather</title>
              <editor role="co-editor" sameAs="#awj"/>
              <editor role="co-editor" sameAs="#ja_st"/>
              <editor role="associate_editor" sameAs="#me_ho"/>
            </seriesStmt>
            <sourceDesc>
              <bibl>
                <note>This file is composed of individual letter annotations written for The Complete Letters of Willa Cather project. The file was automatically generated from annotations written using the Annotonia tool.</note>
              </bibl>
            </sourceDesc>
          </fileDesc>
          <revisionDesc>
            <change when="#{change_date}">Automatically generated file from annotations created with Annotonia tool.</change>
          </revisionDesc>
        </teiHeader>
          <text>
              <body>
                  <div type="annotations"></div>
              </body>
          </text>
      </TEI>
      }
  end

end
