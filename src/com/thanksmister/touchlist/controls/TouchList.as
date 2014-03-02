/**
 * @author Michael Ritchie
 * @blog http://www.thanksmister.com
 * @twitter Thanksmister
 * Copyright (c) 2011
 * 
 * TouchList is an ActionScript 3 scrolling list for Android and iOS devices. TouchList uses a custom TouchItemRenderer to display
 * list items in a scrollable list.  TouchList can also use virtualization through object pools to render large sets of data with
 * without performance issues.   If virualization is enabled, the list can not use item renderers of variable row height as the
 * renderers are being recycled from the object pool rather than be created and added to the list upon initialization. 
 * 
 * The list uses, in part, modified code from the following people or sites:
 * 
 * Dan Florio ( polyGeek )
 * @ polygeek.com/2846_flex_adding-physics-to-your-gestures
 * 
 * James Ward
 * @ www.jamesward.com/2010/02/19/flex-4-list-scrolling-on-android-with-flash-player-10-1/
 * 
 * FlepStudio
 * @ www.flepstudio.org/forum/flepstudio-utilities/4973-tipper-vertical-scroller-iphone-effect.html
 * 
 * Armit (using OpenyPyro)
 * @ http://www.arpitonline.com/blog/2009/08/02/optimized-list-a-pure-as3-list-with-renderer-recycling/
 * 
 * Polygonal (Object Pool Example)
 * @lab.polygonal.de/2008/06/18/using-object-pools/
 * 
 * You may use this code for your personal or professiona projects, just be sure to give credit where credit is due.
 * */
package com.thanksmister.touchlist.controls 
{
	import com.thanksmister.touchlist.events.TouchListItemEvent;
	import com.thanksmister.touchlist.renderers.ITouchListItemRenderer;
	
	import de.polygonal.core.ObjectPool;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/**
	 * Item selected event is dispatched when item has been selected by user.
	 * */
	[Event(name="itemSelected", type="com.thanksmister.touchlist.events.TouchListItemEvent")]
	
	/**
	 * Item pressed event is dispatched when user presses down on a list item.
	 * */
	[Event(name="itemPressed", type="com.thanksmister.touchlist.events.TouchListItemEvent")]
	
	public class TouchList extends Sprite
	{
		//------- List --------

		private var listHitArea:Shape;
		private var list:Sprite;
		
		private var scrollListHeight:Number; // the actual size of the scrolling list
		private var scrollAreaHeight:Number; // used for the scroll bar scrolling area
		private var listTimer:Timer; // timer for all events
		private var initialized:Boolean = false; // flag for list initialized
		
		private var lastListItemNumber:Number = 0; // keeps track of last amount of items added to list
		private var listPool:ObjectPool; // the object pool for recycling
		private var visualListItems:Vector.<DisplayObject>; // list of list items in viewable area
		
		private var _visualListItemBuffer:Number = 2; 
		
		private var listHeight:Number = 100;
		private var listWidth:Number = 100;
		
		private var _itemRenderer:Class
		private var _dataProvider:Array;
		private var _dirty:Boolean = false;
		private var _rowHeight:Number = 20;
		
		//------ Scrolling ---------------
		
		private var scrollBar:MovieClip;
		private var lastY:Number = 0; // last touch position
		private var firstY:Number = 0; // first touch position
		private var listY:Number = 0; // initial list position on touch 
		private var diffY:Number = 0;;
		private var inertiaY:Number = 0;
		private var minY:Number = 0;
		private var maxY:Number = 0;
		private var totalY:Number;
		
		private var _scrollRatio:Number = 40; 
		
		//------- Touch Events --------
		
		private var isTouching:Boolean = false;
		private var tapDelayTime:Number = 0;
		private var _maxTapDelayTime:Number = 5;
		private var tapItem:ITouchListItemRenderer;
		private var tapEnabled:Boolean = false;

		// ------ Constructor --------
		
		/**
		 * Constructor for the TouchList class.
		 * */
		public function TouchList()
		{
			visualListItems = new Vector.<DisplayObject>;
			
			listPool = new ObjectPool(true);

			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, destroy);
		}
		
		/**
		 * The data provider for the list which can be an array
		 * of data items. 
		 * */
		public function get dataProvider():Array
		{
			return _dataProvider;
		}
		
		public function set dataProvider(value:Array):void
		{
			_dataProvider = value;
			
			dirty = true; // mark it dirty
		}
		
		/**
		 * Set the item renderer for the list.  The item renderer
		 * should implement the ITouchListItemRenderer interface.
		 * */
		public function get itemRenderer():Class
		{
			return _itemRenderer;
		}
		
		public function set itemRenderer(value:Class):void
		{
			_itemRenderer = value;
			
			dirty = true; // mark it dirty
		}
		
		/**
		 * The height of each row. If the value is not explicitly set,
		 * it is calculated a new itemRenderer is created and measured
		 */ 
		public function get rowHeight():Number
		{
			return _rowHeight;
		}
		
		public function set rowHeight(value:Number):void
		{
			_rowHeight = value
		}
	
		/**
		 * The number of pixels that constitute a touch event.
		 * This should be adjusted for device sensitivy.
		 * */
		public function get scrollRatio():Number
		{
			return _scrollRatio;
		}
		
		public function set srollRatio(value:Number):void
		{
			_scrollRatio = value;
		}
		
		/**
		 * The number of offscreen items to render just out of visible area for 
		 * faster scrolling with now blank list items.  The default is 2, but this
		 * could depend on the device and scroll speeds.
		 * */
		public function get visualListItemBuffer():Number
		{
			return _visualListItemBuffer;
		}
		
		public function set visualListItemBuffer(value:Number):void
		{
			_visualListItemBuffer = value;
		}
		
		/**
		 * This porperty controls the tap sensitivity. Change this to 
		 * increase or descrease tap sensitivity which may be different
		 * depending on device. 
		 * */
		public function get maxTapDelayTime():Number
		{
			return _maxTapDelayTime;
		}
		
		public function set maxTapDelayTime(value:Number):void
		{
			_maxTapDelayTime = value;
		}
		
		/**
		 * Marks the list dirty and must be rendered.
		 * */
		public function get dirty():Boolean
		{
			return _dirty;
		}
		
		public function set dirty(value:Boolean):void
		{
			_dirty = value;
			
			if(!initialized) return;
			
			this.stage.addEventListener(Event.RENDER, onRenderHandler);
			this.stage.invalidate();
		}
		
		/**
		 * Sets the list width and height values.
		 * 
		 * @param width Number value for list width
		 * @param height Number value for list height
		 * */
		public function setSize(w:Number, h:Number):void
		{
			//trace("setResize");
			
			listWidth = w; 
			listHeight = h;
			
			creatList();
			createScrollBar();
	
			scrollAreaHeight = listHeight;
		}
		
		/**
		 * Redraw component usually as a result of orientation change.
		 * */
		public function resize(w:Number, h:Number):void
		{
			listWidth = w; 
			listHeight = h;
			
			scrollAreaHeight = listHeight;
			
			creatList(); // redraw list
			
			cleanThePool(); // clean pool
			
			renderListItems(); // rerender list
			
			// resize each list item
			var children:Number = list.numChildren;
			for (var i:int = 0; i < children; i++) {
				var item:DisplayObject = list.getChildAt(i);
				ITouchListItemRenderer(item).itemWidth = listWidth;
			}
		}
		
		/**
		 * Clear the list of all item renderers.
		 * */
		public function removeAllListItems():void
		{
			tapDelayTime = 0;
			
			listTimer.stop();
			isTouching = false;
			scrollAreaHeight = 0;
			scrollListHeight = 0;
			
			dataProvider = new Array();
			
			cleanThePool(); // clean the object pool
		}
		
// ------ protected methods --------
		
		protected function cleanThePool():void
		{
			listPool.purge();
			
			visualListItems = new Vector.<DisplayObject>();
			
			while(list.numChildren > 0) {
				var item:DisplayObject = list.removeChildAt(0);
				item.removeEventListener(TouchListItemEvent.ITEM_SELECTED, handleItemSelected);
				item.removeEventListener(TouchListItemEvent.ITEM_PRESS, handleItemPress);
				item = null;
			}
		}
		
		protected function onAddedToStage(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown );
		
			listTimer = new Timer( 33 );
			listTimer.addEventListener( TimerEvent.TIMER, onListTimer);
			listTimer.start();
	
			creatList();
			createScrollBar();
			
			if(dirty) {
				renderListItems();
			}
			
			initialized = true; // we are initialized
		}
		
		/**
		 * Create an empty list an the list hit area, which is also its mask.
		 * */
		protected function creatList():void
		{
			if(!listHitArea){
				listHitArea = new Shape();
				addChild(listHitArea);
			}
			
			listHitArea.graphics.clear();
			listHitArea.graphics.beginFill(0x000000, 1);
			listHitArea.graphics.drawRect(0, 0, listWidth, listHeight)
			listHitArea.graphics.endFill();
			
			if(!list){
				list = new Sprite();
				addChild(list);
			}
			
			list.graphics.clear();
			list.graphics.beginFill(0x000000, 1);
			list.graphics.drawRect(0, 0, listWidth, listHeight)
			list.graphics.endFill();
			list.mask = listHitArea;
		}
		
		/**
		 * Create our scroll bar based on the height of the scrollable list.
		 * */
		protected function createScrollBar():void
		{
			if(!scrollBar) {
				scrollBar = new MovieClip();
				addChild(scrollBar);
			}
			
			scrollBar.x = listWidth - 5;
			scrollBar.graphics.clear();

			if(scrollAreaHeight < scrollListHeight) {
				scrollBar.graphics.beginFill(0x505050, .8);
				scrollBar.graphics.lineStyle(1, 0x5C5C5C, .8);
				scrollBar.graphics.drawRoundRect(0, 0, 4, (scrollAreaHeight/scrollListHeight*scrollAreaHeight), 6, 6);
				scrollBar.graphics.endFill();
				scrollBar.alpha = 0;
			}
		}
		
		/**
		 * Returns the number of items in the viewable area for the list.
		 * Note the use of a buffer value so items just out outside the
		 * list are renderered to avoid empty list items while scrolling.
		 * 
		 * @return int Number of list items visible
		 * */
		protected function get numViewableItems():int
		{
			return Math.ceil(listHeight / rowHeight) + visualListItemBuffer;
		}

		/**
		 * Populates the list with the item renderers and data. 
		 * Sets up the object pool values.
		 */ 
		protected function renderListItems():void
		{
			dirty = false;
			
			listPool.allocate(numViewableItems, itemRenderer); // allocate the number of pool objects needed
			
			for (var i:int = 0; i < numViewableItems; i++) {
				addListItem(i);
			}
			
			scrollListHeight = dataProvider.length * rowHeight; // scroll list is the actual height of all item renderers

			createScrollBar(); // update scrollbar
		}
		
		/**
		 * Add single item renderer to the list from the pool. 
		 * 
		 * @param indx Number for the index of item in list
		 * @param addToTop Boolean value to add item to top of list or bottom
		 * */
		protected function addListItem(indx:Number, addToTop:Boolean = false):void
		{
			var listItem:DisplayObject = DisplayObject(listPool.object);
			
			if(!listItem) return;
			
			listItem.y = indx * rowHeight;
			listItem.addEventListener(TouchListItemEvent.ITEM_SELECTED, handleItemSelected);
			listItem.addEventListener(TouchListItemEvent.ITEM_PRESS, handleItemPress);
			
			var data:Object = dataProvider[indx];
			
			if(!data) return;
			
			ITouchListItemRenderer(listItem).data = data;
			ITouchListItemRenderer(listItem).itemHeight = rowHeight;
			ITouchListItemRenderer(listItem).itemWidth = listWidth;
			ITouchListItemRenderer(listItem).index = indx;
	
			if(addToTop){
				visualListItems.unshift(listItem);
				list.addChildAt(listItem, 0);
			} else {
				visualListItems.push(listItem); // store our visual list''
				list.addChild(listItem);
			}
		}
		
		/**
		 * Remove item from list and listeners, returning it to the pool.
		 * 
		 * @param remoteFromTop Boolean value to remove item from top or bottom of list
		 * */
		protected function removeListItem(removeFromTop:Boolean = true):void
		{	
			var listItem:DisplayObject = (removeFromTop)? visualListItems.shift():visualListItems.pop();
			
			if(!listItem) return;
			
			listItem.removeEventListener(TouchListItemEvent.ITEM_SELECTED, handleItemSelected);
			listItem.removeEventListener(TouchListItemEvent.ITEM_PRESS, handleItemPress);
			list.removeChild(listItem);
			
			listPool.object = listItem; // return to pool
				
			if(removeFromTop) {
				var bottomIndex:int = visualListItems.length + ITouchListItemRenderer(listItem).index + 1;
				addListItem( bottomIndex );
			} else {
				var topItem:DisplayObject = visualListItems[0];
				var topIndex:int = ITouchListItemRenderer(topItem).index - 1;
				addListItem (topIndex, true);
			} 
		}
		
		/**
		 * This handles the race condition you get when you set the data provider or 
		 * renderer after the list has been added to stage. 
		 * */
		protected function onRenderHandler(event:Event):void
		{
			if(!dataProvider || !itemRenderer|| !dirty){
				return
			}
			
			trace("onRenderHandler");
			
			this.stage.removeEventListener(Event.RENDER, onRenderHandler);
			
			
			
			renderListItems();
		}
		
		/**
		 * Detects frist mouse or touch down position.
		 * */
		protected function onMouseDown( e:Event ):void 
		{
			addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
			addEventListener( MouseEvent.MOUSE_UP, onMouseUp );
			removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);

			inertiaY = 0;
			firstY = mouseY;
			listY = list.y;
			minY = Math.min(-list.y, -scrollListHeight + listHeight - list.y);
			maxY = -list.y;
		}
		
		/**
		 * List moves with mouse or finger when mouse down or touch activated. 
		 * If we move the list moves more than the scroll ratio then we 
		 * clear the selected list item. 
		 * */
		protected function onMouseMove( e:MouseEvent ):void 
		{
			totalY = mouseY - firstY;
	
			if(Math.abs(totalY) > scrollRatio) isTouching = true;

			if(isTouching) {
				
				diffY = mouseY - lastY;	
				lastY = mouseY;

				if(totalY < minY)
					totalY = minY - Math.sqrt(minY - totalY);
			
				if(totalY > maxY)
					totalY = maxY + Math.sqrt(totalY - maxY);
			
				list.y = listY + totalY;
				
				onTapDisabled();
			}
		}
		
		/**
		 * Handles mouse up and begins animation. This also deslects
		 * any currently selected list items. 
		 * */
		protected function onMouseUp( e:MouseEvent ):void 
		{
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown );
			removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
			removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				
			if(isTouching) {
				isTouching = false;
				inertiaY = diffY;
			}
		
			onTapDisabled();
		}
		
		/**
		 * Timer event handler.  This is always running keeping track
		 * of the mouse movements and updating any scrolling or
		 * detecting any tap events.
		 * 
		 * Mouse x,y coords come through as negative integers when this out-of-window tracking happens. 
		 * The numbers usually appear as -107374182, -107374182. To avoid having this problem we can 
		 * test for the mouse maximum coordinates.
		 * */
		protected function onListTimer(e:Event):void
		{
			// test for touch or tap event
			if(tapEnabled) {
				onTapDelay();
			}
			
			// recycle our list items on movement
			recycleListItems();
			
			// scroll the list on mouse up
			if(!isTouching) {
				
				if(list.y > 0) {
					inertiaY = 0;
					list.y *= 0.3;
					
					if(list.y < 1) {
						list.y = 0;
					}
				} else if(scrollListHeight >= listHeight && list.y < listHeight - scrollListHeight) {
					inertiaY = 0;

					var diff:Number = (listHeight - scrollListHeight) - list.y;
					
					if(diff > 1)
						diff *= 0.1;

					list.y += diff;
					
				} else if(scrollListHeight < listHeight && list.y < 0) {
					inertiaY = 0;
					list.y *= 0.8;
					
					if(list.y > -1) {
						list.y = 0;
					}
				}
				
				if( Math.abs(inertiaY) > 1) {
					list.y += inertiaY;
					inertiaY *= 0.9;
				} else {
					inertiaY = 0;
				}
			
				if(inertiaY != 0) {
					if(scrollBar.alpha < 1 )
						scrollBar.alpha = Math.min(1, scrollBar.alpha + 0.1);
					
					scrollBar.y = listHeight * Math.min(1, (-list.y/scrollListHeight) );
				} else {
					if(scrollBar.alpha > 0 )
						scrollBar.alpha = Math.max(0, scrollBar.alpha - 0.1);
				}
				
			} else {
				if(scrollBar.alpha < 1)
					scrollBar.alpha = Math.min(1, scrollBar.alpha + 0.1);
				
				scrollBar.y = listHeight * Math.min(1, (-list.y/scrollListHeight) );
			}
		}
	
	
		/**
		 * Recycle the list item renderers using the object pool.
		 * */
		protected function recycleListItems():void
		{
			var diffListY:Number = Math.abs(list.y);	
			var itemsAdded:Number = Math.floor(diffListY/rowHeight);
			var diff:int = Math.abs(itemsAdded - lastListItemNumber);
			var itemIndx:Number;
		
			if(itemsAdded != lastListItemNumber) {
				for (var i:int = 0; i < diff; i++){
					removeListItem( (itemsAdded >  lastListItemNumber) ); 
				}
				
				lastListItemNumber = itemsAdded;
			} 
		}
		
		/**
		 * The ability to tab is disabled if the list scrolls.
		 * */
		protected function onTapDisabled():void
		{
			if(tapItem){
				tapItem.unselectItem();
				tapEnabled = false;
				tapDelayTime = 0;
			}
		}
		
		/**
		 * We set up a tap delay timer that only selectes a list
		 * item if the tap occurs for a set amount of time.
		 * */
		protected function onTapDelay():void
		{
			tapDelayTime++;
			
			if(tapDelayTime > maxTapDelayTime ) {
				tapItem.selectItem();
				tapDelayTime = 0;
				tapEnabled = false;
			}
		}
		
		/**
		 * On item press we clear any previously selected item. We only
		 * allow an item to be pressed if the list is not scrolling.
		 * 
		 * @param e ListItemEvent for item pressed
		 * */
		protected function handleItemPress(e:TouchListItemEvent):void
		{
			if(tapItem) tapItem.unselectItem();
			
			e.stopPropagation();
			tapItem = e.renderer;
			
			if(scrollBar.alpha == 0) {
				tapDelayTime = 0;
				tapEnabled = true;
			}
		}
		
		/**
		 * Item selection event fired from a item press.  This event does
		 * not fire if list is scrolling or scrolled after press.
		 * 
		 * * @param e ListItemEvent for item selected
		 * */
		protected function handleItemSelected(e:TouchListItemEvent):void
		{
			e.stopPropagation();
			tapItem = e.renderer;
			
			if(scrollBar.alpha == 0) {
				tapDelayTime = 0;
				tapEnabled = false;
				tapItem.unselectItem();
				
				dispatchEvent(new TouchListItemEvent(TouchListItemEvent.ITEM_SELECTED, e.renderer) );
			}
		}
		
		/**
		 * Destroy, destroy, must destroy.
		 * */
		protected function destroy(e:Event):void
		{
			removeEventListener(Event.REMOVED_FROM_STAGE, destroy);
			removeAllListItems();
			
			tapDelayTime = 0;
			tapEnabled = false;
			listTimer = null;
			
			removeChild(scrollBar);
			removeChild(list);
			removeChild(listHitArea);
		}
	}
}