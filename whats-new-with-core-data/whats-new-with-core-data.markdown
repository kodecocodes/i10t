```metadata
author: "By Rich Turton"
number: "11"
title: "Chapter 11: What's new with Core Data"
```
# Chapter 11: What's new with Core Data

**Outline**

## Introduction - theme of core data this year is less code. Code generation, boilerplate for setup, strongly typed things. The features to cover are:

- NSPersistentContainer - what it replaces and what it offers
- Automatic generation of NSMO subclass code
- Typed fetch requests
- Typed fetch results controller
- Init method with context

Target audience is already familiar with core data. There are other new features but they are far too involved for an overview and not really applicable to a wide audience.  

## Instructions

The reader will create from scratch (not using the apple template) a core data based app. It'll be something simple like a list of things that the user can rate or check off or modify in some simple way. There will be a simple UI for editing or adding data which will use a child context. 

This will exercise each new feature listed above. 

I don't want to spend too much time on the UI since that's not the important part, but you can't really make a starter project for a core data app since none of the model files will be present.

## If room

Some fake JSON coming from a web service to show the background task API of the persistent container.
Something happening on the main context while an editing view is being shown, demonstrating the changes flowing through.




