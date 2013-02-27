package commands
{
	import events.PlayPauseEvent;
	import events.SubtitleButtonEvent;
	
	import flash.events.Event;
	import flash.events.MouseEvent;

	/**
	 * Place here the visual control functions until we decide a better location
	 *  
	 * @author inko
	 * 
	 */	
	public class PlayerControls
	{
		public function PlayerControls()
		{
			
		}
		
		
		public function enableControls():void{
			
		}
		
		public function disableControls():void{
			
		}
		
		public function set controlsEnabled(value:Boolean):void{
			
		}

		
		public function overlayClicked(event:MouseEvent):void
		{
			//_ppBtn.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		}
		
		
		
		override protected function onPPBtnChanged(e:PlayPauseEvent):void
		{
			super.onPPBtnChanged(e);
			//if(_overlayButton.visible)
			//	_overlayButton.visible=false;
		}
		
		
		/**
		 * Setters and Getters
		 *
		 */
		public function setSubtitle(text:String, textColor:uint=0xffffff):void
		{
			//_subtitleBox.setText(text, textColor);
		}
		
		public function set subtitles(flag:Boolean):void
		{
			//_subtitlePanel.visible=flag;
			//_subtitleButton.setEnabled(flag);
			//this.updateDisplayList(0, 0);
		}
		
		public function get subtitlePanelVisible():Boolean
		{
			//return _subtitlePanel.visible;
			return true;
		}
		
		
		
		// show/hide arrow panel
		public function set arrows(flag:Boolean):void
		{
			/*
			if (_state != PLAY_STATE)
			{
			_arrowContainer.visible=flag;
			this.updateDisplayList(0, 0);
			} else {
			_arrowContainer.visible=false;
			this.updateDisplayList(0, 0);
			}
			*/
		}
		
		/**
		 * Set role to talk in role talking panel
		 * @param duration in seconds
		 **/
		public function startTalking(role:String, duration:Number):void
		{
			/*
			if (!_roleTalkingPanel.talking)
			_roleTalkingPanel.setTalking(role, duration);
			*/
		}
		
		/**
		 * Enable/disable subtitling controls
		 */
		public function set subtitlingControls(flag:Boolean):void
		{
			/*
			_subtitleStartEnd.visible=flag;
			this.updateDisplayList(0,0); //repaint component
			*/
		}
		
		public function get subtitlingControls():Boolean
		{
			/*
			return _subtitlingControls.visible;
			*/
			return true;
		}
		
		
		/**
		 *  Highlight components
		 **/
		public function set highlight(flag:Boolean):void
		{
			//_arrowPanel.highlight=flag;
			//_roleTalkingPanel.highlight=flag;
		}

		
		/**
		 * On subtitle button clicked:
		 * - Do show/hide subtitle panel
		 */
		private function onSubtitleButtonClicked(e:SubtitleButtonEvent):void
		{
			if (e.state)
				doShowSubtitlePanel();
			else
				doHideSubtitlePanel();
		}
		
		/**
		 * Subtitle Panel's show animation
		 */
		private function doShowSubtitlePanel():void
		{
			/*
			_subtitlePanel.visible=true;
			var a1:AnimateProperty=new AnimateProperty();
			a1.target=_subtitlePanel;
			a1.property="alpha";
			a1.toValue=1;
			a1.duration=250;
			a1.play();
			
			this.drawBG(); // Repaint bg
			*/
		}
		
		/**
		 * Subtitle Panel's hide animation
		 */
		private function doHideSubtitlePanel():void
		{/*
			var a1:AnimateProperty=new AnimateProperty();
			a1.target=_subtitlePanel;
			a1.property="alpha";
			a1.toValue=0;
			a1.duration=250;
			a1.play();
			a1.addEventListener(EffectEvent.EFFECT_END, onHideSubtitleBar);
			*/
		}
		
		private function onHideSubtitleBar(e:Event):void
		{/*
			_subtitlePanel.visible=false;
			this.drawBG(); // Repaint bg
			*/
		}

	}
}