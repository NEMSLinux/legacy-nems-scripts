#!/usr/bin/php
<?php
  // This script logs the 15 minute load average over the course of 1 week every 15 minutes self-maintaining.
  // Then, nems-info loadaverage will tell you our load average in a much more accurate overview than just a 15 minute load average (ie., you can see an average based on the entire week, not just the moment you're running it, which may be after a reboot).

  // Get the existing log
  if (file_exists('/var/log/nems/load-average.ser')) {
    $loads = unserialize(trim(file_get_contents('/var/log/nems/load-average.ser')));
  }
  if (isset($loads) && is_array($loads) && count($loads) > ((60*24*7)/15) ) { // how many times 15 minutes goes into a week
    unset($loads[0]);
  }

  // Find the current load average over 15 minutes
  $load = sys_getloadavg();
  if (isset($load[2])) {
    $loads[] = $load[2];
    $loads = array_values($loads);
    file_put_contents('/var/log/nems/load-average.ser',serialize($loads));
  }
  if (is_array($loads)) {
    $total = 0;
    foreach ($loads as $thisload) {
      $total=($total+$thisload);
    }
    $average = ($total/count($loads));
    file_put_contents('/var/log/nems/load-average.log', $average); // this file has the current average
  }
?>
