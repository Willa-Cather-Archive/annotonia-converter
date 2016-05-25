<?php
  include "config.php";
  include "helpers.php";
?>

<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <title>Annotonia Letters</title>
    <meta name="viewport" content="width=device-width">
    <link rel="stylesheet" href="https://rosie.unl.edu/annotonia/assets/css/bootstrap.css">
    <link rel="stylesheet" href="https://rosie.unl.edu/annotonia/assets/css/main.css">
    <script src="https://rosie.unl.edu/annotonia/assets/js/vendor/modernizr-2.6.2-respond-1.1.0.min.js"> </script>

  </head>
  <body>
    <div class="navbar">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
          <span class="icon-bar">
            <span class="icon-bar">
              <span class="icon-bar">
              </span>
            </span>
          </span>
          </button>
          <a class="navbar-brand" href="#">Annotonia Letters</a>
        </div>
        <div class="navbar-collapse collapse">
          <ul class="nav navbar-nav">
            <li><a href="https://rosie.unl.edu/annotonia/">Home</a></li>
            <li><a href="https://rosie.unl.edu/annotonia/about.html">About</a></li>
            <li><a href="https://rosie.unl.edu/annotonia_status">Status</a></li>
            <li class="status"><a href="https://rosie.unl.edu/annotonia_status/letters.php">Letters</a></li>
          </ul>
        </div>
      </div>
    </div>
    <div class="container">
      <h4>Status of Annotations</h4>

      <div class="results">
      <?php 
        // GET a request to the flask url for the requested tag (or no tags if all annotations)
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $flask_url);
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

        $files = scandir("/var/local/www/cocoon/annotonia/xml/letters");

        foreach ($files as $file) {
          $xml = simplexml_load_file("/var/local/www/cocoon/annotonia/xml/letters/" . $file);
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
