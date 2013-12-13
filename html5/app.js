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
	$scope.CANVAS_HEIGHT;
	$scope.CANVAS_WIDTH;	

	$scope.roles = [];
	$scope.chosenRole = '';
	$scope.previous_time=0;

	$scope.cuepoint_target_recorded = 'exercise';
	$scope.cuepoint_target_live = 'response';

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

	$scope.appendRecControls = function(){
		$(".rec-inner").remove();
		$(".mejs-inner").append($("<div></div>").addClass("rec-inner"));
		$(".rec-inner").append($("<div></div>").addClass("rec-controls"));		
		$(".rec-controls").append($("<div></div>").addClass("mic-activity-rail"));

		//Take into account the padding to calculate the height
		var d = $scope.videoElementHandle.height,
			pt = parseInt($(".mic-activity-rail").css("padding-top")),
			pb = parseInt($(".mic-activity-rail").css("padding-bottom")),
			ch = parseInt($(".mejs-controls").css("height")),
			rheight = d-pt-pb-ch,
			theight = rheight-pt-pb;
		$(".mic-activity-rail").css("height",rheight+"px");
		$(".mic-activity-rail").append($("<span></span>").addClass("mic-activity-total").css("height",theight+"px"));
		$(".mic-activity-rail .mic-activity-total").append($("<span></span>").addClass("mic-activity-current"));
	}

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

		//Rewind the video to the start
		$scope.videoElementHandle.pause();
		$scope.videoElementHandle.setCurrentTime(0);

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

		//Init user devices
		navigator.getMedia = ( navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia);
		navigator.getMedia({ video: false, audio: true }, $scope.gotUserMedia, $scope.userMediaFailed);
	};

	$scope.prepare_cuepoints = function(chosenRole){
		$scope.role_cuepoints;
		for(i=0; i<$scope.interaction_data.length; i++){
			if($scope.interaction_data[i].voiceId == chosenRole){
				$scope.role_cuepoints = $scope.interaction_data[i].cuepoints;
				break;
			}
		}
		if($scope.role_cuepoints){
			$scope.cuepoint_gaps = [];
			for (j=0; j<$scope.role_cuepoints.length; j++){
				//Get all the interactions that affect the exercise
				if($scope.role_cuepoints[j].hasOwnProperty('gapend')){
					$scope.cuepoint_gaps.push({'startTime':$scope.role_cuepoints[j].time, 'endTime':$scope.role_cuepoints[j].gapend});
				}
			}
			//console.log($scope.cuepoint_gaps);
		}
	}

	$scope.initWebsocket = function(){
		$scope.wsport = 8080;
		$scope.wsapp = 'ws/audio';
		
		$devicesamplerate = $scope.in_samplerate;
		
		maxduration = $scope.chosenRole ? $scope.videoElement.duration : 300;

		$scope.recordinghash = Math.random().toString(36).substr(2);

		$scope.ws = new WebSocket("ws://" + window.location.host + ":" + $scope.wsport + "/" + $scope.wsapp +
									"/" + $scope.recordinghash + "/" + $devicesamplerate + "/" + maxduration);
		$scope.ws.onopen = function() {
			console.log("WebSocket opened");
			$scope.onWebsocketReady();
		};
		$scope.ws.onclose = function() {
			console.log("WebSocket closed");
			//The webSocket went down unexpectedly, abort the recording
			//TODO
		};
		$scope.ws.onerror = function(err) {
			console.log("Error connecting to WebSocket");
		};

	}

	$scope.userMediaFailed = function(error) {
		console.log('Getting access to microphone failed: ' + error.message);
		//If webSocket is open close it
		if($scope.ws.readyState  == 1){
			$scope.ws.close();
			$scope.ws = null;
			$scope.encoder.terminate();
			$scope.encoder = null;
		}
		//Stop cue_point triggering timer
		clearInterval($scope.trigger_cuepoints);

		//Clear the cuepoint gaps
		$(".mejs-cuepoint").remove();
	};

	$scope.gotUserMedia = function(localMediaStream) {
		console.log('Successfully got acccess to the microphone');
		$scope.stream = localMediaStream;
		$scope.initWebsocket();
	}

	$scope.onWebsocketReady = function(){
		if($scope.audioContext){
			$scope.prepare_cuepoints($scope.chosenRole);
			$scope.draw_cuepoints();

			$scope.appendRecControls();
			$scope.micActivityHeight = parseInt($(".mic-activity-total").css("height"));

			$scope.recording = true;
			$scope.recordButtonStyle = '';

			//$scope.stream = localMediaStream;
			$scope.input = $scope.audioContext.createMediaStreamSource($scope.stream);
			
			//Function createJavaScriptNode renamed in favor of createScriptProcessor
			$scope.node = $scope.input.context.createScriptProcessor(4096, 1, 1);

			//Firefox and Chrome's samplerate differ: 48000Hz, 44100Hz
			$scope.in_samplerate = $scope.input.context.sampleRate;
			console.log('Device sampleRate: ' + $scope.in_samplerate);
			console.log('Initializing encoder with sampleRate = ' + $scope.out_samplerate + ' and bitrate = ' + $scope.bitrate);
			
			$scope.encoder.postMessage({ cmd: 'init', config: { in_samplerate: $scope.in_samplerate, out_samplerate: $scope.out_samplerate, bitrate: $scope.bitrate } });

			//$scope.micLevelCanvas.height = $scope.videoElement.height;
			//$scope.micLevelCanvas.width = 20;

			//$scope.drawMicLevel();

			$scope.videoElementHandle.play();

			//<video> 'timeupdate' event fires at different intervals: Firefox every video frame, Webkit 250ms, Opera 200ms
			setInterval($scope.trigger_cuepoints, 100);

			$scope.videoElement.addEventListener('ended', $scope.onMediaEnded);
	
			$scope.node.onaudioprocess = function(e) {
				if (!$scope.recording)
					return;

				var channelLeft = e.inputBuffer.getChannelData(0);
				if($scope.recordingMuted)
					channelLeft = $scope.silencedMicInputBufferData;

				$scope.maxVal = 0;
				//Get mic activity level
				for(var i = 0; i < channelLeft.length; i++){
					if($scope.maxVal < channelLeft[i]){
						$scope.maxVal = channelLeft[i];
					}
				}
				
				//Draw the current mic activity level
				var marginpercent = 1-$scope.maxVal,
					activityheight = $scope.micActivityHeight * $scope.maxVal,
					marginheight = $scope.micActivityHeight * marginpercent;
				$(".mic-activity-current").css("margin-top",marginheight+"px").css("height",activityheight+"px");

				$scope.encoder.postMessage({ cmd: 'encode', buf: channelLeft });
			};

			$scope.input.connect($scope.node);
			$scope.node.connect($scope.audioContext.destination);

			//Refresh the angularjs bindings
			$scope.$apply();
		} else {
			console.log("Your browser does not support Web Audio API. You can't grab the mic's raw data.");
		}
	};

	$scope.onMediaEnded = function(e){
		//If role chosen, end recording
		console.log("Video playback ended");
		$scope.videoElement.removeEventListener('ended',$scope.onMediaEnded);
		clearInterval($scope.trigger_cuepoints);
		$scope.stopRecording();



		//Called the stopRecording function without explicit user interaction, call $apply() to update the bindings
		$scope.$apply();
	}

	$scope.setupSimultaneousPlayback = function(){
		$scope.videoElement.addEventListener("play",$scope.simultaneusPlay);
		$scope.videoElement.addEventListener("pause", $scope.simultaneusPause);
		$scope.videoElement.addEventListener("ended", $scope.simultaneusEnded);
	}

	$scope.stopRecording = function() {
		if (!$scope.recording) {
			return;
		}
		$scope.recordButtonStyle = "red-btn";
		console.log('Stop recording');
		$scope.stream.stop();
		$scope.recording = false;
		$scope.encoder.postMessage({ cmd: 'finish' });

		$scope.input.disconnect();
		$scope.node.disconnect();
		$scope.input = $scope.node = null;
		//cancelAnimationFrame($scope.micAnimation);
	};

	$scope.draw_cuepoints = function () {
        	var i, time_total_rail, percent;
        	if ($scope.cuepoint_gaps) {
            		if ($scope.videoElement.duration <= 0 || isNaN($scope.videoElement.duration)) 
				return setTimeout(function () { $scope.draw_cuepoints() }, 200), void 0;
            		//$scope.cue_points_installed = !0;
            		var margin = 1,
                	    maxTime = $scope.videoElement.duration - margin,
			    time_total_rail = $scope.videoElementHandle.controls.find(".mejs-time-total"),
			    pxpersec = time_total_rail.width()/$scope.videoElement.duration;
			    //console.log(pxpersec);

			$(".mejs-cuepoint").remove();

            		for ( i = 0; i < $scope.cuepoint_gaps.length; i++) {
                		if ($scope.cuepoint_gaps[i].startTime > maxTime)
					$scope.cuepoint_gaps[i].startTime = maxTime;
				
				var cue_width = Math.floor(($scope.cuepoint_gaps[i].endTime-$scope.cuepoint_gaps[i].startTime)*pxpersec) + 'px'; 
				//console.log(cue_width); 

                		percent = ($scope.cuepoint_gaps[i].startTime) / $scope.videoElement.duration, 
				percent = Math.floor(1e4 * percent) / 100 + "%", 
				time_total_rail.append($("<div></div>").addClass("mejs-cuepoint").css("position", "absolute").css("left", percent).css("width", cue_width));
            		}
        	}
	};

	$scope.trigger_cuepoints = function () {
        	if ($scope.role_cuepoints){
            	if (!$scope.videoElement.paused) {
                    var i, 
                        cue_point_time, 
                        triggered_cue_points, 
                        currentTime = $scope.videoElement.currentTime,
                        timeDelta = currentTime - $scope.previous_time;
                    if (timeDelta > 0 && 2 > timeDelta) {
                        for (triggered_cue_points = [], i = 0; i < $scope.role_cuepoints.length; i++){
                        	cue_point_time = $scope.role_cuepoints[i].time;
                            if (($scope.previous_time < cue_point_time || (cue_point_time == 0 && $scope.previous_time <= cue_point_time)) && currentTime >= cue_point_time){
                               	triggered_cue_points.push($scope.role_cuepoints[i]);
                            }
						}
                        if (triggered_cue_points.length > 0 && null !== $scope.cue_point_handler){
                           	//console.log(triggered_cue_points);
							$scope.cue_point_handler(triggered_cue_points);
						}
                    }
                    $scope.previous_time = currentTime;
                }
			}
        };

	$scope.cue_point_handler = function(triggered_cuepoints){
		var i,j,k;
		for(i=0; i<triggered_cuepoints.length; i++){
			var cuepoint = triggered_cuepoints[i];
			for(j=0; j<cuepoint.actions.length; j++){
				var parameters = cuepoint.actions[j].hasOwnProperty('parameters') ? cuepoint.actions[j].parameters : null;
				if(cuepoint.actions[j].target == $scope.cuepoint_target_recorded){
					switch(cuepoint.actions[j].function){
						case 'mute':
							$scope.videoElementHandle.setMuted(true);
							break;
						case 'unmute':
							$scope.videoElementHandle.setMuted(false);
							break;
						case 'volumechange':
							$scope.videoElementHandle.setVolume(parameters);
							break;
						default:
							break;
					}
				}
				if(cuepoint.actions[j].target == $scope.cuepoint_target_live){
					switch(cuepoint.actions[j].function){
						case 'mute':
							//Send the encoder a buffer of 'silence' until told otherwise
							$scope.recordingMuted = !0;
							break;
						case 'unmute':
							$scope.recordingMuted = !1;
							break;
						case 'volumechange':
							//TODO Apply a GainNode with the given value before passing the raw input to the  encoding worker
							break;
						default:
							break;
					}
				}
				//console.log("[" + cuepoint.time + "]" + cuepoint.actions[j].target + ":" + cuepoint.actions[j].function + ":" + cuepoint.actions[j].parameters);
			}	
		}
	}

}]);

