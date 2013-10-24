<?php
namespace DemoServer;
use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;

class ConnectionHandler implements MessageComponentInterface {

    protected $clients;

    protected $htdocsDir = "/var/www/uploads";
    protected $startTime;
    protected $sum;
    protected $count;

    protected $file;
    protected $buffsize = 8192;

    public function __construct($filepath){
	$this->clients = new \SplObjectStorage;
    	if($filepath !== ''){
		$this->htdocsDir = $filepath;
	}
    }

    public function onOpen(ConnectionInterface $conn) {
	$this->clients->attach($conn);

	echo "New connection ({$conn->resourceId})\n";

	$this->startTime = time();
	$this->sum = 0;
	$this->count = 0;

	$filepath = sprintf("%s/%s.mp3", $this->htdocsDir, date(DATE_RFC3339,time()));

	//Create file in specified path for binary writing
	if(($this->file = @fopen($filepath, "cwb")) === FALSE){
	    echo "Can't open file {$filepath} for writing\n";
	    return;
	}
	if(@chmod($filepath, 0644) === FALSE){
	    echo "Can't set file {$filepath} permissions\n";
	    return;	
	}
    } 

    public function onMessage(ConnectionInterface $from, $msg) {

	$this->count++;
	$this->sum += strlen($msg);


	if(fwrite($this->file, $msg) === FALSE){
	    echo "Write to file failed\n";
	}
    }

    public function onClose(ConnectionInterface $conn) {
	//The connection is closed, remove it, as we can no longer send it messages
	$this->clients->detach($conn);

	fclose($this->file);

	$duration = time() - $this->startTime;

	echo sprintf("Received %d frames (%d bytes), took %s (%.3f kb/s)\n", $this->count, $this->sum, $duration, $this->sum / $duration / 1024);


	echo "Connection {$conn->resourceId} has disconnected\n";
    }

    public function onError(ConnectionInterface $conn, \Exception $e){
	echo "An error has occurred: {$e->getMessage()}\n";

	//$conn->close();
    }
}
