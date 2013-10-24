var recorderApp = angular.module('recorder', [ ]);

recorderApp.controller('RecorderController', [ '$scope' , function($scope) {
	$scope.stream = null;
	$scope.recording = false;
	$scope.encoder = null;
	$scope.ws = null;
	$scope.input = null;
	$scope.node = null;
	$scope.samplerate = 22050;
	$scope.samplerates = [ 8000, 11025, 12000, 16000, 22050, 24000, 32000, 44100, 48000 ];
	$scope.bitrate = 64;
	$scope.bitrates = [ 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 192, 224, 256, 320 ];
	$scope.recordButtonStyle = "red-btn";

	//Dirty hack to pass all 0's to the encoder when recording something that's not from our chosen role
	$scope.silencedMicInputBufferData = new Float32Array(4096);

	$scope.videoElement = document.getElementById("videoPlayer");
	//$scope.textTracks = $scope.videoElement.textTracks;
	//$scope.textTrack = $scope.textTracks[0];

	$scope.chosenRole = "Shaman";
	
	$scope.trackElements = document.querySelectorAll("track");
	// for each track element
	for (var i = 0; i < $scope.trackElements.length; i++) {
		$scope.trackElements[i].addEventListener("load", function() {
			if(this.default){
				$scope.textTrack = this.track; // "this" is an HTMLTrackElement, not a TextTrack object
				$scope.textTrackKind = this.kind;
				$scope.textTrackMode = $scope.textTrack.mode; // e.g. "disabled", "hidden" or "showing"
				for (var j=0; j<$scope.textTrack.cues.length; j++){
					var cue = $scope.textTrack.cues[j];
					cue.onenter = function(e){
						//e.target, e.srcElement, e.currentTarget, e.timeStamp, e.type
						console.log(e.timeStamp);
						//console.log("Cue enter");
					};
					cue.onexit = function(e){
						console.log("Cue exit");
					};
				}	
				$scope.textTrack.oncuechange = function(){
					for(var k=0; k<this.activeCues.length; k++){
						var acue = this.activeCues[k];
						var fragment = acue.getCueAsHTML();
						var node = document.createElement('div');
						node.appendChild(fragment);
						if(node.childNodes[0].getAttribute('title') === $scope.chosenRole){
							//console.log(acue);
							console.log(node.childNodes[0].innerHTML);
							$scope.videoElement.muted=true;
							$scope.yourTurn=false;
						} else {
							$scope.videoElement.muted=false;
							$scope.yourTurn=true;
						}
					}		
				};
			}
		});
	}	

	
	

	$scope.startRecording = function() {
		if ($scope.recording)
			return;
		console.log('start recording');
		$scope.encoder = new Worker('encoder.js');
		console.log('initializing encoder with samplerate = ' + $scope.samplerate + ' and bitrate = ' + $scope.bitrate);
		$scope.encoder.postMessage({ cmd: 'init', config: { samplerate: $scope.samplerate, bitrate: $scope.bitrate } });

		$scope.encoder.onmessage = function(e) {
			if($scope.ws.readyState == 1){
			    $scope.ws.send(e.data.buf);
			    if (e.data.cmd == 'end') {
				$scope.ws.close();
				$scope.ws = null;
				$scope.encoder.terminate();
				$scope.encoder = null;
			    }
			}
		};

		$scope.ws = new WebSocket("ws://" + window.location.host + ":8080/ws/audio");
		$scope.ws.onopen = function() {
			navigator.getMedia = ( navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia);
			navigator.getMedia({ video: false, audio: true }, $scope.gotUserMedia, $scope.userMediaFailed);
		};
		$scope.ws.onclose = function() {
			console.log("WebSocket closed");
		};
		$scope.ws.onerror = function(err) {
			console.log("Error connecting to WebSocket");
		};
	};

	$scope.userMediaFailed = function(code) {
		console.log('grabbing microphone failed: ' + code);
	};

	$scope.gotUserMedia = function(localMediaStream) {
		console.log('success grabbing microphone');

		window.AudioCtx = ( window.AudioContext || window.mozAudioContext || window.webkitAudioContext || window.msAudioContext );

		if(window.AudioCtx){
			var audio_context = new window.AudioCtx();

			$scope.recording = true;
			$scope.recordButtonStyle = '';

			$scope.stream = localMediaStream;
			$scope.input = audio_context.createMediaStreamSource($scope.stream);
			$scope.node = $scope.input.context.createJavaScriptNode(4096, 1, 1);

			console.log('sampleRate: ' + $scope.input.context.sampleRate);

			$scope.node.onaudioprocess = function(e) {
				if (!$scope.recording)
					return;
				var channelLeft = e.inputBuffer.getChannelData(0);

				//If not your turn while recording send all 0's
				if(!$scope.yourTurn)
					channelLeft = $scope.silencedMicInputBufferData;

				$scope.encoder.postMessage({ cmd: 'encode', buf: channelLeft });
			};

			$scope.input.connect($scope.node);
			$scope.node.connect(audio_context.destination);

			$scope.$apply();
		} else {
			console.log("Your browser does not support Web Audio API. You can't grab the mic's raw data.");
		}
	};

	$scope.stopRecording = function() {
		if (!$scope.recording) {
			return;
		}
		$scope.recordButtonStyle = "red-btn";
		console.log('stop recording');
		$scope.stream.stop();
		$scope.recording = false;
		$scope.encoder.postMessage({ cmd: 'finish' });

		$scope.input.disconnect();
		$scope.node.disconnect();
		$scope.input = $scope.node = null;
	};

}]);

