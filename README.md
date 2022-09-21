DissertationSubmission
======================

The submitted project code for the applied project of my MSc. Computer Science dissertation.

## Abstract

This is the codebase for an applied project using Human Interactive Security Protocols (HISPs) in a wireless mesh network.  In this project both the group version of Hash Commitment Before Knowledge (HCBK) and Symmetrized Hash Commitment Before Knowledge (SHCBK) have been implemented to ensure secure messaging in an ad-hoc network.  This paper will cover the foundation of HISPs and their related security elements, the application of the protocols in an app for Apple’s iOS operating system, the frameworks of that system that were utilized including the Multipeer Connectivity framework (MCF) that implements the wireless mesh network, and the design decisions made in the development of the app.  The techniques and breadth of this project encompass both a background in computer security as well as the practical implications of object oriented programming.

## Provisioning Links

As stated in Appendix A of the dissertation, below are the relevant instructions and links for provisioning this application onto a device.

Xcode is a free download from [the Mac AppStore](https://itunes.apple.com/en/app/xcode/id497799835?mt=12).

By selecting the "Download Zip" button on the right hand side of the GitHub page, a copy of the application will be added to your local machine.  Because the project uses CocoaPods to import open source libraries, it is best to open the project by double clicking on the appliedHISP.xcworkspace file.  This should load the application into Xcode.  From there it can be run by selecting an iOS device’s simulator from the destination in the upper left and hitting the triangle to compile and run onto that simulator.

[Apple Documentation about running an app.](https://developer.apple.com/Library/ios/documentation/ToolsLanguages/Conceptual/Xcode_Overview/RunYourApp/RunYourApp.html)

Provisioning onto a device requires a provisioning certificate, which is only available if the user has a Developer’s license from Apple.  The process is mostly automated and is explained in detail in [Apple’s documentation.](https://developer.apple.com/library/mac/Documentation/IDEs/Conceptual/AppDistributionGuide/MaintainingProfiles/MaintainingProfiles.html#//apple_ref/doc/uid/TP40012582-CH30-SW2)

Once provisioned, the device can be run the same as in the simulator, by selecting it in the Destination and hitting the Run button.  More information is available [from Apple.](https://developer.apple.com/library/mac/Documentation/IDEs/Conceptual/AppDistributionGuide/LaunchingYourApponDevices/LaunchingYourApponDevices.html)

Obviously, to send messages or run a HISP, more than one device will need to be active, as more than one actor is required to run the protocols and every message needs both a sender and recipient.  This download and install process has been tested on Macs and it has also been verified that two Macs each running an iPhone simulator can also communicate with each other.  So in lieu of a Developer’s license, two Macintosh computers within WiFi or Bluetooth range of each other can test the functionality of the application.  


## Libraries and Licensing

This project incorporates the following libraries, each available on github under the [MIT License](http://opensource.org/licenses/MIT)

* [Diffie-Hellman-iOS](https://github.com/benjholla/Diffie-Hellman-iOS)
* [RNCryptor](https://github.com/RNCryptor/RNCryptor)
* [LTHPasscodeViewController](https://github.com/rolandleth/LTHPasscodeViewController)
* [JSQMessagesViewController](https://github.com/jessesquires/JSQMessagesViewController) with the associated [JSQSystemSoundPlayer](https://github.com/jessesquires/JSQSystemSoundPlayer)  

* Icons for each of the three views in the tab bar controller were provided by [PixelLove.com](http://www.pixellove.com) under the [Creative Commons License](http://creativecommons.org/licenses/by/3.0/deed.en)

* Much of the technology around the HCBK protocols are subject to international patents and licensing.  For more informations please visit the [Oxford HCBK website.](http://www.cs.ox.ac.uk/hcbk)
