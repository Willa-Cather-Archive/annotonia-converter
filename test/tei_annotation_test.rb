require_relative "../lib/tei_annotation"

class TestTeiAnnotation < Minitest::Test
  def test_teify
    start_text = %{
<note>
<p>This is a <i>test</i> of <br/> the <i>system</i>.</p>
<p>It has some other stuff like lists</p>
<ul><li>1</li><li>2</li></ul>
<ol><li>1</li><li>2</li></ol>
<p><span style="text-decoration: underline;">Underlined word!</span></p>
<a href="path">linktext</a>
<img src="path" alt="alttext" width="w" height="h"/>
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
  <figure corresp="path">
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

end
