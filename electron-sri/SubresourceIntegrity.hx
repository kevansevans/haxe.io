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
import haxe.Constraints.Function;

using StringTools;
using haxe.io.Path;
using tink.CoreApi;

@:enum abstract Consts(String) from String to String {
	var Link = 'link';
	var Href = 'href';
	var Script = 'script';
	var Src = 'src';
	var Body = 'body';
	var Meta = 'meta';
	var Content = 'content';
	var Integrity = 'integrity';
	var Sha512 = 'sha512';
	var Id = 'subresource$Integrity';
	var Hex = 'hex';
	var Base64 = 'base64';
	var Search = 'search';
}

@:jsRequire('postcss')
extern class PostCss {

    public function new(plugins:Array<Dynamic>);
    public function process(css:String, ?options:{from:String, to:String}):js.Promise<{css:String}>;

}

@:cmd
@:expose('subresourceintegrity')
class SubresourceIntegrity {
	
	/**
	The source directory.
	**/
	@alias public var root:String;

	/**
	The base path to load resources from.
	*/
	@alias('rs')
	public var resourcePath:String;
	
	private var hashedPaths:StringMap<String> = new StringMap();
	private var input:String = '';
	private var counter:Int = 0;
	private var redundantNames:Array<String> = [];
	
	private static var data:{args:Array<String>};
	private var final:CallbackList<Noise->Void> = new CallbackList();
	
	public static function main() {
		make();
	}

	private static var single:SubresourceIntegrity;

	public static function make():SubresourceIntegrity {
		if (single == null) {
			data = tink.Json.parse( window.sessionStorage.getItem( 'data' ) );
			single = new SubresourceIntegrity( data.args );
		}
		return single;
	}
	
	public function new(args:Array<String>) {
		@:cmd _;
		
		var nodes = [for (n in window.document.querySelectorAll('$Link[$Href], $Script[$Src], $Body [$Src], $Meta[$Content*="ms"]')) n];

		final.add( function(cb:Callback<Noise>) {
			var nodes:Array<DOMElement> = cast nodes;
			console.log( nodes );
            for (node in nodes) if (node.hasAttribute(Integrity)) {
                var value = node.getAttribute(Integrity);
				console.log( Id, redundantNames );
				for (name in redundantNames) if (value.indexOf(name) > -1) {
					value = value.replace('sha512-$name', '');
				}

				node.setAttribute(Integrity, value.trim());

            }
            
			cb.invoke(Noise);
        } );

		var futures = [for (node in nodes) {
			process( switch node.nodeName.toLowerCase() {
				case Link: Href;
				case Script: Src;
				case Meta: Content;
				case _: Src;
			}, cast node );
			
		}];

		Future.ofMany(futures).handle(function(results) {
			console.log( results.filter( r -> r.match(Failure(_)) ) );
			window.document.dispatchEvent( new CustomEvent('$Id:complete', {detail:Id, bubbles:true, cancelable:true}) );
		});
		
	}
	
	private function process(attr:String, node:DOMElement):Surprise<String, String> {
		var result = Future.trigger();
		var value:String = node.getAttribute( attr );
		var url = parse( value, true, true );
		
		switch url.host {
			case null, '', _.indexOf('haxe.io') > -1 => true:
				if ((url.query:DynamicAccess<String>).exists('v')) {
					Reflect.deleteField(url, Search);
					(url.query:DynamicAccess<String>).remove('v');

				}
				var formattedUrl = format( url ).normalize();
				
				var f = hash(formattedUrl, Hex) >>
				function (o:Outcome<Pair<String,String>, String>) {
					return switch o {
						case Success(pair):
							modifyUrl(node, attr, '', pair.b);

						case Failure(error):
							Future.sync(Failure(error));

					}
				} >>
				function (o:Outcome<String, String>) {
					return switch o {
						case Success(clone):
							hash(clone, Base64) >>
							function(r:Outcome<Pair<String, String>, String>) {
								return switch r {
									case Success(pair):
										redundantNames.push( pair.b );
										modifiySri(node, '', pair.b);
										o;

									case Failure(error):
										o;

								}
							} 
						case Failure(error):
							Future.sync(o);

					}
				} >>
				function (o:Outcome<String, String>) {
					return switch o {
						case Success(clone):
							console.log( clone );
							var postcss = new PostCss([
								/*require('postcss-font-magician')({
									//display: "swap", // Causes issue further down if specified.
									variants: {
										"Open Sans": {
											"400": [],
										},
										"Gentium Book Basic": {
											"400": [],
											"700 italic": []
										}
									}
								}),*/ require('autoprefixer'), require('postcss-sorting'),
								require('postcss-merge-rules'), require('cssnano')
							]);
							Future.ofJsPromise(postcss.process(sys.io.File.getContent(clone))) >>
							function (o:Outcome<{css:String}, Error>) {
								return switch o {
									case Success(result):
										console.log(clone);
										var opt = clone.replace(root, resourcePath);
										sys.io.File.saveContent(opt, result.css);
										console.log( opt );
										hash(opt, Base64) >>
										function (o:Outcome<Pair<String, String>, String>) {
											return switch o {
												case Success(pair):
													modifiySri(node, '', pair.b);

												case Failure(error):
													Future.sync(Failure(error));

											}
										}

									case Failure(error):
										Future.sync(Failure(error.message));

								}
							}

						case Failure(error):
							Future.sync(Failure(error));

					}
				};
				f.handle( function(results) {
					console.log( results );
					console.log( node );
					result.trigger(Success(''));
				} );

			case _:
				result.trigger(Failure('' + url.host));


		}

		return result.asFuture();
	}
	
	private function modifyUrl(node:DOMElement, attr:String, event:String, hash:String):Surprise<String, String> {
		var result = Future.trigger();

		if (hash != 'failed') {
			var value:String = node.getAttribute( attr );
			var url = parse( value, true, true );
			
			Reflect.deleteField(url, Search);
			if (url.query == null) url.query = {};
			if ((url.query:DynamicAccess<String>).exists('v')) {
				Reflect.deleteField(url, Search);
				(url.query:DynamicAccess<String>).remove('v');
				
			}

			// Copy and rename file using hash value.
			var prefix = '${Sys.getCwd()}/$root';
			var filename = hash.substring(hash.length - 8);
			var renamed = url.pathname.directory() + '/$filename.' + url.pathname.extension();
			var source = '$prefix/${url.pathname}'.normalize();
			var clone = '$prefix/$renamed'.normalize();
			
			if (sys.FileSystem.exists(source) && !sys.FileSystem.exists(clone)) {
				sys.io.File.copy(source, clone);

			}

			url.pathname = url.pathname.replace( url.pathname.withoutDirectory().withoutExtension(), filename );
			
			//(url.query:DynamicAccess<String>).set('v', filename);
			
			node.setAttribute( attr, format( url ));

			result.trigger(Success(clone));
			
		} else {
			console.log( 'sri hashing failed', event, hash, node.getAttribute(attr) );
			result.trigger(Failure('sri hashing failed'));
			
		}
		
		//counter--;
		//if (counter < 1) window.document.dispatchEvent( new CustomEvent('subresourceintegrity:complete', {detail:'subresourceintegrity', bubbles:true, cancelable:true}) );
		return (result.asFuture():Surprise<String, String>);
	}
	
	private function modifiySri(node:DOMElement, event:String, hash:String) {
		if (!node.hasAttribute(Integrity)) {
			node.setAttribute(Integrity, '$Sha512-$hash');

		} else {
			node.setAttribute(Integrity, node.getAttribute(Integrity) + ' $Sha512-$hash');

		}
		node.setAttribute('crossorigin', 'anonymous');
		return Future.sync(Success(Noise));
		//counter--;
		//if (counter < 1) window.document.dispatchEvent( new CustomEvent('subresourceintegrity:complete', {detail:'subresourceintegrity', bubbles:true, cancelable:true}) );
	}
	
	private function hash(/*event:String, */url:String, encoding:String/*, cb:String->String->Void*/):Surprise<Pair<String, String>, String> {
		var result = Future.trigger();
		var path = sys.FileSystem.exists(url) ? url : (resourcePath + input.directory() + url).normalize();
		console.log( url );
		if (path.extension() == '') path += '/index.html';
		
		if (hashedPaths.exists(path)) {
			//cb('content::hashed::$arg', hashedPaths.get( path ));
			result.trigger(Success(new Pair(url, hashedPaths.get( path ))));
			
		} else {
			stat(path, function(error, stats) {
				if (error == null && stats.isFile()) {
					var hash = createHash(cast Sha512);
					var stream = createReadStream(path);
					
					stream.on('readable', function() {
						var data = stream.read();
						
						if (data != null) {
							hash.update(data);
							
						} else {
							var digest = hash.digest( encoding );
							hashedPaths.set( path, digest );
							//cb('content::hashed::$arg', digest);
							result.trigger(Success(new Pair(url, digest)));
						}
					});
					
				} else {
					//console.log( error );
					//cb('content::hashed::$arg', 'failed');
					result.trigger(Failure('$error'));
					
				}
				
			});
			
		}

		return (result.asFuture():Surprise<Pair<String, String>, String>);
	}
	
}
