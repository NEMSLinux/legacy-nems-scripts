#!/usr/bin/php
<?php
  declare(strict_types=1);

  echo 'Checking NEMS Version... ';
  $nemsver = shell_exec('/usr/local/bin/nems-info nemsver');
  echo $nemsver . PHP_EOL;
  // NEMS 1.5 includes packages that are needed for the encryption aspects of NEMS Cloud.
  // Can't continue if on an older version of NEMS Linux.
  if ($nemsver < 1.5) die('NEMS Cloud requires NEMS 1.5+. Please upgrade.' . PHP_EOL);
  echo 'Checking if this NEMS server is authorized to use NEMS Cloud... ';
  $cloudauth = shell_exec('/usr/local/bin/nems-info cloudauth');
  if ($cloudauth == 1) {
  file_put_contents('/var/log/nems/cloudauth.log','1');
  echo 'Yes.' . PHP_EOL;

  $nems = new stdClass();

  echo 'Checking system uptime... ';
  $nems->uptime = intval(shell_exec("echo $(awk '{print $1}' /proc/uptime) / 1 | bc"));
  echo 'Done.' . PHP_EOL;

  echo 'Checking load average... ';
  $nems->loadaverage = trim(shell_exec('/usr/local/bin/nems-info loadaverage'));
  echo 'Done.' . PHP_EOL;

  echo 'Checking temperature... ';
  $nems->temperature = trim(shell_exec('/usr/local/bin/nems-info temperature'));
  echo 'Done.' . PHP_EOL;

  echo 'Syncing your NEMS Dashboard configuration...';
  $nems->settings = new stdClass();
  $nems->settings->tv_24h = intval(trim(shell_exec('/usr/local/bin/nems-info tv_24h')));
    $conftmp = file('/usr/local/share/nems/nems.conf');
    if (is_array($conftmp) && count($conftmp) > 0) {
      foreach ($conftmp as $line) {
        $tmp = explode('=',$line);
        if (trim($tmp[0]) == 'background') {
          $nems->settings->background=trim($tmp[1]);
          // for now, I won't allow custom backgrounds on NCS
          if ($nems->settings->background == 8) $nems->settings->background = 6;
        } elseif (trim($tmp[0]) == 'backgroundColor') {
          $nems->settings->backgroundColor=trim($tmp[1]);
        }
      }
    }
  echo 'Done.' . PHP_EOL;

  echo 'Loading NEMS GPIO Extender... ';
  $nems->GPIO = '';
  $curl = curl_init();
    curl_setopt($curl, CURLOPT_URL, '127.0.0.1:9595');
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($curl, CURLOPT_HEADER, false);
    $data = curl_exec($curl);
    curl_close($curl);
    if (is_string($data) && strlen($data) > 0){
      $GPIO = json_decode($data);
      if (json_last_error() === 0) {
        $nems->GPIO = json_encode($GPIO);
        echo 'Success. GPIO will be extended to NEMS Cloud Services.';
      } else {
        echo 'Failed. Continuing without GPIO Extender.';
      }
    } else {
      echo 'Failed. Continuing without GPIO Extender.';
    }

    echo PHP_EOL;

  echo 'Loading NEMS state information... ';
  $nems->state = new stdClass();
  $nems->state->raw = trim(shell_exec('/usr/local/bin/nems-info state'));
  $nems->hwid = trim(shell_exec('/usr/local/bin/nems-info hwid'));
  $tmp = file('/usr/local/share/nems/nems.conf');

  $nems->osbkey = '';
  $nems->osbpass = '';
  if (is_array($tmp)) {
    foreach($tmp as $line) {
      if (strstr($line,'=')) {
        $tmp2 = explode('=',$line);
        if (isset($tmp2[1])) {
          $tmp2[0] = trim($tmp2[0]);
          $tmp2[1] = trim($tmp2[1]);
        }
        if ($tmp2[0] == 'osbkey') {
          $nems->osbkey = $tmp2[1];
        }
        if ($tmp2[0] == 'osbpass') {
          $nems->osbpass = $tmp2[1];
        }
        unset($tmp,$tmp2);
      }
    }
  }
  if (isset($nems->state->raw) && isset($nems->hwid) && isset($nems->osbkey) && isset($nems->osbpass)) {
    echo 'Done.' . PHP_EOL;
    echo 'Encrypting data for transmission... ';
    if (strlen($nems->hwid) > 0 && strlen($nems->osbkey) > 0 && strlen($nems->osbpass) > 0) {
      $fp = fopen('/dev/urandom', 'r');
      $randomString = fread($fp, 32);
      fclose($fp);
                                                // using 256-bit key file, generated via genKeyFile() - must match server
      $key = getKeyFromPassword($nems->osbpass,file_get_contents('/root/nems/nems-admin/keys/osb.key'),32);
      $nems->state->encrypted = safeEncrypt($nems->state->raw,$key);
    }
  }

  if (isset($nems->state->encrypted) && strlen($nems->state->encrypted) > 0) {
    // proceed, but only if the data is encrypted
    echo 'Done.' . PHP_EOL;
    echo 'Sending data... ';

    // creating a new payload to avoid there EVER being a possibility of accidentally transmitting the raw data
    $datatransfer = array(
      'settings'=>json_encode($nems->settings),
      'state'=>$nems->state->encrypted,
      'GPIO'=>$nems->GPIO,
      'uptime'=>$nems->uptime,
      'loadaverage'=>$nems->loadaverage,
      'temperature'=>$nems->temperature,
      'hwid'=>$nems->hwid,
      'osbkey'=>$nems->osbkey // notice, I am NOT sending the osbpass - that is for you only
    );
print_r($datatransfer);
    $ch = curl_init('https://nemslinux.com/api/cloud/');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLINFO_HEADER_OUT, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $datatransfer);
    $result = curl_exec($ch);
    echo $result . PHP_EOL;

    curl_close($ch);

  } else {
    echo 'Failed.' . PHP_EOL;
    echo 'Did you activate your NEMS Cloud account? Aborted.';
  }


} else {
  file_put_contents('/var/log/nems/cloudauth.log','0');
  echo 'No.';
}
echo PHP_EOL;

/**
 * Encrypt a message
 * 
 * @param string $message - message to encrypt
 * @param string $key - encryption key
 * @return string
 * @throws RangeException
 */
function safeEncrypt(string $message, string $key): string
{
    if (mb_strlen($key, '8bit') !== SODIUM_CRYPTO_SECRETBOX_KEYBYTES) {
        throw new RangeException('Key is not the correct size (must be 32 bytes).');
    }
    $nonce = random_bytes(SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);

    $cipher = base64_encode(
        $nonce.
        sodium_crypto_secretbox(
            $message,
            $nonce,
            $key
        )
    );
    sodium_memzero($message);
    sodium_memzero($key);
    return $cipher;
}

/**
 * Decrypt a message
 * 
 * @param string $encrypted - message encrypted with safeEncrypt()
 * @param string $key - encryption key
 * @return string
 * @throws Exception
 */
function safeDecrypt(string $encrypted, string $key): string
{   
    $decoded = base64_decode($encrypted);
    $nonce = mb_substr($decoded, 0, SODIUM_CRYPTO_SECRETBOX_NONCEBYTES, '8bit');
    $ciphertext = mb_substr($decoded, SODIUM_CRYPTO_SECRETBOX_NONCEBYTES, null, '8bit');

    $plain = sodium_crypto_secretbox_open(
        $ciphertext,
        $nonce,
        $key
    );
    if (!is_string($plain)) {
        throw new Exception('Invalid MAC');
    }
    sodium_memzero($ciphertext);
    sodium_memzero($key);
    return $plain;
}

/**
 * Get an AES key from a static password and a secret salt
 * 
 * @param string $password Your weak password here
 * @param int $keysize Number of bytes in encryption key
 */
function getKeyFromPassword($password, $salt, $keysize = 16)
{
    return hash_pbkdf2(
        'sha256',
        $password,
        $salt,
        100000, // Number of iterations
        $keysize,
        true
    );
}

// Generate a key file in nems-admin
// Never run this unless you are sure. This will kill all connections and require importing new key to server.
function genKeyFile() {
      $fp = fopen('/dev/urandom', 'r');
      $rand1 = fread($fp, 256);
      fclose($fp);
      $fp = fopen('/dev/urandom', 'r');
      $rand2 = fread($fp, 256);
      fclose($fp);
      $key = getKeyFromPassword($rand1,$rand2,256);
      file_put_contents('/root/nems/nems-admin/keys/osb.key',$key);
}
// Not for users. This is a server key for the cloud server.
// If you change this, your salt will no longer match the server, so you'll no longer be able to access your NEMS Cloud Services Dashboard
//genKeyFile();

?>
