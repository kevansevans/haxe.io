package ;

import js.Node.*;
import js.html.*;
import js.Browser.*;
import js.node.Url.*;
import js.Node.process;

using tink.CoreApi;
using haxe.io.Path;

@:expose('fontcharacters')
class FontCharacters {
    
    private var final:CallbackList<Noise->Void> = new CallbackList();

    public static function main() {
        var fs = make();
    }

    private static var single:FontCharacters;

    public static function make():FontCharacters {
        if (single == null) {
            single = new FontCharacters();
        }
        return single;
    }
    
    public function new() {
        final.add( function(cb:Callback<Noise>) cb.invoke(Noise) );
        
        var body = window.document.getElementsByTagName('body')[0];
        var charList = [];
        
        if (body != null) {
            charList = buildList( body );
            var link = window.document.querySelectorAll( 'head link[href*="fonts.googleapis.com/css"]' );
            console.log( 'charlist', charList.length, charList.join('') );
            if (link.length > 0) {
                //var url:Url = cast(link[0],DOMElement).getAttribute('href');
                var url = parse( cast(link[0], DOMElement).getAttribute('href'), true, true );
                console.log( 'font url ', url );
                //var queryString:haxe.DynamicAccess<String> = url.query;
                if ((url.query:haxe.DynamicAccess<String>) != null) console.log( 'exists', (url.query:haxe.DynamicAccess<String>).exists('text') );
                if ((url.query:haxe.DynamicAccess<String>) != null && !(url.query:haxe.DynamicAccess<String>).exists('text')) {
                    (url.query:haxe.DynamicAccess<String>).set( 'text', ~/[^a-z0-9]*/gi.replace(charList.join(''), '') );
                    
                    //var search = queryString.toStringWithSymbols('&', '=', function(s)return s);
                    /*var path = format( url );/*url.pathName + '?$search';
                    var string = (url.isAbsolute) ?
                    '${url.hasProtocol ? url.protocol + ":" : ""}${url.slashes?"//":""}${url.hasAuth?url.auth+"@":""}${url.host}${path}${url.hasHash?"#"+url.hash:""}'
                    :
                    '${path}${url.hasHash?"#"+url.hash:""}';*/
                    Reflect.deleteField(url, 'search');
                    console.log( 'final font url', format(url) );
                    cast(link[0],DOMElement).setAttribute('href', format( url ));
                    
                }
                
            }
            
        }

        setTimeout( function(_) window.document.dispatchEvent( new CustomEvent('fontcharacters:complete', {detail:'fontcharacters', bubbles:true, cancelable:true}) ), 250 );
        
    }
    
    private function buildList(e:Node):Array<String> {
        var results = [];
        if (e == null) return results;
        
        if (e.nodeType == 3) {
            for (i in 0...e.textContent.length) {
                if ([' ', '\t', '\r', '\n'].indexOf( e.textContent.charAt(i) ) == -1 && results.indexOf(e.textContent.charAt(i)) == -1) {
                    results.push(e.textContent.charAt(i));
                            
                }
                    
            }
            
        } else {
            for (i in 0...e.childNodes.length) {
                var returned = buildList(e.childNodes[i]);
                for (j in 0...returned.length) if (results.indexOf(returned[j]) == -1) results.push( returned[j] );
                    
            }
            
        }
        
        return results;
    }
    
}
