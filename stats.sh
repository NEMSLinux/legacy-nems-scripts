#!/usr/bin/php
<?php
// # This is simple, anonymous stats just so Robbie knows a bit about how many systems are using NEMS.
// # This will also help me understand limitations of various platforms (ie, how many hosts can a Pi 3 handle?).
// # Please do not deactivate this unless you absolutely have to.
// # Again, it's completely anonymous, and nothing private is revealed.

  // Get the platform of your NEMS server
  $platform = trim(shell_exec('/home/pi/nems-scripts/info.sh platform'));

  // Get the number of configured hosts
  $hostdata = file('/etc/nagios3/Default_collector/hosts.cfg');
  $hosts = 0;
  if (is_array($hostdata)) foreach ($hostdata as $line) {
    if (strstr($line, 'define host')) $hosts++;
  }

  // Get the number of configured services
  $servicedata = file('/etc/nagios3/Default_collector/services.cfg');
  $services = 0;
  if (is_array($servicedata)) foreach ($servicedata as $line) {
    if (strstr($line, 'define service')) $services++;
  }

  // Get the size of your storage media
  $disksize = disk_total_space('/');
  $diskfree = disk_free_space('/');

  // Determine system uptime
  $str   = @file_get_contents('/proc/uptime');
  $num   = floatval($str);
  $secs  = floor(fmod($num, 60)); $num = intdiv($num, 60);
  $mins  = $num % 60;      $num = intdiv($num, 60);
  $hours = $num % 24;      $num = intdiv($num, 24);
  $days  = $num;

  // Get the current load average
  $load = sys_getloadavg();

  // Put it together to send to the server
  $data = array(
    'hwid'=>trim(shell_exec('/home/pi/nems-scripts/info.sh hwid')),
    'platform'=>$platform,
    'uptime_days'=>$days,
    'uptime_hours'=>$hours,
    'uptime_mins'=>$mins,
    'uptime_secs'=>$secs,
    'nemsver'=>trim(shell_exec('/home/pi/nems-scripts/info.sh nemsver')),
    'hosts'=>$hosts,
    'services'=>$services,
    'disksize'=>$disksize,
    'diskfree'=>$diskfree,
    'loadaverage'=>$load[2], // just the 15 minute average
    'timezone'=>date('T'),
  );

  // Load existing NEMS Stats API Key, if it exists
  $settings = file('/home/pi/nems.conf');
  if (is_array($settings)) {
    foreach ($settings as $line) {
      if (substr($line,0,6) == 'apikey') {
        $data['apikey'] = substr($line,7);
      }
    }
  }

  $ch = curl_init('https://nems.baldnerd.com/api/stats/');
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
  $response = curl_exec($ch);
  curl_close($ch);
  $newkey = filter_var($response,FILTER_SANITIZE_STRING);
  if (!isset($data['apikey'])) {
    $data['apikey'] = $newkey; // no API Key in settings, use the new one
    file_put_contents('/home/pi/nems.conf','apikey=' . $newkey . PHP_EOL, FILE_APPEND);
  }

?>
