function query_client($address) {
    $address = explode(':', $address);

    $client['ip']     = $address[0];
    $client['port']   = (int)$address[1];
    if (!$client['ip'] || !$client['port']) { exit("empty or invalid address"); }

    $fp = fsockopen("udp://".$client['ip'], $client['port'], $errno, $errstr, 2);
    stream_set_blocking($fp , 0);

    $header = "\xFF\xFF\xFF\xFF";
    $query = "T";
    fwrite ($fp, $header . $query);

    fclose($fp );
}
query_client("95.28.194.121:27005");
