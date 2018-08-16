#!/usr/bin/php
<?php
 /*
  This is where all the PHP scripts are for nems-info.
  These are called with the nems-info command, not direct.
 */

if (!isset($argv[1])) exit('Invalid usage. Please use the nems-info command.' . PHP_EOL);

switch($argv[1]) {

  case 1: // temperature
   if (file_exists('/var/log/nems/thermal.log')) {
     echo file_get_contents('/var/log/nems/thermal.log');
   } else {
     echo 0 . PHP_EOL;
   }
  break;

  case 2: // NEMS Version Branch (exclude microversion)
    $ver = floatval(shell_exec('/usr/local/bin/nems-info nemsver'));
    echo $ver . PHP_EOL;
  break;

  case 3: // Find the board platform ID number
    if (!file_exists('/var/log/nems/hw_model')) shell_exec('/usr/local/share/nems/nems-scripts/hw_model.sh'); // try to detect
    if (file_exists('/var/log/nems/hw_model')) { // was reporting 0 (pi 1) when file didn't exist
      $tmp = file('/var/log/nems/hw_model');
      if ( $tmp[0] == 0 && strtolower(substr($tmp[1],0,14)) == strtolower('Unknown Device') ) $tmp[0] = 98000; // Unknown
    } else {
      $tmp[0] = 98000; // NEMS' "unknown" ID
    }
    echo $tmp[0];
  break;

  case 4: // Load the platform data from the API
    $platform['id'] = shell_exec('/usr/local/share/nems/nems-scripts/info.sh platform');
    if (!file_exists('/tmp/platform_data')) {
      if (file_exists('/var/log/nems/hw_model')) { // try to get it from the hw_model file
        $tmp = file('/var/log/nems/hw_model');
        $platform['data'] = new stdclass();
        $platform['data']->name = trim($tmp[1]);
      } else { // try to get it from the online API
        $platform['data'] = @json_decode(@file_get_contents('https://nemslinux.com/api/platform/' . $platform['id']));
      }
      if (is_object($platform['data']) && strlen($platform['data']->name) > 0) {
        file_put_contents('/tmp/platform_data',$platform['data']->name);
        chmod('/tmp/platform_data',0444);
      }
    } else {
      $platform['data']=new stdclass();
      $platform['data']->name=file_get_contents('/tmp/platform_data');
    }
    if (isset($platform['data'])) {
      echo $platform['data']->name;
    } else {
      echo '[API Did Not Respond]';
    }
  break;

  case 5:
    $ver = floatval(shell_exec('/usr/local/bin/nems-info nemsver'));
    if ($ver >= 1.4) { // EVERYTHING 1.4+
      $logdir = '/var/log/nems/phoronix/';
      $logfile = 'composite.xml';
      $loglist = array_filter(explode(PHP_EOL,shell_exec('find ' . $logdir . ' -iname ' . $logfile)));
      $tests = array(
        'smallpt',
        'himeno',
        'ramspeed',
        'iozone'
      );
      if (!isset($argv[2]) || !in_array($argv[2],$tests)) {
        echo "Usage: nems-info phoronix [smallpt|himeno|ramspeed|iozone]" . PHP_EOL;
        exit();
      }
      if (is_array($loglist)) {
        foreach ($loglist as $file) {
          $tmp = explode($logdir,$file);
          $tmp = array_filter(explode($logfile,$tmp[1]));
          $date = strtotime(str_replace('/','',$tmp[0]));
          $logs[$date] = $file;
        }
        if (is_array($logs)) {
          ksort($logs); // sort to ensure oldest is first (so value overwrites)

          function check_test($title,$tests) {
            if (is_array($tests)) { // checking array (list of tests)
              foreach($tests as $test) {
                if (strpos(strtolower($title), $test) !== false) {
                  return true;
                }
	      }
            } else { // checking string (one specific test)
                if (strpos(strtolower($title), $tests) !== false) {
                  return true;
                }
            }
            return false;
          }

          foreach ($logs as $date => $log) {
            $data = new SimpleXMLElement(file_get_contents($log));
            if (check_test(strtolower($data->Result->Title),$tests)) {
              if (check_test(strtolower($data->Result->Title),$argv[2])) {
                $count=0; foreach ($data->Result as $dataresult) { $count++; } // YES, I am being lazy.
                foreach ($data->Result as $dataresult) {
		  if ($count > 1) { // use the one labeled "average"
                    if (check_test(strtolower($dataresult->Description),'average')) {
                      $result = floatval($dataresult->Data->Entry->Value);
                    }
                  } else {
                    $result = floatval($dataresult->Data->Entry->Value);
                  }
                }
              }
            }
          }
          if (isset($result)) {
            echo $result;
          } else {
            echo 0;
          }
        }
      } else {
        return false;
      }
    } else {
      echo 0;
    }
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
