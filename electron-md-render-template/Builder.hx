package ;

import js.Node.*;
import js.node.Fs;
import js.html.*;
import js.Browser.*;
import haxe.Serializer;
import Controller.Data;
import haxe.extern.Rest;
import haxe.Unserializer;
import haxe.ds.StringMap;
import Controller.Payload;
import haxe.DynamicAccess;
import haxe.Constraints.Function;
import uhx.pati.Consts.EventConsts;

import electron.renderer.IpcRenderer;

using StringTools;
using haxe.io.Path;
using tink.CoreApi;

extern class TaskScript {
    public var final:CallbackList<Noise->Void>;
}

@:enum @:forward private abstract Consts(String) to String {

}

@:enum @:forward private abstract Stages(String) to String {
    var Final = 'final';

    public static inline function asArray():Array<String> {
        return [Final];
    }
}

@:enum @:forward private abstract Events(String) to String {
    var Sent = 'sent';
    var Received = 'received ';
}

class Builder {
    
    public static var storage:Storage = window.sessionStorage;
    
    private var max:Int = 2;
    private var waitFor:Int = 100;	// wait in ms.
    private var timestamp:Float = 0;
    private var timeoutId:Null<Int>;
    private var maxDuration:Int = 1000;	// wait in ms.
    private var observer:MutationObserver;
    
    private var files:Array<String> = [];
    private var scripts:Array<String> = [];
    private var scriptNames:Array<String> = [];
    private var completedScripts:Map<String, Bool> = new Map();
    private var loadedScripts:Map<String, haxe.DynamicAccess<{make:Void->TaskScript}>> = new Map();
    
    public static function main() {
        var con:Builder = new Builder();
        
    }
    
    public function new() {
        IpcRenderer.once('data:payload', function(event:String, arg:String) {
            var data:Data = tink.Json.parse( arg );
            console.log( data );
            storage.setItem( 'data', arg );
            files = scripts = data.scripts;
            
            processHtml( data.html );
            processJson( data.payload );

            console.log( scripts );
            for (script in scripts) {
                var name = script.withoutDirectory().withoutExtension();
                
                //require( '$__dirname/$script'.normalize() );
                scriptNames.push( name );
                console.log( 'setting $name' );
                completedScripts.set( name, false );
                
                //window.document.addEventListener( '$name:complete', handleScriptCompletion, untyped {once:true} );
                
            }

            processScripts();
            
        });
        
        IpcRenderer.once('scripts:watch', function(event:String, arg:String) {
            observer = new MutationObserver(mutation);
            observer.observe(window.document, {childList:true, subtree:true});
            
        });
    }

    public function processScripts() {
        if (scripts.length > 0) {
            var script = scripts.shift();
            var name = script.withoutDirectory().withoutExtension();
            var required = require( '$__dirname/$script'.normalize() );
            console.log (required );
            loadedScripts.set( name, (required:haxe.DynamicAccess<{make:Void->TaskScript}>) );
            console.log( 'using $script', 'listening for $name:complete' );
            window.document.addEventListener( '$name:complete', handleScriptCompletion, untyped {once:true} );

        }

    }
    
    public function processHtml(data:String) {
        var node = window.document.querySelector('#markdown');
        
        if (node != null) {
            var template:TemplateElement = cast window.document.createElement('template');
            template.innerHTML = data;
            node.parentNode.replaceChild( window.document.importNode(template.content, true), node );
            
        }
        
    }
    
    public function processJson(data:Payload) {
        window.document.dispatchEvent( new CustomEvent(JsonDataRecieved, {detail:data, bubbles:true}) );
    }
    
    public function clean():Void {
        for (link in window.document.querySelectorAll( 'a:not([href*="://haxe.io"]):not([href="#"]):not([href="/"])' )) if (cast (link,AnchorElement).href.length > 1) {
            cast (link,DOMElement).setAttribute('target', '_blank');
        }

        for (link in window.document.querySelectorAll( 'link[rel="import"]' )) {
            link.parentNode.removeChild( link );
            
        }
        
    }
    
    public function preCheck():Void {
        timestamp = haxe.Timer.stamp() - timestamp;
        
        //if (timestamp < maxDuration) {
            /*if ([for (k in completedScripts.keys()) k].length == 0) {
                 if (scripts.length > 0) for (script in scripts) {
                    var name = script.withoutDirectory().withoutExtension();
                    
                    require( '$__dirname/$script'.normalize() );
                    completedScripts.set( name, false );
                    
                    window.document.addEventListener( '$name:complete', handleScriptCompletion, untyped {once:true} );
                    
                } else {
                    timeoutId = cast setTimeout( save, waitFor );
                    
                }
                
            } else {*/
                /*var match = true;
                
                for (key in completedScripts.keys()) {
                    match = completedScripts.get( key );
                    if (!match) break;
                    
                }*/
                
                //timeoutId = cast setTimeout( save, waitFor );
                
            /*}*/
            
        /*} else {*/
        console.log( scripts );
        if (scripts.length > 0) {
            timeoutId = cast setTimeout( preCheck, waitFor );
        } else {
            timeoutId = cast setTimeout( save, waitFor );
        }
        //}
        
    }
    
    public function save():Void {
        var futures = [];
        
        var snames = scriptNames.copy();
        var stages = Stages.asArray();
        var events = new Map<String, FutureTrigger<Noise>>();
        var eventNames = [];

        for (name in snames) {
            var result = Future.trigger();
            var future = result.asFuture();
            
            futures.push( future );
            eventNames.push( name );
            console.log( name, result );
            events.set( name, result );
        }
        function inform() {
            console.log( eventNames );
            var event = snames.shift();
            console.log( event, [for (k in events.keys()) k] );
            var result = events.get(event);
            
            console.log( result );
            var script = loadedScripts.get(event);
            console.log( script, script[event].make().final );
            if (Reflect.hasField(script[event], 'make')) script[event].make().final.invoke(function(_) {
                result.trigger(Noise);
                if (snames.length > 0) inform();
            }); else {
                result.trigger(Noise);
            }
            
        }
        inform();
        console.log( 'future length ${futures.length}', futures, snames.length );
        Future.ofMany(futures).handle( function (_) {
            console.log('saving page');
            observer.disconnect();
            // Wait until `maxDuration` has passed of no dom changes before continuing.
            clearTimeout( cast timeoutId );
            //counter = -1;
            clean();
            
            var node = window.document.doctype;
            var doctype = node != null ? "<!DOCTYPE "
                    + node.name
                    + (node.publicId != null ? ' PUBLIC "' + node.publicId + '"' : '')
                    + (node.publicId == null && node.systemId != null ? ' SYSTEM' : '') 
                    + (node.systemId != null ? ' "' + node.systemId + '"' : '')
                    + '>\n' : '';
                    
            var html = window.document.documentElement.outerHTML;
            
            if (html != null && html != '<html><head></head><body></body></html>') {
                IpcRenderer.send('save', doctype + html);
                
            } else {
                IpcRenderer.send('save', 'failed');
                
            }

        } );
        
    }
    
    private function handleScriptCompletion(event:CustomEvent):Void {
        completedScripts.set( event.detail, true );
        console.log( 'completed script ${event.detail}', event.type, scripts );
        if (scripts.length > 0) processScripts();
        if (timeoutId != null) clearTimeout( cast timeoutId );
        
        timestamp = haxe.Timer.stamp() - timestamp;
        timeoutId = cast setTimeout( preCheck, waitFor );
    }
    
    private function mutation(changes:Array<MutationRecord>, observer:MutationObserver):Void {
        if (timeoutId != null) clearTimeout( cast timeoutId );
        
        timestamp = haxe.Timer.stamp() - timestamp;
        timeoutId = cast setTimeout( preCheck, waitFor );
        
    }
    
}
