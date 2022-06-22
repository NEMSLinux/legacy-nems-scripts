#!/usr/bin/env php
<?php
  if (isset($argv[1])) $test=$argv[1]; else die('This script is not made to be run manually.' . PHP_EOL);
  $data = explode(PHP_EOL,stream_get_contents(STDIN));
  if (is_array($data)) {
    foreach ($data as $key=>$line) {
      $data[$key] = trim($line);
      if ($data[$key] == '') unset($data[$key]);
    }
  } else {
    die('No data.' . PHP_EOL);
  }

  switch ($test) {

    case 'cpu':
    case 'ram':
    case 'mutex':
    case 'io':
      foreach ($data as $line) {
        // The time it took to run the test
        if ( (substr($line,0,11) == 'total time:') || (substr($line,0,13) == 'time elapsed:') ) {
          $tmp = explode(':',$line);
          $time = floatval($tmp[1]);
        }
        // The number of events during that time
        if (substr($line,0,23) == 'total number of events:') {
          $tmp = explode(':',$line);
          $events = floatval($tmp[1]);
        }
      }
      if ( isset($events) && isset($time) && ($events > 0) && ($time > 0) ) {
        $result = ($events / $time);
        echo $result;
      } else {
        echo 0;
      }
      break;

  }

?>
