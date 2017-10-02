#!/usr/bin/php
<?php
$CONTACTEMAIL=@trim(@$argv[1]);
if (!filter_var($CONTACTEMAIL, FILTER_VALIDATE_EMAIL)) {
  echo 'Usage: ./mailtest.sh youremail@yourdomain.com' . PHP_EOL;
  exit();
}
echo 'Please wait...';
$resource = file('/etc/nagios3/resource.cfg');
if (is_array($resource)) {
  foreach ($resource as $line) {
    if (strstr($line,'$=')) {
      $tmp = explode('$=',$line);
      if (substr(trim($tmp[0]),0,1) == '$') { // omit comments (eg., starts with # instead of $)
        $variable_name = str_replace('$','',trim($tmp[0]));
        $$variable_name = trim($tmp[1]);
      }
    }
  }
}
$HOSTADDRESS = shell_exec('/usr/bin/nems-info ip');
$HOSTNAME = shell_exec('hostname');
$LONGDATETIME = date('r');
if ($USER5 == $CONTACTEMAIL) exit('You need to send to a different email address: same as sender.' . PHP_EOL);
$command = "/usr/bin/printf \"%b\" \"***** NEMS Test Email *****\n\nNotification Type: Test\nHost: $HOSTNAME\nAddress: $HOSTADDRESS\n\nDate/Time: $LONGDATETIME\n\" | /usr/bin/sendemail -v -s $USER7 -xu $USER9 -xp $USER10 -t $CONTACTEMAIL -f $USER5 -l /var/log/sendmail -u \"** NEMS Test Email: $HOSTNAME **\" -m \"***** NEMS Test Email *****\n\nNotification Type: Test\nHost: $HOSTNAME\nAddress: $HOSTADDRESS\n\nDate/Time: $LONGDATETIME\n\"";
$output = shell_exec($command);
echo $output;
?>
