#!/usr/bin/php
<?php
 /*
  This is where all the PHP scripts are for nems-info.
  These are called with the nems-info command, not direct.
 */

if (!isset($argv[1])) exit('Invalid usage. Please use the nems-info command.' . PHP_EOL);

switch($argv[1]) {
  case 1: // temperature
    $monitorix = monitorix('raspberrypi');
    if (is_array($monitorix['data']['rpi_temp0'])) {
      $tmp = 0;
      $count = 0;
      foreach ($monitorix['data']['rpi_temp0'] as $date=>$temperature) {
        if (floatval($temperature) > 0) { // Failsafe in case thermals aren't working
          $tmp = ($tmp + floatval($temperature));
          $count++;
        }
      }
      if ($tmp > 0) {
        $average_temperature = ($tmp/$count);
        echo $average_temperature . PHP_EOL;
      } else {
        echo 0 . PHP_EOL; // 0 means "unknown"
      }
    }
  break;

  case 2: // NEMS Version Branch (exclude microversion)
    $ver = floatval(shell_exec('/usr/local/bin/nems-info nemsver'));
    echo $ver . PHP_EOL;
  break;

  case 3: // Find the board platform ID number
    if (file_exists('/var/log/nems/hw_model')) { // was reporting 0 (pi 1) when file didn't exist
      $tmp = file('/var/log/nems/hw_model');
    } else {
      $tmp[0] = 98000; // NEMS' "unknown" ID
    }
    echo $tmp[0];
  break;

}




function monitorix($db) {

  switch ($db) {

    case 'apache':
      return rrd_fetch( "/var/lib/monitorix/apache.rrd", array( "AVERAGE", "--resolution", "60", "--start", "-1d", "--end", "start+1h" ) );
    break;

    case 'fs':
      return rrd_fetch( "/var/lib/monitorix/fs.rrd", array( "AVERAGE", "--resolution", "60", "--start", "-1d", "--end", "start+1h" ) );
    break;

    case 'int':
      return rrd_fetch( "/var/lib/monitorix/int.rrd", array( "AVERAGE", "--resolution", "60", "--start", "-1d", "--end", "start+1h" ) );
    break;

    case 'kern':
      return rrd_fetch( "/var/lib/monitorix/kern.rrd", array( "AVERAGE", "--resolution", "60", "--start", "-1d", "--end", "start+1h" ) );
    break;

    case 'net':
      return rrd_fetch( "/var/lib/monitorix/net.rrd", array( "AVERAGE", "--resolution", "60", "--start", "-1d", "--end", "start+1h" ) );
    break;

    case 'raspberrypi':
      return rrd_fetch( "/var/lib/monitorix/raspberrypi.rrd", array( "AVERAGE", "--resolution", "60", "--start", "-1d", "--end", "start+1h" ) );
    break;

    case 'system':
      return rrd_fetch( "/var/lib/monitorix/system.rrd", array( "AVERAGE", "--resolution", "60", "--start", "-1d", "--end", "start+1h" ) );
    break;

  }

}


?>
