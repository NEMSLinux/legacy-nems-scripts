#!/usr/bin/env php
<?php

if (!isset($argv[1])) exit('Invalid usage.' . PHP_EOL);

if (isset($argv[2]) && strlen($argv[2]) > 0) {
  $VARIABLE = trim($argv[2]);
} else {
  $VARIABLE = '';
}

switch($argv[1]) {

  case 'update':

    switch ($VARIABLE) {
      case 'platform':
        $platform['id'] = shell_exec('/usr/local/share/nems/nems-scripts/info.sh platform');
        $platform['data'] = @json_decode(@file_get_contents('https://nemslinux.com/api/platform/' . $platform['id']));
        if (isset($platform['data']->current_ver) && floatval($platform['data']->current_ver) > 0) file_put_contents('/var/www/html/inc/ver-available.txt',trim($platform['data']->current_ver));
      break;
    }
    break;

}

?>
