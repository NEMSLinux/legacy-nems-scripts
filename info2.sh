#!/usr/bin/php
<?php
 /*
  This is where all the PHP scripts are for nems-info.
  These are called with the nems-info command, not direct.
 */

if (!isset($argv[1])) exit('Invalid usage. Please use the nems-info command.' . PHP_EOL);

if (isset($argv[2]) && strlen($argv[2]) > 0) {
  $VARIABLE = trim($argv[2]);
} else {
  $VARIABLE = '';
}

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

  case 6: // list scheduled downtime
     $ch = curl_init();
	$timeout = 5;
	curl_setopt($ch, CURLOPT_URL, 'http://127.0.0.1/nems-api/downtimes');
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, $timeout);
	$data = curl_exec($ch);
	curl_close($ch);
        echo $data;
  break;

  case 7: // list detected wifi access points in json format
    $wifi = array();
    $wifitmp=shell_exec('iwlist wlan0 scan');
    $wifiarr=explode(PHP_EOL,$wifitmp);
    $count=0;
    if (is_array($wifiarr) && count($wifiarr) > 0) {
      foreach ($wifiarr as $arr) {
        $tmp = explode(':',$arr);
        if (substr(trim($tmp[0]),0,4) == 'Cell') {
	  $count++;
        } else {
          if (isset($tmp[1])) $result[$count][trim($tmp[0])] = trim($tmp[1]);
        }
      }
      if (isset($result) && count($result) > 0) {
        foreach ($result as $data) {
          if (isset($data['ESSID'])) $data['ESSID'] = str_replace('"','',$data['ESSID']);
          if (isset($data['ESSID']) && strlen($data['ESSID']) > 0) {
            $wifi[$data['ESSID']]['channel'] = $data['Channel'];
            $wifi[$data['ESSID']]['frequency'] = $data['Frequency'];
            $wifi[$data['ESSID']]['rate'] = $data['Bit Rates'];
            $wifi[$data['ESSID']]['encryption'] = $data['Encryption key'];
          }
        }
      }
    }
    echo json_encode($wifi);
  break;

  case 8: // root device
//    $fulldev=shell_exec("df /root | awk '/^\/dev/ {print $1}'");
    $fulldev=trim(shell_exec("/usr/local/bin/nems-info rootfulldev"));
    $tmp = explode('p',$fulldev);
    if (is_array($tmp)) {
      end($tmp);
      $lastkey = key($tmp);
      reset($tmp);
      foreach ($tmp as $key => $value) {
        if ($key != $lastkey) {
          $value = str_replace('/dev/','',$value);
          echo trim($value);
          if (count($tmp) > 2) echo 'p'; // actual device name contains a p in the name
        }
      }
    }
  break;

  case 9: // root partition on root device
//    $fulldev=shell_exec("df /root | awk '/^\/dev/ {print $1}'");
    $fulldev=trim(shell_exec("/usr/local/bin/nems-info rootfulldev"));
    $tmp = explode('p',$fulldev);
    if (is_array($tmp)) {
      end($tmp);
      $partkey = key($tmp);
      reset($tmp);
      foreach ($tmp as $key => $value) {
        if ($key == $partkey) {
          echo trim($value);
        }
      }
    }
  break;

  case 10: // output the recommended speedtest server number
    if ($VARIABLE == 'best') {
      exec('/usr/local/share/nems/nems-scripts/speedtest --list',$servernum_tmp);
      if (is_array($servernum_tmp)) {
        foreach ($servernum_tmp as $line) {
          $tmp = explode(')',$line);
          if (intval($tmp[0]) > 0) {
            $speedtestservers[] = array(
              'num'=>intval($tmp[0]),
            );
            break; // we only need one
          }
        }
      }
      echo $speedtestservers[0]['num'];
    } elseif ($VARIABLE == 'which') {
      $speedtestwhich = intval(trim(shell_exec("cat /usr/local/share/nems/nems.conf | grep speedtestwhich |  printf '%s' $(cut -n -d '=' -f 2)")));
      // best = most local server as detected by NEMS
      // switch = the passed server number on the check_command's arg
      if ($speedtestwhich == 0) { echo 'best'; } else { echo 'switch'; }
    } elseif ($VARIABLE == 'location') {
      $server = shell_exec('/usr/local/bin/nems-info speedtest');
      exec('/usr/local/share/nems/nems-scripts/speedtest --list',$servernum_tmp);
      if (is_array($servernum_tmp)) {
        foreach ($servernum_tmp as $line) {
          $tmp = explode(')',$line);
          if (intval($tmp[0]) == $server) {
            $speedtestservers[] = array(
              'location'=>trim($tmp[1]) . ')',
            );
            break; // we only need one
          }
        }
      }
      echo $speedtestservers[0]['location'];
    } else {
      $speedtestserver = intval(trim(shell_exec("cat /usr/local/share/nems/nems.conf | grep speedtestserver |  printf '%s' $(cut -n -d '=' -f 2)")));
      if ($speedtestserver > 0) {
        echo $speedtestserver;
      } else {
        $speedtestserver = intval(trim(shell_exec("/usr/local/bin/nems-info speedtest best")));
        file_put_contents('/usr/local/share/nems/nems.conf','speedtestserver=' . $speedtestserver . PHP_EOL, FILE_APPEND);
        echo $speedtestserver;
      }
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
