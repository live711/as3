////////////////////////////////////////////////////////////////////////////////
//  zengrong.org
//  创建者:	zrong
//  创建时间：2011-04-27
////////////////////////////////////////////////////////////////////////////////
package org.zengrong.assets
{
/**
 * Assets载入过程中，调用Progress回调函数的参数的ValueObject
 * @author zrong
 */
public class AssetsProgressVO
{
	public function AssetsProgressVO($curFile:Object=null)
	{
		if($curFile)
		{
			name = $curFile.name;
			url = $curFile.url;
			type = $curFile.type;
			if($curFile.loaded!=undefined)
				loaded = $curFile.loaded;
			if($curFile.total!=undefined)
				total = $curFile.total;
			if($curFile.whole!=undefined)
				whole = $curFile.whole;
		}
	}
	
	/**
	 * 若值为true，代表载入列表的进度；否则就是当前文件的载入进度
	 */	
	public var whole:Boolean;
	
	/**
	 * 载入的总量
	 */	
	public var total:int;
	
	/**
	 * 当前载入量
	 */	
	public var loaded:int;
	
	/**
	 * 正在载入的资源的名称
	 */	
	public var name:String;
	
	/**
	 * 正在载入的资源的url
	 */	
	public var url:String;
	
	/**
	 * 正在载入的资源的type
	 */	
	public var type:String;
	
	public function toString():String
	{
		return 'org.zengrong.assets::AssetsProgressVO{'+
				'name:'+name+
				',url:'+url+
				',type:'+type+
				',loaded:'+loaded+
				',total:'+total+
				',whole:'+whole + '}';
	}
}
}
