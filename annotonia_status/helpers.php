<?php
  function get_color($row_type) {
    $colors = array(
      "Needs Correction" => "label-danger",
      "Needs Annotation" => "label-warning",
      "Draft" => "label-info",
      "Complete" => "label-primary",
      "Published" => "label-success"
    );
    return $colors[$row_type];
  }

  function generate_tags($tags) {
    $tag_length = count($tags);
    $html = "";
    for ($i = 0; $i < $tag_length; $i++) {
       $tag = $tags[$i];
       $type = get_color($tag);
       $html .= "<span class='label " . $type . "'>" . $tag . "</span>";
    }
    return $html;
  }
?>
