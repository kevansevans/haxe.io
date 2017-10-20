package ;

import unifill.CodePoint;
import tink.json.Representation;

using unifill.Unifill;

@:structInit class Payload {

    public static inline function make():Payload {
        return new Payload(
            {raw:'', directory:'', parts:[], filename:'', extension:''},
            {raw:'', directory:'', parts:[], filename:'', extension:''},'',
            {raw:'', pretty:''},{raw:'', pretty:''},{raw:'', pretty:''},[],'',[],[],{}
        );
    }

    public var input:PathData;
    public var output:PathData;
    public var template:String;
    public var created:DateData;
    public var modified:DateData;
    public var published:DateData;
    public var edits:Array<String>;
    public var description:String;
    public var authors:Array<Person>;
    public var contributors:Array<Person>;
    public var extra:DynamicTink;

    public inline function new(i, o, t, c, m, p, es, d, as, cs, ex) {
        input = i;
        output = o;
        template = t;
        created = c;
        modified = m;
        published = p;
        edits = es;
        description = d;
        authors = as;
        contributors = cs;
        extra = ex;
    }
}

typedef Raw = {
    var raw:String;
}

typedef PathData = {>Raw,
    var directory:String;
    var parts:Array<String>;
    var filename:String;
    var extension:String;
}

typedef DateData = {>Raw,
    var pretty:String;
}

typedef Person = {
    var display:String;
    var url:String;
}

abstract DynamicTink(Dynamic) from Dynamic {
    
    @:to public inline function toTinkJson():Representation<Array<Int>> {
        var str = haxe.Serializer.run(this);
        return new Representation( [for (i in 0...str.uLength()) str.uCodePointAt(i).toInt()] );
    }
    
    @:from public static inline function fromTinkJson(r:Representation<Array<Int>>):DynamicTink {
        return haxe.Unserializer.run( r.get().map(function(i) return CodePoint.fromInt(i).toString()).join('') );
    }
    
}