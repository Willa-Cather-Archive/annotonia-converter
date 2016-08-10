<?php
  include "config.php";
  include "helpers.php";
?>

<html>
  <?php include "head.html"; ?>

  <body>
    <?php include "navbar.html"; ?>
    <div class="container">
      <h4>Status of Annotations</h4>

      <div class="results">
      <?php 
        // GET a request to the flask url for the requested tag (or no tags if all annotations)
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $flask_url."/search");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
        $res = curl_exec($curl); 
        curl_close($curl);

        // organize the annotation responses by letter
        $annotations = json_decode($res, true);
        $anno_length = count($annotations["rows"]);

        $anno_letters = array();
        for ($i = 0; $i < $anno_length; $i++) {
          $anno = $annotations["rows"][$i];
          if (isset($anno_letters[$anno["pageID"]])) {
            array_push($anno_letters[$anno["pageID"]], $anno);
          } else {
            $anno_letters[$anno["pageID"]] = array($anno);
          }
        }

        $files = scandir($catherletters_dir);

        foreach ($files as $file) {
          $xml = simplexml_load_file($catherletters_dir . $file);
          $title = $xml->teiHeader->fileDesc->titleStmt->title;
          $id = $xml->teiHeader->fileDesc->publicationStmt->idno;
          if (preg_match("/cat\.let[0-9]{4}/i", $id)) {
            echo "<div class='letter'>";
              $id = str_replace("cat.", "", $id);
                echo "<h4><a href='" . $boilerplate_url . $id . ".html'>" . $title . "</a></h4>";
              $annotations = $anno_letters[$id];
              $anno_count = count($annotations);
              $tags = array();
              // TODO there must be a way to do an array_map but it's not working
              for ($i = 0; $i < $anno_count; $i++) {
                foreach ($annotations[$i]["tags"] as $tag) {
                  array_push($tags, $tag);
                }
              }
              echo "<a href='" . $catherletters_url . $id . ".html'>View cat. " . $id . " on the Cather site</a>";
              echo "<div>" . $anno_count . " annotation(s)</div>";
              echo "<div>" . generate_tags(array_unique($tags)) . "</div>";
            echo "</div>";
          }
        }
      ?>
      </div>
    </div>
  </body>
</html>
