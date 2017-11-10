#!/usr/bin/php
<?php
  // This script logs the 15 minute CPU temperature over the course of 1 week every 15 minutes self-maintaining.
  // Then, nems-info tempaverage will tell you our temperature average this week.

  // This script should ONLY be called by cron, otherwise the results will be wrong!
  // If you're hoping to see the results, please use: nems-info loadaverage
  if (@$argv[1] != 'cron') exit('Do not run this script manually.' . PHP_EOL);

  $temp = (file_get_contents('/sys/class/thermal/thermal_zone0/temp')/1000);

  if ($temp > 0) {
    $thermal = array();
    if (file_exists('/var/log/nems/thermal.ser')) {
      $thermal = unserialize(trim(file_get_contents('/var/log/nems/thermal.ser')));
    }
    if (isset($thermal) && is_array($thermal) && count($thermal) > ((60*24*7)/15) ) { // how many times 15 minutes goes into a week
      unset($thermal[0]);
    }
    $thermal[] = $temp;
    file_put_contents('/var/log/nems/thermal.ser',serialize($thermal));

    $count = 0;
    $alltemps = 0;
    foreach ($thermal as $temperature) {
      $count++;
      $alltemps = ($alltemps+$temperature);
    }
    $average = ($alltemps/$count);
    file_put_contents('/var/log/nems/thermal.log', $average);
  }
?>
