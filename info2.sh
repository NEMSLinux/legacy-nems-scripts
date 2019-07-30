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
    if (!file_exists('/sys/class/thermal/thermal_zone0/temp')) {
      echo 0;
      break;
    }
    $temp = file_get_contents('/sys/class/thermal/thermal_zone0/temp');
    $temp = (floatval($temp));
    if ($temp > 1000) $temp = ($temp/1000); // this board logs microunits
    if ($temp > 0) {
      echo trim($temp) . PHP_EOL;
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

  case 11: // output JSON livestatus
  $socket_path = "/usr/local/nagios/var/rw/live.sock";

  $in_notification_period = shell_exec('/usr/local/bin/nems-info tv_require_notify');
  if ($in_notification_period != 1 && $in_notification_period != 2) $in_notification_period = 1; // use default setting if for some reason nems-info didn't provide the setting

  $custom_filters = array(
    'host_name ~ ',
  );

  $nems = new stdClass();
  $nems->livestatus = new stdClass();
  $nems->livestatus->hosts = new stdClass();
  $nems->livestatus->services = new stdClass();
  $nems->livestatus->unhandled = new stdClass();

function readSocket($len) {
    global $sock;
    $offset = 0;
    $socketData = '';
    
    while($offset < $len) {
        if(($data = @socket_read($sock, $len - $offset)) === false)
            return false;
    
        $dataLen = strlen ($data);
        $offset += $dataLen;
        $socketData .= $data;
        
        if($dataLen == 0)
            break;
    }
    
    return $socketData;
}

function queryLivestatus($query) {
    global $sock;
        global $socket_path;

    $sock = socket_create(AF_UNIX, SOCK_STREAM, 0);
    socket_set_option($sock, SOL_SOCKET, SO_RCVTIMEO, array('sec' => 10, 'usec' => 0));
    socket_set_option($sock, SOL_SOCKET, SO_SNDTIMEO, array('sec' => 10, 'usec' => 0));
    $result = socket_connect($sock, $socket_path);

    socket_write($sock, $query . "\n\n");

    $read = readSocket(16);

    $status = substr($read, 0, 3);
    $len = intval(trim(substr($read, 4, 11)));

    $read = readSocket($len);

    
    if($read === false)
        die("Livestatus error: ".socket_strerror(socket_last_error($sock)));
        
    if($status != "200")
        die("Livestatus error: ".$read);
    
    if(socket_last_error($sock) == 104)
        die("Livestatus error: ".socket_strerror(socket_last_error($sock)));

    $result = socket_close($sock);
    
    return $read;

}


function sort_by_state($a, $b) {
   if ( $a[2] == $b[2] ) {
      if ( $a[0] > $b[0] ) {
         return 1;
      }
      else if ( $a[0] < $b[0] ) {
         return -1;
      }
      else {
         return 0;
      }
   }
   else if ( $a[2] > $b[2] ) {
      return -1;
   }
   else {
      return 1;
   }
}


            $hosts = array();
            while ( list(, $filter) = each($custom_filters) ) {

if ($in_notification_period == 1) {
$query = <<<"EOQ"
GET hosts
Columns: host_name alias
Filter: $filter
Filter: scheduled_downtime_depth = 0
Filter: in_notification_period = 1
Filter: acknowledged = 0
Filter: host_acknowledged = 0
Filter: hard_state != 0
OutputFormat: json
ResponseHeader: fixed16
EOQ;
} else {
$query = <<<"EOQ"
GET hosts
Columns: host_name alias
Filter: $filter
Filter: scheduled_downtime_depth = 0
Filter: acknowledged = 0
Filter: host_acknowledged = 0
Filter: hard_state != 0
OutputFormat: json
ResponseHeader: fixed16
EOQ;
}
               $json=queryLivestatus($query);
               $tmp = json_decode($json, true);
               if ( count($tmp) ) {
                  $hosts = array_merge($hosts, $tmp);
               }
            }
            asort($hosts);
  $nems->livestatus->unhandled->hosts = $hosts;

            #### HOSTS
            $nems->livestatus->hosts->down = 0;
            $nems->livestatus->hosts->unreach = 0;
            $nems->livestatus->hosts->total = 0;

            reset($custom_filters);
            while ( list(, $filter) = each($custom_filters) ) {
$query = <<<"EOQ"
GET hosts
Filter: $filter
Stats: hard_state = 1
Stats: hard_state = 2
Stats: hard_state = 3
Stats: hard_state != 0
Stats: hard_state >= 0
OutputFormat: json
ResponseHeader: fixed16
EOQ;

               $json=queryLivestatus($query);
               $stats = json_decode($json, true);

               $nems->livestatus->hosts->down += $stats[0][0];
               $nems->livestatus->hosts->unreach += $stats[0][1];
               $nems->livestatus->hosts->total += $stats[0][4];
            }

            $nems->livestatus->hosts->down_pct = round($nems->livestatus->hosts->down / $nems->livestatus->hosts->total * 100, 2);
            $nems->livestatus->hosts->unreach_pct = round($nems->livestatus->hosts->unreach / $nems->livestatus->hosts->total * 100, 2);
            $nems->livestatus->hosts->up = $nems->livestatus->hosts->total - ($nems->livestatus->hosts->down + $nems->livestatus->hosts->unreach);
            $nems->livestatus->hosts->up_pct = round($nems->livestatus->hosts->up / $nems->livestatus->hosts->total * 100, 2);


            #### SERVICES

            $nems->livestatus->services->ok = 0;
            $nems->livestatus->services->critical = 0;
            $nems->livestatus->services->warning = 0;
            $nems->livestatus->services->unknown = 0;
            $nems->livestatus->services->not_ok = 0;
            $nems->livestatus->services->total = 0;

            reset($custom_filters);
            while ( list(, $filter) = each($custom_filters) ) {
$query = <<<"EOQ"
GET services
Filter: $filter
Filter: state_type = 1
Stats: state = 0
Stats: state = 1
Stats: state = 2
Stats: state = 3
Stats: state >= 1
Stats: state >= 0
OutputFormat: json
ResponseHeader: fixed16
EOQ;

               $json=queryLivestatus($query);
               $stats = json_decode($json, true);

               $nems->livestatus->services->ok += $stats[0][0];
               $nems->livestatus->services->warning += $stats[0][1];
               $nems->livestatus->services->critical += $stats[0][2];
               $nems->livestatus->services->unknown += $stats[0][3];
               $nems->livestatus->services->not_ok += $stats[0][4];
               $nems->livestatus->services->total += $stats[0][5];
            }

            $nems->livestatus->services->critical_pct = round($nems->livestatus->services->critical / $nems->livestatus->services->total * 100, 2);
            $nems->livestatus->services->warning_pct = round($nems->livestatus->services->warning / $nems->livestatus->services->total * 100, 2);
            $nems->livestatus->services->unknown_pct = round($nems->livestatus->services->unknown / $nems->livestatus->services->total * 100, 2);
            $nems->livestatus->services->ok_pct = round($nems->livestatus->services->ok / $nems->livestatus->services->total * 100, 2);

            reset($custom_filters);
            $services = array();
            while ( list(, $filter) = each($custom_filters) ) {

if ($in_notification_period == 1) {
$query = <<<"EOQ"
GET services
Columns: host_name description state plugin_output last_hard_state_change last_check
Filter: $filter
Filter: scheduled_downtime_depth = 0
Filter: host_scheduled_downtime_depth = 0
Filter: service_scheduled_downtime_depth = 0
Filter: in_notification_period = 1
Filter: host_acknowledged = 0
Filter: acknowledged = 0
Filter: state != 0
Filter: state_type = 1
OutputFormat: json
ResponseHeader: fixed16
EOQ;
} else {
$query = <<<"EOQ"
GET services
Columns: host_name description state plugin_output last_hard_state_change last_check
Filter: $filter
Filter: scheduled_downtime_depth = 0
Filter: host_scheduled_downtime_depth = 0
Filter: service_scheduled_downtime_depth = 0
Filter: host_acknowledged = 0
Filter: acknowledged = 0
Filter: state != 0
Filter: state_type = 1
OutputFormat: json
ResponseHeader: fixed16
EOQ;
}
               $json=queryLivestatus($query);
               $tmp = json_decode($json, true);
               if ( count($tmp) ) {
                  $services = array_merge($services, $tmp);
               }
            }
            usort($services, "sort_by_state");
  $nems->livestatus->unhandled->services = $services;
  echo json_encode($nems->livestatus);

  break;

  case 12:
    while (stristr($temper = shell_exec('/usr/local/share/nems/nems-scripts/temper.py --json'),'error')) {
    }
    print_r($temper);

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
