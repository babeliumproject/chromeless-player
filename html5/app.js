var recorderApp = angular.module('recorder', [ ]);

recorderApp.factory('jsonFactory', function($http){
	var jsonFactory = {
		getCuepoints: function(url){ 
			var promise = $http.get(url).then(function (response) {
          		return response.data;
        	});      
      		return promise;
		}
	};
	return jsonFactory;
}); 
recorderApp.controller('RecorderController', [ '$scope' , 'jsonFactory', function($scope, jsonFactory) {
	$scope.stream = null;
	$scope.recording = false;
	$scope.micActivityBarStyle = {"width": "0%"};
	$scope.encoder = null;
	$scope.ws = null;
	$scope.input = null;
	$scope.node = null;
	$scope.in_samplerate = 44100;
	$scope.out_samplerate = 22050;
	$scope.samplerates = [ 8000, 11025, 12000, 16000, 22050, 24000, 32000, 44100, 48000 ];
	$scope.bitrate = 64;
	$scope.bitrates = [ 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 192, 224, 256, 320 ];
	$scope.recordButtonStyle = "red-btn";

	//Init AudioContext
	window.AudioCtx = ( window.AudioContext || window.mozAudioContext || window.webkitAudioContext || window.msAudioContext );
	$scope.audioContext = window.AudioCtx ? new window.AudioCtx() : null; 
	$scope.recAudioContext = window.AudioCtx ? new window.AudioCtx() : null;
	$scope.recAudioAnalyser;
	$scope.micLevelCanvas = document.getElementById('micLevel');
	$scope.micLevelCanvasCtx = $scope.micLevelCanvas.getContext('2d');
	$scope.CANVAS_HEIGHT;
	$scope.CANVAS_WIDTH;	

	$scope.roles = [];
	$scope.chosenRole = '';

	//Dirty hack to pass all 0's to the encoder when recording something that's not from our chosen role
	$scope.silencedMicInputBufferData = new Float32Array(4096);

	//Mediaelement.js player initialization
	$scope.videoElementOptions = {
		alwaysShowControls: true,
		features: ['stop', 'playpause', 'current', 'progress', 'duration', 'tracks', 'volume'] //, 'fullscreen'
	};
	$scope.videoElement = document.getElementById('videoPlayer');
	$scope.videoElementHandle = new MediaElementPlayer($scope.videoElement, $scope.videoElementOptions);

	//$scope.micLevelCanvas.height = $scope.videoElement.height;
	//$scope.micLevelCanvas.width = 20;
	
	jsonFactory.getCuepoints('sintel_cuepoints.json').then(function(results){ 
		$scope.interaction_data = results.data;
		for(i=0; i<$scope.interaction_data.length; ++i){
			$scope.roles.push($scope.interaction_data[i].voiceId);	
		}
		console.log($scope.roles); 
	});
	/*
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
	*/

	$scope.drawMicLevel = function(){
		var WIDTH = $scope.micLevelCanvas.width,
		    HEIGHT = $scope.micLevelCanvas.height;

		$scope.micAnimation = requestAnimationFrame($scope.drawMicLevel);
		$scope.micLevelCanvasCtx.clearRect(0, 0, WIDTH, HEIGHT);
		$scope.micLevelCanvasCtx.fillRect(0, HEIGHT, WIDTH, -Math.round(HEIGHT*$scope.maxVal));
	}

	$scope.startRecording = function() {
		if ($scope.recording)
			return;

		$scope.cue_points = [{'startTime':2090, 'endTime':8390}, {'startTime':12590,'endTime':16790}, {'startTime':23440,'endTime':26340}];

		$scope.prepareCuepoints($scope.chosenRole);
		$scope.draw_cue_points();

		$scope.encoder = new Worker('encoder.js');
		$scope.encoder.onmessage = function(e) {
			//Ensure the channel is open before sending
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

		$scope.ws = new WebSocket("ws://" + window.location.host + ":8080/ws/audio?h=U1McDtQfkp&d=32&f=48000");
		$scope.ws.onopen = function() {
			navigator.getMedia = ( navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia);
			navigator.getMedia({ video: false, audio: true }, $scope.gotUserMedia, $scope.userMediaFailed);
		};
		$scope.ws.onclose = function() {
			console.log("WebSocket closed");
			//The webSocket went down unexpectedly, close the connection
			if($scope.ws) $scope.stopRecording();
		};
		$scope.ws.onerror = function(err) {
			console.log("Error connecting to WebSocket");
		};
	};

	$scope.prepareCuepoints = function(chosenRole){
		var roleCuepoints;
		for(i=0; i<$scope.interaction_data.length; i++){
			if($scope.interaction_data[i].voiceId == chosenRole){
				roleCuepoints = $scope.interaction_data[i].cuepoints;
				break;
			}
		}
		if(roleCuepoints){
			for (j=0; j<roleCuepoints.length; ++j){
				//Get all the interactions that affect the exercise
				if(roleCuepoints[j].hasOwnProperty('exercise') && roleCuepoints[j].exercise.hasOwnProperty('gapstart')){
					console.log(roleCuepoints[j].time + " " + roleCuepoints[j].exercise.gapstart);
				}
			}
		}
	}

	$scope.userMediaFailed = function(code) {
		console.log('grabbing microphone failed: ' + code);
	};

	$scope.gotUserMedia = function(localMediaStream) {
		console.log('success grabbing microphone');

		if($scope.audioContext){
			$scope.recording = true;
			$scope.recordButtonStyle = '';

			$scope.stream = localMediaStream;
			$scope.input = $scope.audioContext.createMediaStreamSource($scope.stream);
			
			//Function createJavaScriptNode renamed in favor of createScriptProcessor
			//$scope.node = $scope.input.context.createJavaScriptNode(4096, 1, 1);
			$scope.node = $scope.input.context.createScriptProcessor(4096, 1, 1);

			//Firefox and Chrome's samplerate differ: 48000Hz, 44100Hz
			$scope.in_samplerate = $scope.input.context.sampleRate;
			console.log('Input sampleRate: ' + $scope.in_samplerate);

			console.log('initializing encoder with samplerate = ' + $scope.out_samplerate + ' and bitrate = ' + $scope.bitrate);
			$scope.encoder.postMessage({ cmd: 'init', config: { in_samplerate: $scope.in_samplerate, out_samplerate: $scope.out_samplerate, bitrate: $scope.bitrate } });

			$scope.micLevelCanvas.height = $scope.videoElement.height;
			$scope.micLevelCanvas.width = 20;

			$scope.drawMicLevel();
	
			$scope.node.onaudioprocess = function(e) {
				if (!$scope.recording)
					return;
				var channelLeft = e.inputBuffer.getChannelData(0);

				$scope.maxVal = 0;
				//Get mic activity level
				for(var i = 0; i < channelLeft.length; i++){
					if($scope.maxVal < channelLeft[i]){
						$scope.maxVal = channelLeft[i];
					}
				}
				$scope.encoder.postMessage({ cmd: 'encode', buf: channelLeft });
			};

			$scope.input.connect($scope.node);
			$scope.node.connect($scope.audioContext.destination);

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
		cancelAnimationFrame($scope.micAnimation);
	};

	$scope.draw_cue_points = function () {
        	var i, time_total_rail, percent, self = this;
        	if ($scope.cue_points && !$scope.cue_points_installed) {
            		if ($scope.videoElement.duration <= 0 || isNaN($scope.videoElement.duration)) 
				return setTimeout(function () { $scope.draw_cue_points() }, 200), void 0;
            		$scope.cue_points_installed = !0;
            		var margin = 1,
                	    maxTime = $scope.videoElement.duration - margin,
			    time_total_rail = $scope.videoElementHandle.controls.find(".mejs-time-total"),
			    pxpersec = time_total_rail.width()/$scope.videoElement.duration;
			    console.log(pxpersec);
            		for ( i = 0; i < $scope.cue_points.length; i++) {
                		if ($scope.cue_points[i].startTime/1000 > maxTime)
					$scope.cue_points[i].startTime = maxTime*1000;
				
				var cue_width = Math.floor(($scope.cue_points[i].endTime-$scope.cue_points[i].startTime)/1000*pxpersec) + 'px'; 
				console.log(cue_width); 

                		percent = ($scope.cue_points[i].startTime / 1000) / $scope.videoElement.duration, 
				percent = Math.floor(1e4 * percent) / 100 + "%", 
				time_total_rail.append($("<div></div>").addClass("mejs-cuepoint").css("position", "absolute").css("left", percent).css("width", cue_width));
            		}
        	}
	};

	$scope.triggerCuePoints = function () {
        	if ($scope.cue_points)
                        if (!$scope.videoElement.paused) {
                            var i, cue_point_time, triggered_cue_points, currentTime = $scope.videoElement.currentTime,
                                timeDelta = currentTime - $scope.previous_time;
                            if (timeDelta > 0 && 2 > timeDelta) {
                                for (triggered_cue_points = [], i = 0; i < $scope.cue_points.length; i++)
                                    if (cue_point_time = $scope.cue_points[i].time, $scope.previous_time < cue_point_time && currentTime >= cue_point_time) 
					triggered_cue_points.push($scope.cue_points[i]);
                                if (triggered_cue_points.length > 0 && null !== $scope.cue_point_handler) $scope.cue_point_handler(triggered_cue_points)
                            }
                            $scope.previous_time = currentTime
                        }
        };

}]);

