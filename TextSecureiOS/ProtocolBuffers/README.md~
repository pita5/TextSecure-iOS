# protoc supported for iOS via cocoapods. 
added to Podfile
```pod 'GoogleProtobuf', 		'~> 2.5.0'```
ran
```pod install```

# protobuffer format from:
https://github.com/WhisperSystems/TextSecure/blob/push-library/library/protobuf/IncomingPushMessageSignal.proto

#protoc compiler generate from pod
run with 
```../../Pods/GoogleProtobuf/bin/protoc -I=`pwd` --cpp_out=`pwd` `pwd`/IncomingPushMessageSignal.proto ```

# Objective-C++ code wrapper code written
Code that includes this header is itself objective C++ and must be named accordingly (.hh/.mm extension) to compile, that means that after you compile your classes (compiler will generate pb.h and pb.cc, so these must be moved to pb.hh and pb.cc respectively)




