<?php
  include "config.php";
  
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

  function make_link($tag, $search = null) {
    $search = $search ? $search : $tag;
    $html = "";
    $class = ($_GET["tag"] == $search ? 'active' : 'inactive');
    $html .= "<li role='presentation' class='" . $class . "'>";
    if ($tag == "") {
      $html .= "<a href='" . $GLOBALS["status_link_url"] . "''>All Annotations</a>";
    } else {
      $html .= "<a href='" . $GLOBALS["status_link_url"] . "?tag=" . $search . "''>" . $tag . "</a>";
    }
    $html .= "</li>";
    return $html;
  }
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

    <style>
      .quote {
        background-color:yellow;
      }
      .text {
        font-size:.8em;
        background-color:lightgrey;
        font-family: Consolas, monaco, monospace;
      }
      .annotation {
        border-bottom: solid 1px #AAA;
      }
    </style>

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
            <li class="active"><a href="https://rosie.unl.edu/annotonia_status">Status</a></li>
          </ul>
        </div>
      </div>
    </div>
    <div class="container">
      <h4>Status of Annotations</h4>

      <div class="navbar">
        <ul class="nav nav-pills">
          <?php echo make_link(""); ?>
          <?php echo make_link("Needs Correction", "Correction"); ?>
          <?php echo make_link("Needs Annotation", "Annotation"); ?>
          <?php echo make_link("Draft"); ?>
          <?php echo make_link("Complete"); ?>
          <?php echo make_link("Published"); ?>
        </ul>
      </div>

      <div class="results">
      <?php 
        // GET a request to the flask url for the requested tag (or no tags if all annotations)
        $curl = curl_init();
        $url = (isset($_GET["tag"]) ? $flask_url . "?tags=" . $_GET["tag"] : $flask_url);
        $url = str_replace(" ", "%20", $url);
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
        $res = curl_exec($curl); 
        curl_close($curl);

        // Parse json and display results
        $annotations = json_decode($res, true);
        $anno_length = count($annotations["rows"]);
        echo "<h4>" . $anno_length . " result(s) found</h4>";
        echo "<div class='list'>";
        for ($i = 0; $i < $anno_length; $i++) {
          echo "<div class='annotation'>";
            $row = $annotations["rows"][$i];
            $tag_html = generate_tags($row["tags"]);
            echo "<h5>Letter Id: " . $row["pageID"] . "</h5>";
            echo "<div class='row'>";
              echo "<div class='col-md-6'>";
                echo $tag_html . " ";
                echo "<br/>Annotation Id: " . $row["id"] . "<br/>";
                if (isset($row["pageID"])) {
                  echo "<a href='" . $boilerplate_url . $row["pageID"] . ".html'>Boilerplate</a>";
                  echo " | <a href='" . $catherletters_url . $row["pageID"] . ".html'>Cather Site</a>";
                } else {
                  echo "No links available for nonexistent id";
                }
              echo "</div>";
              echo "<div class='col-md-6'>";
                echo "Highlight: <span class='quote'>" . $row["quote"] . "</span>";
                echo "<br/>Annotation: <div class='text'>" . htmlspecialchars($row["text"]) . "</div>";
              echo "</div>";
            echo "</div>";
          echo "</div>";
        }
        echo "</div>"
      ?>
      </div>
    </div>
  </body>
</html>
