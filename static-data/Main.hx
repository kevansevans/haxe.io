package ;

using Std;
using StringTools;
using haxe.io.Path;
using sys.FileSystem;

typedef FileList = {
    var b:String;
    var p:Array<String>;
}

class Main {

    public static function main() {
        var files = [];
        var paths = [];
        var sources = [];
        var args = Sys.args();
        var cwd = Sys.getCwd();
        var output = 'filelist.json';
        var recursive = true;

        for (i in 0...args.length) {
            var arg = args[i];
            var has = () -> i+1 <= args.length;
            var next = () -> args[i+1];
            switch arg {
                case '-s' if (has()): sources.push( next() );
                case '-d' if (has()): paths.push( next() );
                case '-r' if (has()): recursive = !next().startsWith('f');
                case '-o' if (has()): output = next();
                case '-h':
                    Sys.println('usage:\ntool -s sourceDirectory -d directory -o filename.json');
                    return;
                    
                case _:

            }

        }

        var directories = [];
        for (s in sources) for (p in paths) if ('$cwd/$s/$p'.normalize().exists()) directories.push('$cwd/$s/$p'.normalize());
        var matches = directories.copy();

        while (directories.length > 0) {
            var directory = directories.shift();

            for (path in directory.readDirectory()) {
                if (!'$directory/$path'.isDirectory()) {
                    files.push( '$directory/$path'.normalize() );

                } else if (recursive) {
                    directories.push( '$directory/$path'.normalize().addTrailingSlash() );

                }

            }

        }

        function reduce(value:String) {
            var r = value;
            for (m in matches) if (r.startsWith(m)) {
                r = r.replace(m, '');
                break;
            }

            return r;
        }

        var md = files
            .filter( f -> f.endsWith('.md') )
            .map(reduce)
            .map( m -> m.startsWith('/') ? m.substring(1) : m );

        var html = md
            .map( m -> m.withoutExtension().replace(Sys.getCwd().normalize(), '') );

        var sub:String->Int = a -> a.parseInt();
        html.sort( (a,b) -> sub(a) > sub(b) ? -1 : 1 );

        var fileList:FileList = { b:paths[0].normalize(), p:html };
        sys.io.File.saveContent( '${Sys.getCwd()}/$output', tink.Json.stringify(fileList) );
    }

}