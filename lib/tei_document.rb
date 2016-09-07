require 'fileutils'
require 'nokogiri'

class TeiDocument
  attr_reader :annotations
  attr_reader :file

  def initialize(annotations, file)
    @annotations = annotations
    @file = file
  end

  def wrap
    tei = Nokogiri::XML(tei_wrapper, &:noblanks)
    div = tei.at_css("div[type='annotations']")
    annotations.each do |anno|
      div.add_child(anno.at_css("note").to_s)
    end
    File.write("#{@file}", tei.to_xml( indent: 4 ))
  end

  def tei_wrapper
    return %{
      <?xml version="1.0" encoding="UTF-8"?>
      <?oxygen RNGSchema="http://cather.unl.edu/cat.letters.rng" type="xml"?>
      <TEI xmlns="http://www.tei-c.org/ns/1.0">
          <teiHeader>
              <fileDesc>
                  <titleStmt>
                      <title type="main">Annotations for the Complete Letters of Willa Cather</title>
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
                          <name xml:id="sa_gr">Samantha Greenfield</name>
                      </respStmt>
                      <respStmt>
                          <resp>Editorial Assistant</resp>
                          <name xml:id="em_ra">Emily Rau</name>
                      </respStmt>
                  </titleStmt>
                  <publicationStmt>
                      <authority>The Willa Cather Archive</authority>
                      <idno>cat.let.annotations</idno>
                      <address>
                          <addrLine>http://cather.unl.edu</addrLine>
                      </address>
                      <publisher>University of Nebraska&#211;Lincoln</publisher>
                      <distributor>
                          <name>Center for Digital Research in the Humanities</name>
                          <address>
                              <addrLine>319 Love Library</addrLine>
                              <addrLine>University of Nebraska&#211;Lincoln</addrLine>
                              <addrLine>Lincoln, NE 68588-4100</addrLine>
                              <addrLine>http://cdrh.unl.edu</addrLine>
                          </address>
                      </distributor>
                      <date>2015</date>
                      <availability>
                          <p>The Willa Cather Archive is freely distributed by the Center for Digital
                              Research in the Humanities at the University of Nebraska-Lincoln and
                              licensed under a Creative Commons Attribution-Noncommercial-Share Alike 3.0
                              United States License</p>
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
                          <note>This file is composed of annotations written for The Complete Letters of
                              Willa Cather project.</note>
                      </bibl>
                  </sourceDesc>
              </fileDesc>
              <encodingDesc>
                  <p>Encoded for the The Complete Letters of Willa Cather, a digital edition of Cather's
                      correspondances.</p>
                  <listPrefixDef>
                      <prefixDef ident="psn" matchPattern="([0-9]{4})"
                          replacementPattern="cat.let.personography.xml#$1">
                          <p> Private URIs using the <code>psn</code> prefix are pointers to
                                  <gi>person</gi> elements in the cat.let.personography.xml file. For
                              example, <code>psn:2365</code> dereferences to
                                  <code>cat.let.personography.xml#2365</code>. </p>
                      </prefixDef>
                      <prefixDef ident="wrk" matchPattern="([0-9]{4})"
                          replacementPattern="cat.let.works.xml#$1">
                          <p> Private URIs using the <code>wrk</code> prefix are pointers to <gi>bibl</gi>
                              elements in the cat.let.works.xml file. For example, <code>wrk:1342</code>
                              dereferences to <code>cat.let.works.xml#1342</code>. </p>
                      </prefixDef>
                      <prefixDef ident="geo" matchPattern="([0-9]{4})"
                          replacementPattern="cat.let.gazetteer.xml#$1">
                          <p> Private URIs using the <code>geo</code> prefix are pointers to
                                  <gi>place</gi> elements in the cat.let.gazetteer.xml file. For example,
                                  <code>geo:0023</code> dereferences to
                                  <code>cat.let.gazetteer.xml#0023</code>. </p>
                      </prefixDef>
                      <prefixDef ident="rep" matchPattern="([0-9]{4})"
                          replacementPattern="cat.let.repositories.xml#$1">
                          <p> Private URIs using the <code>rep</code> prefix are pointers to
                                  <gi>repository</gi> elements in the cat.let.repositories.xml file. For
                              example, <code>rep:1020</code> dereferences to
                                  <code>cat.let.repositories.xml#1020</code>. </p>
                      </prefixDef>
                      <prefixDef ident="ann" matchPattern="([0-9]{4})"
                          replacementPattern="cat.let.annotations.xml#$1">
                          <p> Private URIs using the <code>ann</code> prefix are pointers to
                                  <gi>annotation</gi> elements in the cat.let.annotations.xml file. For
                              example, <code>ann:1020</code> dereferences to
                                  <code>cat.let.annotations.xml#1020</code>. </p>
                      </prefixDef>
                      <prefixDef ident="via" matchPattern="([0-9]{4})" replacementPattern="">
                          <p> Private URIs using the <code>via</code> prefix are pointers to <gi>VIAF</gi>
                              numbers. The VIAF, or Virtual International Authority File, combines
                              multiple name authority files into a single OCLC-hosted name authority
                              service.</p>
                      </prefixDef>
                  </listPrefixDef>
              </encodingDesc>
              <revisionDesc>
                  <change when="2015-07-29" who="sa_gr">Input of additional annotations</change>
                  <change when="2015-04-08" who="ga_ki">Initial creation of XML</change>
                  <change notBefore="2015-09-01" notAfter="2016-03-04" who="#em_ra">Add and revise
                      annotations</change>
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
