#!/bin/env php
<?php
$user=trim(shell_exec('whoami'));
if ($user != 'root') die('You cannot run this program as ' . $user . '. Please use sudo.' . PHP_EOL);

  echo 'Sending a webhook test... ';
    $currentissueshead = 'NEMS Linux Test Notification';
    $nemsstate = $state = $currentissues = 'Testing';
    $fieldsarray[] = array(
      'name' => 'Webhook Test',
      'value' => 'Successful.',
      'inline' => false
    );
    include('/root/nems/nems-tools/webhook');
  echo 'Done.' . PHP_EOL;
?>
