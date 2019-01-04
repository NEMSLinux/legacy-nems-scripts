#!/usr/bin/php
<?php

  // Just a quick support report to help figure out issues
  echo 'Creating support-report.txt...';

  $report = date('r') . PHP_EOL;

  $report .= PHP_EOL . 'Disk Free:' . PHP_EOL;
  $report .= shell_exec('df -h') . PHP_EOL;

  $report .= PHP_EOL . 'Large Files:' . PHP_EOL;
  $report .= shell_exec('find / -type f -exec du -Sh {} + 2>&1 | sort -rh 2>&1 | head -n 30') . PHP_EOL;

#  file_put_contents('/var/www/html/backup/snapshot/support-report.txt',gzcompress(json_encode($report)));
  file_put_contents('/var/www/html/backup/snapshot/support-report.txt',(($report)));
  echo ' Done.' . PHP_EOL . 'File created. File will self-destruct in 15 minutes.' . PHP_EOL . PHP_EOL;
  echo 'Please find support-report.txt in your NEMS Migrator backup share' . PHP_EOL . 'ie. \\\\nems.local\\backup\\support-report.txt' . PHP_EOL . PHP_EOL . 'Email that file to: nems@category5.tv' . PHP_EOL . PHP_EOL;

?>
