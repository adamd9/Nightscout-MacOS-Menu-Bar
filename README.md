# Nightscout MacOS Menu Bar

## Download from the Mac App Store
[Click here to get it from the App Store](https://apps.apple.com/au/app/nightscout-menu-bar/id1639776072?mt=12)

## Overview

This app was built in the same spirit as the previous two great solutions to show your key Nightscout stats in the Mac OS menu bar:
* [mddub/nightscout-osx-menubar - GitHub](https://github.com/mddub/nightscout-osx-menubar)
* [Nightscout Menu Bar - GitHub](https://github.com/mpangburn/NightscoutMenuBar)

This solution is 100% native (no Python or external dependancies), and adds a few extra features/info.

[![main app screenshot](/assets/screenshot_opened_small.png)](/assets/screenshot_opened.png)

## Key Features
* Show your current BG in the system bar at the top of your screen on Mac
* Get some additional details for those of you also looping, such as IOB, COB and pump stats.
* Show a mini version of the graph (including predictions) when you click on the widget
* Access your recent BG history
* Indicate to you when the data is stale (due to readings not being in Nightscout
* Option to start automatically on login

## Planned Features
* Allow the setup of multiple profiles to monitor more than one person


## How to Support
<a href="https://ko-fi.com/adamdinneen" target="_blank">
    <img src="https://az743702.vo.msecnd.net/cdn/kofi3.png?v=0" alt="Buy Me a Coffee at ko-fi.com" height="46">
</a>

I do this because I'm a type 1 diabetic myself (and use a Mac). I'm not doing it to make money, but a few people have asked to contribute so here's the deal:
* If I get up to USD 99 in donations in a year, this will go to paying for my Apple Developer License
* Anything over USD 99 I'll donate to the Nightscout foundation (https://www.nightscoutfoundation.org/)

## Problems
Problems can be reported in the app by clicking **Report an issue** in the main menu.

## How to install
There is not currently an installable package, but there will be soon!

## How to build
There's nothing to it - just download or clone and run from Xcode.

## how to use a crash report
```
dSYMs atos -o Nightscout\ Menu\ Bar.app.dSYM -l 0x1043fc000 0x104419bb4
bgValueFormatted(entry:) (in Nightscout Menu Bar) (NightscoutMenuBar.swift:529)
```

The dSYM files are generated when you build your application in Xcode. They contain the debug symbols for your application, which are crucial for symbolication of crash reports. Here's how you can find them:

Within Xcode:

If you have archived your app using Xcode, the dSYM files will be included in the archive. To locate them:
Open Xcode and go to the "Window" menu.
Select "Organizer".
Choose your app from the list of archives.
Right-click on the archive and select "Show in Finder".
Right-click on the archive in Finder and choose "Show Package Contents".
You will find the dSYM files in the "dSYMs" folder.

In the provided crash report, you can identify the load address and the memory address where the crash occurred:

Load Address: This is the base address where the application binary is loaded into memory. In your crash report, the load address for the "Nightscout Menu Bar" application is listed in the lines where the crash occurred. It is the hexadecimal number right after the application name in each line of the "Thread 0 Crashed" section. For the first line of the crash (0 Nightscout Menu Bar 0x104419bb4 0x1043fc000 + 121780), the load address is 0x1043fc000. This address is where the app's executable is loaded in memory.

Memory Address (Crash Address): This is the specific address at which the crash occurred. It's often the address where an exception or a problematic instruction was executed. In your report, it's the second hexadecimal number in the line where the crash occurred. For the same line (0 Nightscout Menu Bar 0x104419bb4 0x1043fc000 + 121780), the memory address where the crash happened is 0x104419bb4.

## Disclaimer
This project is intended for educational and informational purposes only. It is not FDA approved and should not be used to make medical decisions. It is neither affiliated with nor endorsed by Dexcom.
