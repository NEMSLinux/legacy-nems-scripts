#!/usr/bin/php
<?php 
# Based in part on work by Morten Bekkelund, Jonas G. Drange and Mattias Bergsten
# Created by Robbie Ferguson for NEMS Linux
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# See: http://www.gnu.org/copyleft/gpl.html

$socket_path = "/usr/local/nagios/var/rw/live.sock";

$nems = new stdClass();

$nems->alias = trim(shell_exec('/usr/local/bin/nems-info alias'));

$custom_filters = array(
  'host_name ~ ',
);

if (file_exists($socket_path)) {

function _print_duration($start_time, $end_time)
{
                $duration = $end_time - $start_time;
                $days = $duration / 86400;
                $hours = ($duration % 86400) / 3600;
                $minutes = ($duration % 3600) / 60;
                $seconds = ($duration % 60);
                $retval = sprintf("%dd %dh %dm %ds", $days, $hours, $minutes, $seconds);
		return($retval);
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

    if($read === false) {
	$init = shell_exec('/usr/local/bin/nems-info init');
	if ($init == 0) {
	  die("NEMS is not yet initilized. Please run: sudo nems-init");
	} else {
          die("Livestatus error: ".socket_strerror(socket_last_error($sock)));
	}
    }

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

            $hosts = array();
            while ( list(, $filter) = each($custom_filters) ) {

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

               $json=queryLivestatus($query);
               $tmp = json_decode($json, true);
               if ( count($tmp) ) {
                  $hosts = array_merge($hosts, $tmp);
               }
            }
            asort($hosts);

            while ( list(, $row) = each($hosts) ) {
		$nems->down[] = array('hostname'=>$row[0],'alias'=>$row[1]);
            }

            if (!isset($nems->down)) {
		$nems->down = array();
            }

            #### HOSTS

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

               $nems->stats['hosts']['down'] = $stats[0][0];
               $nems->stats['hosts']['unreach'] = $stats[0][1];
               $nems->stats['hosts']['total'] = $stats[0][4];
            }

            #### SERVICES

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

               $nems->stats['services']['ok'] = $stats[0][0];
               $nems->stats['services']['warning'] = $stats[0][1];
               $nems->stats['services']['critical'] = $stats[0][2];
               $nems->stats['services']['unknown'] = $stats[0][3];
               $nems->stats['services']['not_ok'] = $stats[0][4];
               $nems->stats['services']['total'] = $stats[0][5];
            }


# Unhandled details

            reset($custom_filters);
            $services = array();
            while ( list(, $filter) = each($custom_filters) ) {

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

               $json=queryLivestatus($query);
               $tmp = json_decode($json, true);
               if ( count($tmp) ) {
                  $services = array_merge($services, $tmp);
               }
            }
            usort($services, "sort_by_state");

            while ( list(, $row) = each($services) ) {
                if ($row[2] == 2) {
                    $class = "critical";
                } elseif ($row[2] == 1) {
                    $class = "warning";
                } elseif ($row[2] == 3) {
                    $class = "unknown";
                }

		$duration = _print_duration($row[4], time());
		$date = date("Y-m-d H:i:s", $row[5]);
		$nems->unhandled[] = array('host'=>$row[0],'service'=>$row[1],'output'=>$row[3],'duration'=>$duration,'date'=>$date);
	    };

            if (!isset($nems->unhandled)) {
		$nems->unhandled = array();
            }
} // detect socket exists
  echo json_encode($nems);
?>
