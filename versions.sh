#!/usr/bin/php
<?php
echo 'NEMS Linux Server Package Version Information' . PHP_EOL;
echo date('F j, Y') . PHP_EOL;
echo 'Running ' . exec('uname -a') . PHP_EOL;

exec('apt-show-versions',$packages);

$queries = array(
  'nagios',
  'php',
  'apache',
  'webmin',
  'raspi-config',
  
);

if (is_array($packages)) {
  foreach ($packages as $package) {
    foreach ($queries as $query) {
      if (stristr($package,$query)) {
        $found[$package] = 1;
      }
    }
  }
  ksort($found);
  echo PHP_EOL;
  foreach ($found as $item=>$null) {
    echo $item . PHP_EOL;
  }
}

?>
