# Digitally sign and verify documents with the GPG GUI wrapper  
This repository contains two apps:  
1. Digitally sign a document
2. Check document digital signature

Version:     0.9  
License:     GNU GPLv3

## Digitally sign a document  
##### General info:  
This application is designed for signing contracts, agreements, and other
documents with a digital signature in cases where this form of transaction
is not prohibited.  
##### Application features:  
1. create digital signature keys;
2. sign a file with a digital signature;
3. export a public key for a third party.

## Check document digital signature  
##### General info:  
This application is designed for digital signatures verification, and
documents integrity verification, signed with GPG and the application
"Digitally sign a document".  
##### Application features:  
1. check a digital signature;
2. import a public key from a signing person.

### System requirements:  
Current version tested on:  
Windows 10 1909  
macOS Big Sur (version 11, x86_64, on arm should work too)  
Ubuntu 20.04 LTS (gpg version 2 package required)  

### Installation:  
Binary distributions for all operating systems mentioned above can be found in builds directory. Please, see the notes below, otherwise the apps will produce unpredictable errors.  
**Notes:**
* On Windows install the apps into a path which contains only English characters.
* On macOS you need to allow installation from any sources (other than AppStore).
* On Linux if you have non-English locale it is necessary to remove (rename) gpg localization files in order to make gpg to use only English output messages (e.g. on Ubuntu 20.04: `sudo mv /usr/share/locale-langpack/your_locale/LC_MESSAGES/gnupg2.mo /usr/share/locale-langpack/your_locale/LC_MESSAGES/gnupg2.mo.old` with your_locale changed to your language locale). On Linux you unpack and run the apps from any folder.

### Technical details:  
Application utilizes to function GPG program: https://gnupg.org  
It basically simplified graphical user interface for that program.  
Source code written in PureBasic: https://www.purebasic.com  

## Screenshots  
Linux:  
![Digitally sign a document app](images/linux-esign.png?raw=true "Digitally sign a document app")
![Check document digital signature app](images/linux-check.png?raw=true "Check document digital signature app")

macOS:  
![Digitally sign a document app](images/macos-esign.png?raw=true "Digitally sign a document app")
![Check document digital signature app](images/macos-check.png?raw=true "Check document digital signature app")

### Version History:  
0.9 - translated to English.  
0.8 - added: help, view the file to sign, other improvements.  
0.7 - initial version, however, never released.  
