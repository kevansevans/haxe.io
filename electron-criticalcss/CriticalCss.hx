package ;

import js.Node.*;
import js.html.*;
import js.node.Fs.*;
import js.Node.process;
import js.node.Crypto.*;
import js.Browser.*;
import js.node.Url.*;
import haxe.Serializer;
import haxe.extern.Rest;
import haxe.Unserializer;
import haxe.ds.StringMap;
import haxe.DynamicAccess;
import js.node.Url.UrlData;
import js.html.CSSRuleList;
import haxe.Constraints.Function;

import electron.Rectangle;
import electron.renderer.Remote;
import electron.main.BrowserWindow;

using StringTools;
using tink.CoreApi;
using haxe.io.Path;

@:jsRequire('postcss')
extern class PostCss {

    public function new(plugins:Array<Dynamic>);
    public function process(css:String, ?options:{from:String, to:String}):js.Promise<{css:String}>;

}

@:cmd
@:expose('criticalcss')
class CriticalCss {

    private static var single:CriticalCss;
    private static var data:{args:Array<String>};

    public static function main() {
        var ccss = make();
    }

    public static function make():CriticalCss {
        if (single == null) {
            data = tink.Json.parse( window.sessionStorage.getItem( 'data' ) );
            single = new CriticalCss( data.args );
        }

        return single;
    }

    @alias public var root:String;
    @alias public var width:Int = 1280;
    @alias public var height:Int = 800;
    @alias('rs') public var resourcePath:String;
    private var browser:BrowserWindow;
    private var final:CallbackList<Noise->Void> = new CallbackList();

    public function new(args:Array<String>) {
        @:cmd _;
        var cwd = Sys.getCwd();
        var nodes:Array<DOMElement> = 
            [for (n in window.document.querySelectorAll('link[rel="stylesheet"][href]')) cast n]
            .filter( cast filterUrl );
        console.log( 'critical nodes', nodes );
        final.add( function(cb:Callback<Noise>) {
            for (node in nodes) if (node.hasAttribute('media')) node.setAttribute('media', 'defer');
            cb.invoke(Noise);
        } );

        var sets:Array<CSSRuleList> = [for (node in nodes) {
            var node:LinkElement = cast node;
            var sheet:CSSStyleSheet = cast node.sheet;
            sheet.cssRules;
        }];

        var mediaRules:Array<CSSMediaRule> = [];
        var defaultRules:Array<CSSStyleRule> = [];

        for (set in sets) {
            for (rule in set) {
                switch rule.type {
                    case CSSRule.MEDIA_RULE: mediaRules.push( cast rule );
                    case CSSRule.STYLE_RULE: defaultRules.push( cast rule );
                    case _:
                }

            }

        }

        browser = Remote.getCurrentWindow();
        var rect:Rectangle = {x:0, y:0, width:width, height:height};
        browser.setBounds( rect );

        var criticalRules:Array<CSSStyleRule> = [];

        setTimeout( function() {
            browser.webContents.closeDevTools();
            
            setTimeout( function() {
                if (browser.isFocused()) browser.blur();

                var viewportWidth = window.innerWidth;
                var viewportHeight = window.innerHeight;

                for (rule in defaultRules) try {
                    var nodes:Array<DOMElement> = [for (n in window.document.querySelectorAll( ~/:+(before|after)/gi.replace(rule.selectorText, '') )) cast n];
                    nodes = nodes.filter( n -> n.getBoundingClientRect().top <= viewportHeight );
                    if (nodes.length > 0) criticalRules.push( rule );
                    
                } catch (e:Any) {

                }

                var criticalString = criticalRules.map( css -> css.cssText ).join('\n');

                var postcss = new PostCss([
                    require('autoprefixer'), require('postcss-sorting'),
                    require('postcss-merge-rules'), require('cssnano')
                ]);

                postcss.process(criticalString).then(function(result) {
                    var critialStyles = window.document.createStyleElement();
                    critialStyles.innerHTML = result.css;
                    nodes[0].parentNode.insertBefore(critialStyles, nodes[0]);
                    
                    // @see https://stackoverflow.com/a/40314216
                    for (node in nodes) {
                        node.setAttribute('media', 'defer');
                        node.setAttribute('onload', "if(media!='all')media='all'");
                    }

                    window.document.dispatchEvent( new CustomEvent('criticalcss:complete', {detail:'criticalcss', bubbles:true, cancelable:true}) );

                }).catchError(function(e) {
                    console.log( e );
                    window.document.dispatchEvent( new CustomEvent('criticalcss:complete', {detail:'criticalcss', bubbles:true, cancelable:true}) );

                });

            }, 500 );
            
        }, 500 );
    }

    public function filterUrl(n:DOMElement):Bool {
        var url = parse(n.getAttribute('href'), true, true);

        var result = switch url.host {
            case null, '': true;
            case _.indexOf('haxe.io') > -1 => true: true;
            case _: false;
        }

        return result;
    }

}