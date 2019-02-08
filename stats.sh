#!/usr/bin/php
<?php
// # This is simple, anonymous stats just so Robbie knows a bit about how many systems are using NEMS.
// # This will also help me understand limitations of various platforms (ie, how many hosts can a Pi 3 handle?).
// # Please do not deactivate this unless you absolutely have to.
// # Again, it's completely anonymous, and nothing private is revealed.

$v=0;
while (!file_exists('/var/log/nems/hw_model')) {
  // Just in case this is the first boot and running at startup, let's hang tight to let the data generate
  sleep(10);
  $v++;
  if ($v == 6) die('Timed out waiting for hw_model');
}

$v=0;
$socket=shell_exec('/usr/local/bin/nems-info socket');
$socketstatus=shell_exec('/usr/local/bin/nems-info socketstatus');
while ($socketstatus != 1) {
  // waiting for the Nagios livestatus socket to become ready
  sleep(10);
  $socketstatus=shell_exec('/usr/local/bin/nems-info socketstatus');
  $v++;
  if ($v == 6) die('Timed out waiting for livestatus socket to become ready (is Nagios running?)');
}

$output = date('r') . PHP_EOL;
$load = sys_getloadavg();
$output .= 'LA: ' . $load[0] . PHP_EOL;
$output .= 'Sending anonymous stats to https://new.nemslinux.com/stats/' . PHP_EOL;
file_put_contents('/var/log/nems/stats.log',$output,FILE_APPEND);

if (file_exists('/var/log/nems/hw_model')) { // Don't run this until system is ready to report true stats

  // Get the platform of your NEMS server
  $platform = trim(shell_exec('/usr/local/bin/nems-info platform'));

  // Get the NEMS version
  $ver = trim(shell_exec('/usr/local/bin/nems-info nemsver'));

  // Get the number of configured hosts
  $hosts = trim(shell_exec('/usr/local/bin/nems-info hosts'));

  // Get the number of configured services
  $services = trim(shell_exec('/usr/local/bin/nems-info services'));

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

  // Get system benchmarks
  $benchmarks['cpu'] = shell_exec('/usr/local/bin/nems-info benchmark cpu');
  $benchmarks['ram'] = shell_exec('/usr/local/bin/nems-info benchmark ram');
  $benchmarks['io'] = shell_exec('/usr/local/bin/nems-info benchmark io');
  $benchmarks['mutex'] = shell_exec('/usr/local/bin/nems-info benchmark mutex');

  // Put it together to send to the server
  $data = array(
    'hwid'=>trim(shell_exec('/usr/local/bin/nems-info hwid')),
    'platform'=>$platform,
    'uptime_days'=>$days,
    'uptime_hours'=>$hours,
    'uptime_mins'=>$mins,
    'uptime_secs'=>$secs,
    'nemsver'=>$ver,
    'hosts'=>$hosts,
    'services'=>$services,
    'disksize'=>$disksize,
    'diskfree'=>$diskfree,
    'loadaverage'=>trim(shell_exec('/usr/local/bin/nems-info loadaverage')),
    'temperature'=>trim(shell_exec('/usr/local/bin/nems-info temperature')),
    'timezone'=>date('T'),
    'benchmarks'=>json_encode($benchmarks),
  );

  file_put_contents('/var/log/nems/stats.log',serialize($data) . PHP_EOL,FILE_APPEND);

  // Load existing NEMS Stats API Key, if it exists
  $settings = @file('/usr/local/share/nems/nems.conf');
  if (is_array($settings) && count($settings) > 0) {
    foreach ($settings as $line) {
      if (substr($line,0,6) == 'apikey') {
        $data['apikey'] = substr($line,7);
      }
    }
  }

  $ch = curl_init('https://new.nemslinux.com/api/stats/');
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
  $retry = 0;
  $newkey = '';
  while((curl_errno($ch) == 28 || $newkey == '') && $retry < 1440){ // error 28 is timeout - retry every 5 seconds for 1440 tries (2 hours). Will also retry if an apikey is not sent by the server.
    $response = curl_exec($ch);
    sleep(5);
    $newkey = filter_var($response,FILTER_SANITIZE_STRING);
    if (strlen($newkey) > 0) break;
    file_put_contents('/var/log/nems/stats.log','Failed to send stats. Trying again.' . PHP_EOL,FILE_APPEND);
    $retry++;
  }
  if ($retry < 1440) {
    file_put_contents('/var/log/nems/stats.log','Success.' . PHP_EOL,FILE_APPEND);
  } else {
    file_put_contents('/var/log/nems/stats.log','Failed. Giving up.' . PHP_EOL,FILE_APPEND);
  }
  curl_close($ch);
  if (!isset($data['apikey'])) {
    $data['apikey'] = $newkey; // no API Key in settings, use the new one
    file_put_contents('/usr/local/share/nems/nems.conf','apikey=' . $newkey . PHP_EOL, FILE_APPEND);
    file_put_contents('/var/log/nems/stats.log','Assigned new API Key by server: ' . $newkey . PHP_EOL,FILE_APPEND);
  }

}

$load = sys_getloadavg();
$output = 'LA: ' . $load[0] . PHP_EOL;
file_put_contents('/var/log/nems/stats.log',$output . '--------------------' . PHP_EOL,FILE_APPEND);

?>
