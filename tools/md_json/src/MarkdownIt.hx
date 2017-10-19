package ;

@:jsRequire('markdown-it')
extern class MarkdownIt {

    public var block:Dynamic;
    public var core:Dynamic;
    public var renderer:Dynamic;
    public var utils:Dynamic;
    public function new(options:{html:Bool, linkify:Bool, typographer:Bool});
    public function use(plugin:Dynamic, options:Dynamic):Void;
    public function parse(value:String, environment:Dynamic):Array<Token>;

}

// @see https://github.com/markdown-it/markdown-it/blob/master/lib/token.js
typedef Token = {
    var type:String;
    var tag:String;
    var attrs:Array<Array<Dynamic>>;
    var map:Array<Int>;
    var nesting:NestingLevel;
    var level:Int;
    var children:Array<Token>;
    var content:String;
    var markup:String;
    var info:String;
    var meta:Dynamic;
    var block:Bool;
    var hidden:Bool;
}

@:enum abstract NestingLevel(Int) from Int to Int {
    var Opening = 1;
    var SelfClosing = 0;
    var Closing = -1;
}