```metadata
author: "By Rich Turton"
number: "1"
title: "Chapter 1: What's New in Swift 3"
```
# Chapter 1: What's New in Swift 3

## Outline

There is no sample project that makes sense for this chapter, and the playgrounds in the screencast were mostly there so the code could be visualised. Therefore I propose that this is a theory-only chapter with lots of code examples, but the reader is not really expected to build anything. 

LANGUAGE FEATURES:

- Stuff that's gone and how to replace it
	- ++
	- c style for loops
	- currying
- Stuff that's changed
	- Closures
		- Closures - escaping or non-escaping
		- Closure definition syntax
	- Generics
		- Constraints now at the end of the function signature
	- Renaming of internal types
		- SequenceType -> Sequence
		- Generator -> Iterator
- New stuff
	- Access control
		- open
		- fileprivate
	- Key paths
	- Enums - cases are lower camel case now

RENAMING: 

- The Grand Renaming
	- Rationale: 
		- Clarity at the call site
		- Assume common patterns and variable naming conventions
		- Omit needless words
	- Some examples (as from the screencasts)
	- Overloading rule and examples
	- Function, method, property naming rules:
		- Verb / noun side effects rule
		- ed / ing
		- Don't name first argument unless it doesn't make sense when calling
		- Bools are is-prefixed
	- How has this been achieved with UIKit and foundation?
	
PRACTICAL EXAMPLES OF API CHANGES:

- Foundation 
	- value type wrapping
		- Quick overview of value and reference types
		- Which types make sense to be value types
		- Wrapping the underlying reference type
		- Copy-on-write
	- Global enums -> Nested
	- Notification.Name
	- Set algebra for index and character sets
	- Default optional parameters (date components)
	- Data now can be treated as a collection
- C APIs
	- NS_SWIFT_NAME - brief overview
	- Global functions now appear more at the type level
	- GCD examples
	- Core graphics examples
	