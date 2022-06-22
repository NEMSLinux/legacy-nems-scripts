#!/usr/bin/php
<?php
exit();
// perhaps should just do this instead:
// rm -f /etc/NetworkManager/system-connections/*; sudo pkill -9 NetworkManager

  echo 'Clearing NetworkManager config' . PHP_EOL . PHP_EOL . 'Your connection will be reset.' . PHP_EOL . 'If you lose connection, check' . PHP_EOL . 'your DHCP lease to reconnect.' . PHP_EOL;
  # Find out which network interfaces are configured
  $uuid = array();
  $conf = preg_split('/\n+/', trim(shell_exec('nmcli con')));
  if (is_array($conf) && count($conf) > 0) {
    foreach ($conf as $thisconf) {
      $tmp = preg_split('/\s+/', trim($thisconf));
      if (is_array($tmp) && count($tmp) > 0) {
        foreach ($tmp as $thistmp) {
          $thistmp = trim(str_replace('--','',$thistmp)); // remove any that are just --
          $tmp2 = explode('-',$thistmp);
          if (is_array($tmp2) && count($tmp2) > 2) {
            // We've found the UUID (has more than 2 hyphens)
            $uuid[] = $thistmp;
          }
        }
      }
    }
  }
  if (count($uuid) > 0) {
    foreach ($uuid as $thisuuid) {
      // remove this network interface's config
      shell_exec('nmcli con delete uuid ' . $thisuuid);
    }
  }
  echo "Done."
?>
