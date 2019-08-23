#!/usr/bin/php
<?php 
# Based in part on work by Morten Bekkelund, Jonas G. Drange and Mattias Bergsten
# Created by Robbie Ferguson for NEMS Linux
# This version outputs the state of all hosts/services, regardless of state
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
Columns: host_name alias address check_command display_name hard_state is_flapping last_check state services_with_info
Filter: $filter
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
                // services with info
                if (is_array($row[9])) foreach ($row[9] as $service) {
                  $services[] = array(
                    'service'=>$service[0],
                    'state'=>$service[1],
                    'output'=>$service[3]
                  );
           }
		$nems->hosts[] = array(
'host_name'=>$row[0],
'alias'=>$row[1],
'address'=>$row[2],
'check_command'=>$row[3],
'display_name'=>$row[4],
'hard_state'=>$row[5],
'is_flapping'=>$row[6],
'last_check'=>$row[7],
'state'=>$row[8],
'services'=>$services,

);
            }

            if (!isset($nems->hosts)) {
		$nems->hosts = array();
            }
}
  echo json_encode($nems);
?>
