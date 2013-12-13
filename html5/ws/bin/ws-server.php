<?php
use Ratchet\App;
use Ratchet\Http\HttpServer;
use Ratchet\Server\IoServer;
use Ratchet\WebSocket\WsServer;

use DemoServer\ConnectionHandler;

require dirname(__DIR__) . '/vendor/autoload.php';

//Absolute path where you want to store the uploaded mp3 audios
$filepath = dirname(__DIR__) . '/../uploads';
$domain = 'development';
$port = 8080;


$audiouploadinstance = new WsServer(new ConnectionHandler($filepath));
    
//Turn off the UTF-8 encoding check to prevent WsServer from closing the
//connection when receiving binary data 
$audiouploadinstance->setEncodingChecks(false);

//$server = IoServer::factory(new HttpServer($wsinstance),8080);
//$server->run();

$app = new App($domain, $port);
$app->route('/ws/audio/{recordingid}/{inputhz}/{maxduration}', $audiouploadinstance);

//TODO
//$app->route('/livestreaming', $livestreaminginstance);

$app->run();
