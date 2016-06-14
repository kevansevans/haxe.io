[template]: ../../templates/interview.html
[author]: https://twitter.com/cballesterosvel "@cballesterosvel"
[date]: / "2016-06-14"
[modified]: / "2016-06-14"

![profile carlos ballesteros]

## How did you get started in programming? and/or How did you get started in your specific field?

I started learning with QBASIC 1.0/MS-DOS when I was 9. My brother (@maballesteros) which is 12 years older than me, teached me. I started modifying programs that came with QBASIC. And since it had a great documentation and it was in spanish, I was able to understand some stuff. One year as a holiday gift, my brother brought me some diskettes downloaded from the Internet at the university with lots of QBASIC source code. Since I didn’t had Internet by then, that was just awesome. And started to appreciate people that shared its code, and let me learn that much. That’s why I love OSS. I liked videogames and started to get interest in emulators.
After some time I started to mix QBASIC with ASM x86. Then learned PHP and started to work at 14 on web development (both frontend and backend). Then learned C, D, C#, Java, Haxe among other languages, in lots of years.

Even when I was working as web developer I always invested some more time in other programming thinks I like, like games, mmorpgs and emulators.
So I ended working for Our.com and later for Akamon.com where I’m currently working.

## What is your job?
I’m tech lead at akamon.com. I created our client framework to create games: inversion of control, high performance graphics, scenes, websockets and so on. From half a year also I’m working on JTransc, the project I created.

## Who do you work for?
Akamon.com

## Do you use Haxe at work?

## Are there any areas you want/can see Haxe fitting in perfectly?

I have created several haxe libraries we are currently using. Also JTransc itself generates haxe, and I am embedding haxe code frequently.
It fits perfectly in our client: we want to target javascript, while being able to generate flash to support older browsers and integrating with legacy code, and we want to go native mobile too.

## Out of the various Haxe IDE's available, which one(s) do you use?
If you use more than one, why?
What other software do you find vital while working with Haxe?
Do you integrate any cloud based services while working with Haxe?

intelliJ for pure haxe projects, though sometimes I just end using a text editor for small snippets.
No special vital software as far as I know.
No we are not integrating it with any cloud based services.

## What hardware you do you use?

Usually I’m using a Macbook Pro, while other times I use a windows machine. When targeting an android phone, an android tablet and an iPhone.

## What problem does using Haxe solve for you?
What features of Haxe won you over?
Did you consider any other languages? Why didnt you choose them?
What ticks you off about Haxe, if anything? Lack of feature? Something else? How should it be fixed?

Multitarget is just great.
We tried several options:
TypeScript: cool but just targets javascript, IDE’s are not too good handling module based languages yet. Not real int32 integers. It is easy to mess things. Not that safe as expected. Even that I have a huge project: jspspemu written in it.

Dart: cool, but you can get runtime with errors. Syntax is not that good. Integers work different on javascript (doubles) that on plain dart (bigints). Still not good at multitarget.

Scala: has scala.js and have cool functional stuff. But generated code was not too good. Also people didn’t liked syntax, and was way too easy to create unreadable code. I started https://github.com/soywiz/java-aot by then and I was able to generate AS3 code and to run scala in it. That was a project before JTransc.

Haxe: I migrated our framework to haxe and we were going to finally use it, but Kotlin appeared. So we ended using JTransc so we are using Kotlin + Haxe :)

## What compiler targets do you use?
If you only use one target, why?
If you use more than one, for what reason?
As a complete stack?
As seperate, target specific libraries?
What else?

We are currently using: js, flash and C++.
In order to be able to target web and mobile devices while being able to transition from our flash legacy code.

## What platforms to do deploy to?
Mobile, browser, embedded, server, etc

Currently browser and mobile.

## What would you like to see added to the Haxe compiler?
A new target?
A new feature?
Any feature from another language?

Target: ILLVM and (objective-c/swift) adding support for ARC to haxe (with a metadata to mark fields as @:weak)
Features (from other languages):
Labeled breaks (to be able to generate better code)
\#line preprocessor (to be able to get cool stacktraces and sourcemaps)
Goto? so I don’t have to deal with that stuff? :)

## What tips or resources would you recommend to a new Haxe user?

I use a lot:
http://api.haxe.org/
http://code.haxe.org/
Github repositories (issues and files). What I do lot is to go to a github repository, then I press t, and just search for files.

## What Haxe libraries/frameworks are you impressed by/do you use?

lime/openfl, now also kha.

## What problem would you like to see solved by a new or existing Haxe library?

What I usually expect is consistency between targets. So everything just work on each target the same way it work on others. Haxe Std itself and libraries too have to ensure that.

## What is the best use of Haxe you've come across?

Multitarget. Games.

## Where do you get your inspiration?
Music?
Any specific books you strongly recommend?
In general
From/for your specific field

I usually listen to Music while working, also I watch anime and some series. I have a stuff called “random weekend”. I think on a thing, even if it is the craziest one and start working on it the whole weekend. Sometimes I don’t even sleep too much. I don’t even expect to finish it. But it is really fun, and that’s all about it. Sometimes I came with stuff that I really like, and continue with the project other weekends or in my spare time.
Which creatives/developers/artists (do you admire most?/that impress you)?
I like lots of stuff. I couldn’t choose.

## What contributions are you proud of?
Do you use them in your projects? Which?
Did your contributions bring you work opportunities?

I have lots of OSS projects. I used or use most of them. The most complex ones are probably my psp emulators [dpspemu, cspspemu and jspspemu] and jtransc. 

## Tell us about your WWX talk?

It is about JTransc. A project that aims to convert JVM bytecode into Haxe, and then into something that haxe targets.
It was created in a whole-holiday crazy spike. To determine whether it was possible to do it. It was.

## What is the best part of WWX for you/are you looking forward too?

Know about awesome stuff people is creating. It is inspiring. And I think I will be able to use some of them.
