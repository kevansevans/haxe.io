package ;

import unifill.CodePoint;
import tink.json.Representation;

using unifill.Unifill;

typedef Payload = {
    var input:PathData;
    var output:PathData;
    var template:String;
    var created:DateData;
    var modified:DateData;
    var published:DateData;
    var edits:Array<String>;
    var description:String;
    var authors:Array<Person>;
    var contributors:Array<Person>;
    var extra:DynamicTink;
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