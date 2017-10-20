package ;

import Consts;
import js.Node.*;
import tink.Json.*;
import uhx.sys.Cli;
import js.node.Fs.*;
import thx.DateTime;
import js.Node.process;
import haxe.Serializer;
import js.node.Crypto.*;
import haxe.Unserializer;
import unifill.CodePoint;
import haxe.ds.StringMap;
import haxe.DynamicAccess;
import thx.format.DateFormat;
import tink.json.Representation;
import haxe.Constraints.Function;

using Reflect;
using StringTools;
using thx.Objects;
using haxe.io.Path;
using tink.CoreApi;
using unifill.Unifill;

class Entry {

    public static function main() {
        var entry = new Entry();
        Cli.process( entry, Sys.args(), Sys.environment() ).handle( Cli.exit );
    }

    //

    @:alias public var input:String = '';
    @:alias public var output:String = '';

    /**
    The markdown-it plugins should be loaded.
    */
    @:flag('md') public var markdownPlugins:Array<String> = [];

    /**
    Extra options to be passed to markdown-it plugins.
    */
    @:flag('mdo') public var markdownOptions:String = '';

    //

    private var cwd:String = Sys.getCwd();

    private var markdown:MarkdownIt;
    private var markdownObject:DynamicAccess<Dynamic> = {};
    private var markdownEnvironment:DynamicAccess<DynamicAccess<DynamicAccess<String>>> = {};
    
    private var twemoji:Dynamic;

    // Final information payload.
    private var payload = Payload.make();

    public function new() {}

    @:init public function initialize() {
        if (input == '' || output == '') {
            Sys.println('Input/Output needs to be set.');
            return Future.sync(Noise);

        }
        
        input = input.normalize();
        output = output.normalize();

        return process();
    }

    private function process() {
        var future = Future.trigger();
        var options = {};
        // Pass extra options to markdownIt plugins.
        markdown = new MarkdownIt( { html: true, linkify: true, typographer: true } );
        
        if (markdownOptions != null) markdownObject = (markdownOptions == '') ? {} : haxe.Json.parse( markdownOptions );
        
        for (plugin in markdownPlugins) {
            if (markdownObject != null && markdownObject.exists( plugin )) {
                options = markdownObject.get( plugin );
                
            }
            
            markdown.use( require(plugin), options );
            
        }
        
        // Modify the markdownIt `reference` token rule.
        var index = markdown.block.ruler.__find__('reference');
        var original = markdown.block.ruler.__rules__[index].fn;
        
        var replaceReferences = [
            [Ref, Author] => function(object:Dynamic) {
                if (object.fields().length > 0) payload.authors.push( {display:object.title, url:object.href} );
                return true;	// delete
            },
            [Ref, Contributor] => function(object:Dynamic) {
                if (object.fields().length > 0) payload.contributors.push( {display:object.title, url:object.href} );
                return true;	// delete
            },
        ];
        
        markdown.block.ruler.at('reference', function(state, startLine, _endLine, silent) {
            var result = original(state, startLine, _endLine, silent);
            var object:DynamicAccess<Dynamic> = state.env;
            var keys = [for (key in replaceReferences.keys()) key];
            
            for (key in keys) {
                for (segment in key) {
                    if (object.exists( segment )) {
                        if (segment == key[key.length - 1]) {
                            var remove = replaceReferences.get( key )( object[segment] );
                            
                            if (remove) {
                                object.remove( segment );
                                
                            }
                            
                        } else {
                            object = object[segment];
                            
                        }
                        
                    } else {
                        
                        
                    }
                    
                }
                
            }
            
            return result;
        });
        
        var emojione = require('emojione');
        var emoji:haxe.DynamicAccess<EmojiData> = require('emojione/emoji.json');
        var emojies_defs:haxe.DynamicAccess<String> = require('markdown-it-emoji/lib/data/full.json');
        var emoji_replace = require('markdown-it-emoji/lib/replace');
        var normalize_opts = require('markdown-it-emoji/lib/normalize_opts');
        
        // Populate markdown-it-emoji data with emojione data.
        for (key in emoji.keys()) {
            var data = emoji.get( key );
            var shortcode = data.shortname.substring(1, data.shortname.length-1);
            //trace( data, shortcode );
            var unicode = emojione.convert(data.unicode);
            
            if (!emojies_defs.exists( shortcode )) emojies_defs.set( shortcode, unicode );
            if (data.aliases.length > 0) for (alias in data.aliases) {
                if (!emojies_defs.exists( alias.substring(1, alias.length-1) )) emojies_defs.set( alias.substring(1, alias.length-1), unicode );
            }
            
        }
        
        // Rebuild markdown-it-emoji plugin with new shortcodes from the emojione project.
        var defaults = {
            defs: emojies_defs,
            shortcuts: require('markdown-it-emoji/lib/data/shortcuts'),
            enabled: []
        };
        var opts = normalize_opts(markdown.utils.assign({}, defaults, {}));
        
        // Replace markdown-it-emoji with custom options.
        markdown.core.ruler.at('emoji', emoji_replace(markdown, opts.defs, opts.shortcuts, opts.scanRE, opts.replaceRE) );
        
        // Add twemoji support to markdownIt - this replaces short codes only
        twemoji = require('twemoji');
        markdown.renderer.rules.emoji = function(token, idx) {
            return twemoji.parse(token[idx].content, {ext:'.svg', base:'/twemoji/', folder:'svg'});
        };
        
        js.node.Fs.readFile('$cwd/$input'.normalize(), {encoding:'utf8'}, function(error, content) {
            if (error != null) trace( error );
            
            var ast = preprocessAst( markdown.parse( content, markdownEnvironment ) );
            var payload = generatePayload( markdownEnvironment );

            js.node.Fs.writeFile('$cwd/$output'.normalize(), tink.Json.stringify(payload), function(error) {
                if (error != null) trace(error);
                future.trigger(Noise);
            });

        });
        
        return future.asFuture();
    }

    private function preprocessAst(ast:Array<MarkdownIt.Token>):Array<MarkdownIt.Token> {
        // Look for `[“”]: ""` and remove.
        var slice = ast.slice(0,3);

        switch (slice) {
            case [{type:'paragraph_open'}, {content:_.startsWith('[“”]') => true}, {type:'paragraph_close'}]:
                //trace( 'removing ast' );
                ast = ast.splice( 3, ast.length );
                
            case _:
                
                
        }

        return ast;
    }

    private function daySuffix(n:Int):String {
        if (n >= 11 && n <= 13) {
                return "th";
        }
        switch (n % 10) {
                case 1:  return "st";
                case 2:  return "nd";
                case 3:  return "rd";
                case _: return "th";
        }
    }
    
    private function formattedDate(v:String):String {
        var date = DateTime.fromString(v);
        return DateFormat.format(date, 'dddd d"${daySuffix(date.day)}" MMMM yyyy');
    }
    
    private function generatePayload(input:DynamicAccess<DynamicAccess<DynamicAccess<String>>>):Payload {
        var paths:Map<Array<String>, Function> = [
            [Ref, '_$Template', Href] => function(values) payload.template = values[0],
            [Ref, Template, Href] => function(values) payload.template = values[0],
            [Ref, Date, Title] => function(values) {
                payload.created.raw = values[0];
                payload.created.pretty = formattedDate(values[0]);
            },
            [Ref, Modified, Title] => function(values) {
                payload.modified.raw = values[0];
                payload.modified.pretty = formattedDate(values[0]);
            },
            [Ref, Published, Title] => function(values) {
                payload.published.raw = values[0];
                payload.published.pretty = formattedDate(values[0]);
            },
            [Ref, Description, Title] => function(values) {
                payload.description = values[0];
            },
            [Ref, Author] => function(values:Array<String>) {
                for (value in values) {
                    var object = haxe.Json.parse(value);
                    payload.authors.push( { display:object.title, url:object.href } );
                }
            },
            [Ref, Contributor] => function(values:Array<String>) {
                for (value in values) {
                    var object = haxe.Json.parse(value);
                    payload.contributors.push( { display:object.title, url:object.href } );
                }
            }
        ];
        
        for (key in paths.keys()) {
            var object:DynamicAccess<Dynamic> = input;
            
            for (segment in key) {
                if (object.exists(segment)) {
                    if (segment == key[key.length - 1]) {
                        var value = object.get( segment );
                        
                        if (Type.typeof(value).match( TObject )) {
                            paths.get( key )( [haxe.Json.stringify( value )] );
                            
                        } else if (Std.is(value, Array) && Type.typeof(value[0]).match( TObject )) {
                            paths.get( key )( [for (v in (value:Array<Dynamic>)) haxe.Json.stringify(v)] );
                            
                        } else if (Std.is(value, Array) && !Type.typeof(value[0]).match( TObject )) {
                            paths.get( key )( (value:Array<String>) );
                            
                        } else {
                            paths.get( key )( [value] );
                            
                        }
                        
                    } else {
                        object = object.get( segment );
                        
                    }
                    
                }
                
            }
            
        }
        
        // Move to external file or make available via command line or environment?
        if (payload.authors.length == 0) payload.authors.push( { display:SkialBainn, url:TwitterSkial } );

        var _modified = this.input;
        if (payload.input.raw == '') payload.input = {
            raw:this.input.normalize(), parts:[for (part in this.input.normalize().split('/')) /*if (basePaths.indexOf(part) == -1)*/ part], 
            filename:this.input.withoutDirectory().withoutExtension(), 
            extension:this.input.extension(),
            directory:(/*[for (part in basePaths) if (_modified.startsWith(part)) _modified = _modified.replace(part, '')] != null ? _modified :*/ _modified).normalize().directory(),
        };

        var _modified = this.output;
        if (payload.output.raw == '') payload.output = {
            raw:this.output.normalize(), parts:[for (part in this.output.normalize().split('/')) /*if (basePaths.indexOf(part) == -1)*/ part], 
            filename:this.output.withoutDirectory().withoutExtension(), 
            extension:this.output.extension(),
            directory:(/*[for (part in basePaths) if (_modified.startsWith(part)) _modified = _modified.replace(part, '')] != null ? _modified :*/ _modified).normalize().directory(),
        };
        
        return payload;
    }

}

typedef EmojiData = {
    var unicode:String;
    var unicode_alternatives:String;
    var name:String;
    var shortname:String;
    var category:String;
    var emoji_order:String;
    var aliases:Array<String>;
    var aliases_ascii:Array<String>;
    var keywords:Array<String>;
}
