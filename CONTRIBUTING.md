## Contribute

At this early stage there are two primary developers of TextSecure iOS: [@corbett](https://github.com/corbett) and [@FredericJacobs](https://github.com/fredericjacobs) and as we move from the early stages to more advanced ones opportunities will abound to contribute to the core code base. We are particularly interested in support and contributions associated localization, code review, and automated testing, with any of the [Open Issues](https://github.com/WhisperSystems/TextSecure-iOS/issues?state=open) or [Milestones](https://github.com/WhisperSystems/TextSecure-iOS/issues/milestones?state=open). It may help to open an issue or milestone if you plan to make a contribution so we can be sure to clarify questions, give an overview of architectural plans, and ensure we do not overlap work.

## Code Conventions

We are trying to follow the [GitHub code conventions for Objective-C](https://github.com/github/objective-c-conventions) and we appreciate that pull requests do conform with those conventions. 

In addition to that, always add curly braces to your `if` conditionals, even if there is no `else`.

One note, for programmers joining us from Java or similar language communities, note that [exceptions are not commonly used for errors that may occur in normal use](http://stackoverflow.com/questions/324284/throwing-an-exception-in-objective-c-cocoa/324805#324805) so familiarize yourself with **NSError** 

## Tabs vs Spaces

It's the eternal debate. We chose to adopt spaces. Please set your default Xcode configuration to 4 spaces for tabs, and 4 spaces for indentation (it's Xcode's default setting).

![Tabs vs Spaces](http://cl.ly/TYPZ/Screen%20Shot%202014-01-26%20at%2019.02.28.png)

If you don't agree with us, you can use the [ClangFormat Xcode plugin](https://github.com/travisjeffery/ClangFormat-Xcode) to code with your favorite indentation style!

## BitHub

Open Whisper Systems is currently [experimenting](https://whispersystems.org/blog/bithub/) with the funding privacy Free and Open Source software. Payements are opt-in for the `TextSecure-iOS` repo and can be enabled by adding `MONEYMONEY` in a commit message string. For example, this is the current Open WhisperSystems payout per commit, rendered dynamically as an image by the Open WhisperSystems BitHub instance:

![Bithub Payment Amount](https://bithub.herokuapp.com/v1/status/payment/commit?format=png)
