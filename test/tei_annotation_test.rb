require_relative "../lib/tei_annotation"

class TestTeiAnnotation < Minitest::Test
  def test_teify
    start_text = %{
<note>
<p>This is a <i>test</i> of <br/> the <em>system</em>.</p>
<p>It has some <span style="display: none;">other stuff</span> like lists</p>
<ul><li>1</li><li>2</li></ul>
<ol><li>1</li><li>2</li></ol>
<p><span style="text-decoration: underline;">Underlined word!</span></p>
<a href="path">linktext</a>
<img src="http://big/path/to/file.jpg" alt="alttext" width="w" height="h"/>
<p><video width="1" height="2" poster="jessica" controls="controls">
  <source src="first" />
  <source src="second" />
</video></p>
</note>
    }

    after_text = %{<?xml version="1.0"?>
<note>
  <p>This is a <hi rend="italic">test</hi> of <lb/> the <hi rend="italic">system</hi>.</p>
  <p>It has some other stuff like lists</p>
  <list><item>1</item>
<item>2</item></list>
  <list rend="numbered"><item>1</item>
<item>2</item></list>
  <p>
    <hi rend="underline">Underlined word!</hi>
  </p>
  <ref type="url" target="path">linktext</ref>
  <figure corresp="file.jpg">
    <figDesc>alttext</figDesc>
  </figure>
  <p>
    <media mimeType="video/mp4" url="first" width="1"/>
  </p>
</note>
}
    note = TeiAnnotation.new(start_text)
    assert_equal note.tei.to_s, after_text
  end

  def test_nbsp
    before = %{<note><p>This advertisement appeared in the October 15, 1927,&nbsp;<em>Boston Evening Transcript</em></p></note>}
    after = %{<?xml version=\"1.0\"?>
<note>
  <p>This advertisement appeared in the October 15, 1927,&#xA0;<hi rend="italic">Boston Evening Transcript</hi></p>
</note>\n}
    note = TeiAnnotation.new(before)
    assert_equal note.tei.to_s, after
  end


end
