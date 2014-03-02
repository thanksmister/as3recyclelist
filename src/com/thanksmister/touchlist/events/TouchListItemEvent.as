/**
 * @author Michael Ritchie
 * @blog http://www.thanksmister.com
 * @twitter Thanksmister
 * Copyright (c) 2011
 * 
 * Custom list event, can be modified to add any event or payload you wish. 
 * */
package com.thanksmister.touchlist.events
{
	import flash.events.Event;
	import com.thanksmister.touchlist.renderers.ITouchListItemRenderer;
	
	public class TouchListItemEvent extends Event
	{
		public static const ITEM_SELECTED:String = "itemSelected";
		public static const ITEM_PRESS:String = "itemPressed";
		
		public var renderer:ITouchListItemRenderer;
		
		public function TouchListItemEvent(type:String, renderer:ITouchListItemRenderer, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.renderer = renderer;
		}
	}
}