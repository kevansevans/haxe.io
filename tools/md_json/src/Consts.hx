package ;

@:enum @:forward abstract Consts(String) from String to String {

}

@:enum @:forward abstract Defaults(String) from String to String {
    var SkialBainn = 'Skial Bainn';
    var TwitterSkial = '//twitter.com/skial';
}

@:enum @:forward abstract AttributeConsts(String) from String to String {
    var Href = 'href';
    var Title = 'title';
}

@:enum @:forward abstract ExtensionsConsts(String) from String to String {
    var Svg = '.svg';
}

@:enum @:forward abstract MarkdownConsts(String) from String to String {
    var Ref = 'references';
    var Author = 'AUTHOR';
    var Contributor = 'CONTRIBUTOR';
    var Template = 'TEMPLATE';
    var Date = 'DATE';
    var Modified = 'MODIFIED';
    var Published = 'PUBLISHED';
    var Description = 'DESCRIPTION';

}