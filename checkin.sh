#!/usr/bin/php
<?php

// This script is disabled by default. You can enable it in NEMS SST.

// What it does is checkin with the API server, and sends the email address that you provide in NEMS SST, along with your NEMS Server's alias.
// This checkin occurs every 15 minutes (ONLY if activated by you), and if your server does not check in for the time you specify in NEMS SST,
// the NEMS API server will send an email to the email address you provided to let you know that your NEMS server has not checked in.
// The idea is to give you an easy way to ensure your NEMS server is always up. If it goes offline, you'll get a notice from us.

// Again, this script does *nothing* unless you have it enabled in NEMS SST.
// I also set it up so you can specify an alternate email address for this notice so the information you send (and we store) can be an
// alternate email address. Just thinking of your privacy here.
// The email address you provide is sent to the API via an encrypted connection, and
// once there, it is stored in an encrypted format in our database.

echo 'Checking NEMS Version... ';
$nemsver = shell_exec('/usr/local/bin/nems-info nemsver');
echo $nemsver . PHP_EOL;
if ($nemsver < 1.5) die('NEMS Cloud requires NEMS 1.5+. Please upgrade.' . PHP_EOL);
echo 'Checking if this NEMS server is authorized to use NEMS Cloud... ';
$cloudauth = shell_exec('/usr/local/bin/nems-info cloudauth');
if ($cloudauth == 1) {
echo 'Yes.' . PHP_EOL;

$checkinenabled = trim(shell_exec('/usr/local/bin/nems-info checkin'));
$checkinemail = trim(shell_exec('/usr/local/bin/nems-info checkinemail'));
$checkininterval = trim(shell_exec('/usr/local/bin/nems-info checkininterval'));
$alias = trim(shell_exec('/usr/local/bin/nems-info alias'));

# Get the NEMS Cloud Services key (entered in NEMS SST)
  $tmp = file('/usr/local/share/nems/nems.conf');
  $osbkey = '';
  if (is_array($tmp)) {
    foreach($tmp as $line) {
      if (strstr($line,'=')) {
        $tmp2 = explode('=',$line);
        if (isset($tmp2[1])) {
          $tmp2[0] = trim($tmp2[0]);
          $tmp2[1] = trim($tmp2[1]);
        }
        if ($tmp2[0] == 'osbkey') {
          $osbkey = $tmp2[1];
        }
        unset($tmp,$tmp2);
      }
    }
  }

if ($checkinenabled != 1) {
  echo "Checkin not enabled in NEMS SST." . PHP_EOL;
  exit();
}

if ($checkinemail == '' || !filter_var($checkinemail, FILTER_VALIDATE_EMAIL)) {
  echo "You need to specify a valid email address for checkin in NEMS SST." . PHP_EOL;
  exit();
}


$output = date('r') . PHP_EOL;
$output .= 'Checking in: ';
file_put_contents('/var/log/nems/checkin.log',$output,FILE_APPEND);

# only proceed if Nagios is running
$socket = trim(shell_exec('/usr/local/bin/nems-info socket'));
if (file_exists($socket)) {
  # Setup the data array

  $data = array(
    'hwid'=>trim(shell_exec('/usr/local/bin/nems-info hwid')),
    'checkinemail'=>$checkinemail,
    'interval'=>$checkininterval,
    'osbkey'=>$osbkey,
    'alias'=>$alias
  );

  // Load existing NEMS Stats API Key, if it exists
  $settings = @file('/usr/local/share/nems/nems.conf');
  if (is_array($settings) && count($settings) > 0) {
    foreach ($settings as $line) {
      if (substr($line,0,6) == 'apikey') {
        $data['apikey'] = trim(substr($line,7));
      }
    }
  }

  # Connect and checkin
  $ch = curl_init('https://nemslinux.com/api/checkin/');
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
  $retry = 0;
  $newkey = '';
  while((curl_errno($ch) == 28 || $newkey == '') && $retry < 1440){ // error 28 is timeout - retry every 5 seconds for 1440 tries (2 hours). Will also retry if an apikey is not sent by the server.
    $response = curl_exec($ch);
    sleep(5);
    $newkey = filter_var($response,FILTER_SANITIZE_STRING);
    if (strlen($newkey) > 0) break;
    file_put_contents('/var/log/nems/checkin.log','Failed to send stats. Trying again.' . PHP_EOL,FILE_APPEND);
    $retry++;
  }
  if ($retry < 1440) {
    file_put_contents('/var/log/nems/checkin.log','Success.' . PHP_EOL,FILE_APPEND);
  } else {
    file_put_contents('/var/log/nems/checkin.log','Failed. Giving up.' . PHP_EOL,FILE_APPEND);
  }
  curl_close($ch);
  if (!isset($data['apikey'])) {
    $data['apikey'] = $newkey; // no API Key in settings, use the new one
    file_put_contents('/usr/local/share/nems/nems.conf','apikey=' . $newkey . PHP_EOL, FILE_APPEND);
    file_put_contents('/var/log/nems/checkin.log','Assigned new API Key by server: ' . $newkey . PHP_EOL,FILE_APPEND);
  }
} else {
  echo 'Nagios is offline. Will not checkin.' . PHP_EOL;
  file_put_contents('/var/log/nems/checkin.log','Nagios is offline. Will not checkin.' . PHP_EOL,FILE_APPEND);
}

file_put_contents('/var/log/nems/checkin.log','--------------------' . PHP_EOL,FILE_APPEND);

} else {
  echo 'No' . PHP_EOL;
}
?>
