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

    protected $frameduration;
    protected $maxduration;
    protected $totalduration;

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

		$qs = $conn->WebSocket->request->getQuery();
		
		$recordingid = $qs->get('recordingid');
		$inputhz = $qs->get('inputhz');
		$maxduration = $qs->get('maxduration');

		echo "New connection ({$conn->resourceId})\n";

		if(!$recordingid){
			echo "Client didn't provide a recordingid\n";
			$conn->close();
			return;
		}

		$this->frameduration = $inputhz ? (4096 / $inputhz) : (4096/44100);
		$this->maxduration = $maxduration ? ($maxduration * 1.2) : 600;

		$this->startTime = time();
		$this->sum = 0;
		$this->count = 0;

		//$filepath = sprintf("%s/%s.mp3", $this->htdocsDir, date(DATE_RFC3339,time()));
		$filepath = sprintf("%s/%s.mp3", $this->htdocsDir, $recordingid);

		//Create file in specified path for binary writing
		if(($this->file = @fopen($filepath, "cwb")) === FALSE){
		    echo "Can't open file {$filepath} for writing\n";
		    $conn->close();
		    return;
		}
		if(@chmod($filepath, 0644) === FALSE){
		    echo "Can't set file {$filepath} permissions\n";
		    $conn->close();
		    return;	
		}
    } 

    public function onMessage(ConnectionInterface $from, $msg) {

		$this->count++;
		$this->sum += strlen($msg);
		$this->totalduration = $this->count * $this->frameduration;

		if($this->totalduration > $this->maxduration){
			echo "Reached max duration for file, closing connection\n";
			$conn->close();
			return;
		}

		//print_r(unpack("C*",$msg));

		if(fwrite($this->file, $msg) === FALSE){
		    echo "Write to file failed\n";
		    $conn->close();
		    return;
		}
    }

    public function onClose(ConnectionInterface $conn) {
		//The connection is closed, remove it, as we can no longer send it messages
		$this->clients->detach($conn);

		if($this->file && is_resource($this->file))
			fclose($this->file);

		$endTime = time() - $this->startTime;
		$kbps = $endTime ? $this->sum / $endTime / 1024 : 0;
		echo sprintf("Received %d frames (%d bytes) in %d seconds (%.3f kb/s), encoded audio (~%.3f seconds)\n",
					 $this->count, $this->sum, $endTime, $kbps, $this->totalduration);


		echo "Connection {$conn->resourceId} has disconnected\n";
    }

    public function onError(ConnectionInterface $conn, \Exception $e){
		echo "An error has occurred: {$e->getMessage()}\n";
		$conn->close();
    }
}
