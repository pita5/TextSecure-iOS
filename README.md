# TextSecure for iOS

Currently in early development stage.

## Building

1) Clone the repo to a working directory

2) [CocoaPods](http://cocoapods.org) is used to manage dependencies. Pods are setup easily and are distributed via a ruby gem. Follow the simple instructions on the website to setup. After setup, run the following command from the toplevel directory of TextSecureiOS to download the dependencies for TextSecure iOS:

```
pod install
```
If you are having build issues, first make sure your pods are up to date
```
pod update
pod install
```
occasionally, CocoaPods itself will need to be updated. Do this with
```
sudo gem update
```

3) **Temporary** - Building Curve25519-donna manually. This step should be removed soon

- Clone the [git repository](https://github.com/agl/curve25519-donna.git) into `Libraries/src/`
- Run the bash script called `build-libcurve25519.sh`  from within `Libraries/`. This build should be quick, no coffee for you.


4) Open the `TextSecureiOS.xcworkspace` in Xcode. **Note that for CocoaPods to work properly it is very important to always open the workspace and not the `.xcodeproj` file.** Build and Run and you are ready to go!

5) Debugging network calls. If you are contributing networked code, PonyDebugger is integrated in Debug mode of the application. Check out https://github.com/square/PonyDebugger#quick-start and easily debug network code from the iOS simulator

## Certificate Pinning

TextSecure uses certificate-pinning to avoid (wo)man-in-the-middle attacks. If you use your own server, here are the steps to generate the certificate file. 

1) Use OpenSSL to download the certificate (copy-paste the text between the `BEGIN` and `END` into a `cert.pem` file).

```bash
openssl s_client -showcerts -connect textsecure-service.whispersystems.org:443 </dev/null
```
2) Use OpenSSL to convert this PEM certificate into a DER certificate. 

```bash
openssl x509 -inform PEM -outform DER -in cert.pem -out cert.der
```

3) Rename and move `cert.der` to `TextSecureiOS/gcm.textsecure.whispersystems.org.cer`

## Documentation


Looking for documentation? Check out the wiki!

https://github.com/WhisperSystems/TextSecure/wiki

## Interoperability 
The iOS code will be tested to be interoperable with the TextSecure Android push-library branch
```
$ git clone https://github.com/WhisperSystems/TextSecure.git
$ git checkout push-library
$ gradle build
$ adb install -r build/apk/TextSecure-debug-unaligned.apk
```
You'll need gradle > 1.8 installed on your build machine, as well as the
"Android Support Repository" and "Google Repository" installed from the
Android SDK manager on your build machine.
## Contribute

At this early stage there are two primary developers of TextSecure iOS and as we move from the early stages to more advanced ones opportunities will abound to contribute to the core code base. We are particularly interested in support and contributions associated localization, code review, and automated testing. Please contact us.

## Code Conventions

We are trying to follow the [GitHub code conventions for Objective-C](https://github.com/github/objective-c-conventions) and we would really appreciate that pull requests do conform with those conventions. 

In addition to that, always add curly braces to your `if` conditionals, even if there is no `else`.

One note, for programmers joining us from Java or similar language communities, note that [exceptions are not commonly used for errors that may occur in normal use](http://stackoverflow.com/questions/324284/throwing-an-exception-in-objective-c-cocoa/324805#324805) so familiarize yourself with NSError 

## Cryptography Notice

This distribution includes cryptographic software. The country in which you currently reside may have restrictions on the import, possession, use, and/or re-export to another country, of encryption software. 
BEFORE using any encryption software, please check your country's laws, regulations and policies concerning the import, possession, or use, and re-export of encryption software, to see if this is permitted. 
See <http://www.wassenaar.org/> for more information.

The U.S. Government Department of Commerce, Bureau of Industry and Security (BIS), has classified this software as Export Commodity Control Number (ECCN) 5D002.C.1, which includes information security software using or performing cryptographic functions with asymmetric algorithms. 
The form and manner of this distribution makes it eligible for export under the License Exception ENC Technology Software Unrestricted (TSU) exception (see the BIS Export Administration Regulations, Section 740.13) for both object code and source code.

## License

Copyright 2013 Whisper Systems

Licensed under the GPLv3: http://www.gnu.org/licenses/gpl-3.0.html
