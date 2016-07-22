//
//  MIDIManager.swift
//  SwiftMIDIThru
//
//  Created by Gene De Lisa on 7/22/16.
//  Copyright © 2015 Gene De Lisa. All rights reserved.
//

import Foundation
import CoreMIDI
import CoreAudio
import AudioToolbox

/// The `Singleton` instance
private let MIDIManagerInstance = MIDIManager()


/**
 # MIDIManager
 
 > Here is an initial cut at using the new Swift 2.0 MIDI frobs.
 
 */
class MIDIManager : NSObject {
    
    class var sharedInstance:MIDIManager {
        return MIDIManagerInstance
    }
    
    var midiClient = MIDIClientRef()
    
    var outputPort = MIDIPortRef()
    
    var inputPort = MIDIPortRef()
    
    var destEndpointRef = MIDIEndpointRef()
    
    var midiInputPortref = MIDIPortRef()
    
    var midiThru = MIDIThruConnectionRef()
    
    var musicPlayer:MusicPlayer?
    
    var processingGraph:AUGraph?
    
    var samplerUnit:AudioUnit?
    
    /*
     func createThrus(source:MIDIEndpointRef?, dest:[MIDIEndpointRef]?) {
     
     var status = OSStatus(noErr)
     
     var thru = MIDIThruConnectionRef()
     
     var params = MIDIThruConnectionParams()
     MIDIThruConnectionParamsInitialize(&params)
     
     if let s = source {
     params.sources.0.endpointRef = s // it's a tuple
     params.numSources = 1
     }
     
     if let d = dest {
     for var i:Int = 0; i < d.count; i++ {
     let thruEnd = MIDIThruConnectionEndpoint(endpointRef: d[i], uniqueID: MIDIUniqueID(i))
     params.destinations.i = thruEnd
     }
     
     var foo = Int(0)
     params.destinations.0 = nil
     
     //            for (index, me) in d {
     //
     //            }
     
     
     //            //            params.destinations.0.endpointRef = thruEnd.endpointRef
     //            params.numDestinations = 1
     }
     }
     */
    
    
    func createThru(source:MIDIEndpointRef?, dest:MIDIEndpointRef?) -> MIDIThruConnectionRef {
        
        var params = MIDIThruConnectionParams()
        MIDIThruConnectionParamsInitialize(&params)
        
        if let s = source {
            let thruEnd = MIDIThruConnectionEndpoint(endpointRef: s, uniqueID: MIDIUniqueID(1))
            params.sources.0 = thruEnd
            params.numSources = 1
            print("thru source is \(s)")
            
        }
        
        if let d = dest {
            let thruEnd = MIDIThruConnectionEndpoint(endpointRef: d, uniqueID: MIDIUniqueID(2))
            params.destinations.0 = thruEnd
            //            params.destinations.0.endpointRef = thruEnd.endpointRef
            params.numDestinations = 1
            print("thru dest is \(d)")
        }
        
        // now set up params
        
        // don't let these through
        params.filterOutSysEx = 1
        params.filterOutMTC = 1
        params.filterOutBeatClock = 1
        params.filterOutTuneRequest = 1
        
        //        params.lowNote = 65
        //
        //        var map = MIDIValueMap(value:(
        //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
        //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
        //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
        //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
        //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
        //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
        //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
        //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
        //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
        //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
        //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
        //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
        //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0)
        //        ))
        
        // params.maps is commented out right now!
        //        var m = MIDIValueMap()
        //        m.value.0 = 100
        
        
        
        
        
        // transform the value using a map; param is the index of the map in the connection's array of maps.
        //        params.velocity = MIDITransform(transform:MIDITransformType(kMIDITransform_MapValue), param:0)
        //        params.numMaps = 1
        
        params.noteNumber = MIDITransform(transform:.add, param:24)
        
        print("setting params \(params)")
        
        let nsdata = withUnsafePointer(&params) { p in
            NSData(bytes: p, length: MIDIThruConnectionParamsSize(&params))
        }
        
        // toll free bridge from CFData to NSData
        var status = MIDIThruConnectionCreate("com.rockhoppertech.MyMIDIThru", nsdata, &self.midiThru)
        if status == noErr {
            print("created thru \(self.midiThru)")
        } else {
            print("error creating thru \(status)")
            CheckError(status)
        }
        
        /*
        let buf = [UInt8]()
        var cfd = CFDataCreate(kCFAllocatorDefault,  buf,  1)!
        var data:Unmanaged<CFData> = &cfd
        status = MIDIThruConnectionGetParams(self.midiThru,  &cfd)
        CheckError(status)
//        let pd = data.takeUnretainedValue()
//        print("retrieved params \(pd)")

  
        if let d = data {
            //            let pd = d.takeUnretainedValue() as! MIDIThruConnectionParams
            let pd = d.takeUnretainedValue()
            //let o = d.toOpaque()
            //let ppp = Unmanaged<MIDIThruConnectionParams>.fromOpaque(o)
            // MIDIThruConnectionParams is a struct and not a class
            
            print("retrieved params \(pd)")
        }
*/
        
        return self.midiThru
    }
    
    
    func createThru2(source:MIDIEndpointRef?, dest:MIDIEndpointRef?)  {
        
        
        var params = MIDIThruConnectionParams()
        MIDIThruConnectionParamsInitialize(&params)
        
        if let s = source {
            let thruEnd = MIDIThruConnectionEndpoint(endpointRef: s, uniqueID: MIDIUniqueID(1))
            params.sources.0 = thruEnd
            params.numSources = 1
            print("thru source is \(s)")
        }
        
        if let d = dest {
            let thruEnd = MIDIThruConnectionEndpoint(endpointRef: d, uniqueID: MIDIUniqueID(2))
            params.destinations.0 = thruEnd
            params.numDestinations = 1
            print("thru dest is \(d)")
        }
        
        // now set up the other params
        
        // don't let these through
        params.filterOutSysEx = 1
        params.filterOutMTC = 1
        params.filterOutBeatClock = 1
        params.filterOutTuneRequest = 1
        
        // try a transform - add 24 o noteNumbers
        params.noteNumber = MIDITransform(transform:.add, param:24)
        
        // Srsly?
        let nsdata = withUnsafePointer(&params) { p in
            NSData(bytes: p, length: MIDIThruConnectionParamsSize(&params))
        }
        
        // toll free bridge from CFData to NSData
        let status = MIDIThruConnectionCreate("com.rockhoppertech.MyMIDIThru", nsdata, &self.midiThru)
        if status == noErr {
            print("created thru \(self.midiThru)")
        } else {
            print("error creating thru \(status)")
        }
    }
    
    
    
    //     func setupMIDIThru(srcEndpoint:MIDIEndpointRef?, destEndpoint:MIDIEndpointRef?) -> MIDIThruConnectionRef? {
    //
    //        var params = MIDIThruConnectionParams()
    //        MIDIThruConnectionParamsInitialize(&params)
    //        println("initial size params \(sizeofValue(params))")
    //
    //        if let se = srcEndpoint {
    //            var src = MIDIThruConnectionEndpoint(endpointRef: se, uniqueID: 0)
    //            params.sources.0 = src
    //            println("set thru src to \(src)")
    //        }
    //
    //        if let de = destEndpoint {
    //            var dest = MIDIThruConnectionEndpoint(endpointRef: de, uniqueID: 1)
    //            params.destinations.0 = dest
    //            println("set thru dest to \(dest)")
    //        }
    //
    //        var map = MIDIValueMap(value:(
    //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
    //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
    //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
    //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
    //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
    //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
    //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
    //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
    //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
    //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
    //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
    //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),
    //            UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0)
    //        ))
    //
    //
    //
    //        // transform the value using a map; param is the index of the map in the connection's array of maps.
    //        //        params.velocity = MIDITransform(transform:MIDITransformType(kMIDITransform_MapValue), param:0)
    //        //        params.numMaps = 1
    //
    //        println("size params \(sizeofValue(params))")
    //        params.noteNumber = MIDITransform(transform:MIDITransformType(kMIDITransform_Add), param:1)
    //
    //        //        var nsd = params as NSData
    //
    //        var data = encode(params)
    //        var up = UnsafePointer<UInt8>(data.bytes)
    //        //var dataRef = CFDataCreate(kCFAllocatorDefault, up, sizeof(MIDIThruConnectionParams))
    //        var ab = arrayOfBytes(params)
    //        var dataRef = CFDataCreate(kCFAllocatorDefault, ab, sizeof(MIDIThruConnectionParams))
    //
    //        var thru = MIDIThruConnectionRef()
    //        var status = MIDIThruConnectionCreate("MyThruID", dataRef, &thru)
    //        if status == OSStatus(noErr) {
    //            println("yay created thru connection!")
    //        } else {
    //            println("oh crap! thru")
    //            showError(status)
    //            return nil
    //        }
    //              return thru
    //
    //    }
    
    
    
    /**
     This will initialize the midiClient, outputPort, and inputPort variables.
     */
    
    func initMIDI(midiNotifier: MIDINotifyBlock? = nil, reader: MIDIReadBlock? = nil) {
        
        enableNetwork()
        
        var notifyBlock: MIDINotifyBlock
        
        if midiNotifier != nil {
            notifyBlock = midiNotifier!
        } else {
            notifyBlock = MyMIDINotifyBlock
        }
        
        var readBlock: MIDIReadBlock
        if reader != nil {
            readBlock = reader!
        } else {
            readBlock = MyMIDIReadBlock
        }
        
        var status = noErr
        status = MIDIClientCreateWithBlock("com.rockhoppertech.MyMIDIClient", &midiClient, notifyBlock)
        
        if status == noErr {
            print("created client")
        } else {
            print("error creating client : \(status)")
            CheckError(status)
        }
        
        
        if status == noErr {
            
            status = MIDIInputPortCreateWithBlock(midiClient, "com.rockhoppertech.MIDIInputPort", &inputPort, readBlock)
            if status == noErr {
                print("created input port")
            } else {
                print("error creating input port : \(status)")
                CheckError(status)
            }
            
            
            status = MIDIOutputPortCreate(midiClient,
                                          "com.rockhoppertech.OutputPort",
                                          &outputPort)
            if status == noErr {
                print("created output port \(outputPort)")
            } else {
                print("error creating output port : \(status)")
                CheckError(status)
            }
            
            //  createThru(inputPort, dest: outputPort)
            
            // this is the sequence's destination
            status = MIDIDestinationCreateWithBlock(midiClient,
                                                    "com.rockhoppertech.VirtualDest",
                                                    &destEndpointRef,
                                                    readBlock)
            
            if status != noErr {
                print("error creating virtual destination: \(status)")
                CheckError(status)
            } else {
                print("midi virtual destination created \(destEndpointRef)")
            }
            
            
            connectSourcesToInputPort()
            
            // createThru(inputPort, dest: destEndpointRef)
            let thruConnection = createThru(source: destEndpointRef, dest: destEndpointRef)
            print("\(thruConnection)")
            
            //            createThru(inputPort, dest: outputPort)
            
            //            createThru(inputPort, dest: destEndpointRef)
            
            
            //            let destCount = MIDIGetNumberOfDestinations()
            //            for i in 0 ..< destCount {
            //                var thru = createThru(inputPort, dest: MIDIGetDestination(i))
            //                print("created thru \(thru)" )
            //            }
            
            
            initGraph()
            
            playWithMusicPlayer()
            
        }
        
    }
    
    
    func initGraph() {
        augraphSetup()
        graphStart()
        // after the graph starts
        loadSF2Preset(0)
        CAShow(UnsafeMutablePointer<MusicSequence>(self.processingGraph!))
    }
    
    
    // swift 2
    // typealias MIDIReadBlock = (UnsafePointer<MIDIPacketList>, UnsafeMutablePointer<Void>) -> Void
    // swift 3
    // typealias MIDIReadBlock = (UnsafePointer<MIDIPacketList>, UnsafeMutablePointer<Swift.Void>?) -> Swift.Void

    
    func MyMIDIReadBlock(packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutablePointer<Swift.Void>?) -> Swift.Void {
        
        //debugPrint("MyMIDIReadBlock \(packetList)")
        
        
        let packets = packetList.pointee
        
        let packet:MIDIPacket = packets.packet
        
        // don't do this
        //        print("packet \(packet)")
        
        var ap = UnsafeMutablePointer<MIDIPacket>.init(allocatingCapacity: 1)
        ap.initialize(with:packet)
        
        for _ in 0 ..< packets.numPackets {
            
            let p = ap.pointee
            print("timestamp \(p.timeStamp)", terminator: "")
            var hex = String(format:"0x%X", p.data.0)
            print(" \(hex)", terminator: "")
            hex = String(format:"0x%X", p.data.1)
            print(" \(hex)", terminator: "")
            hex = String(format:"0x%X", p.data.2)
            print(" \(hex)")
            
            handle(p)
            
            ap = MIDIPacketNext(ap)
            
        }
        
    }
    
    func handle(_ packet:MIDIPacket) {
        
        let status = packet.data.0
        let d1 = packet.data.1
        let d2 = packet.data.2
        let rawStatus = status & 0xF0 // without channel
        let channel = status & 0x0F
        
        switch rawStatus {
            
        case 0x80:
            print("Note off. Channel \(channel) note \(d1) velocity \(d2)")
            // forward to sampler
            playNoteOff(UInt32(channel), noteNum: UInt32(d1))
            
        case 0x90:
            print("Note on. Channel \(channel) note \(d1) velocity \(d2)")
            // forward to sampler
            playNoteOn(UInt32(channel), noteNum:UInt32(d1), velocity: UInt32(d2))
            
        case 0xA0:
            print("Polyphonic Key Pressure (Aftertouch). Channel \(channel) note \(d1) pressure \(d2)")
            
        case 0xB0:
            print("Control Change. Channel \(channel) controller \(d1) value \(d2)")
            
        case 0xC0:
            print("Program Change. Channel \(channel) program \(d1)")
            
        case 0xD0:
            print("Channel Pressure (Aftertouch). Channel \(channel) pressure \(d1)")
            
        case 0xE0:
            print("Pitch Bend Change. Channel \(channel) lsb \(d1) msb \(d2)")
            
        default: print("Unhandled message \(status)")
        }
    }
    
    
    func showMIDIObjectType(_ ot: MIDIObjectType) {
        switch ot {
        case .other:
            print("midiObjectType: Other")
            break
        case .device:
            print("midiObjectType: Device")
            break
        case .entity:
            print("midiObjectType: Entity")
            break
        case .source:
            print("midiObjectType: Source")
            break
        case .destination:
            print("midiObjectType: Destination")
            break
        case .externalDevice:
            print("midiObjectType: ExternalDevice")
            break
        case .externalEntity:
            print("midiObjectType: ExternalEntity")
            break
        case .externalSource:
            print("midiObjectType: ExternalSource")
            break
        case .externalDestination:
            print("midiObjectType: ExternalDestination")
            break
        }
        
    }
    
    //typealias MIDINotifyBlock = (UnsafePointer<MIDINotification>) -> Void
    func MyMIDINotifyBlock(midiNotification: UnsafePointer<MIDINotification>) {
        print("\ngot a MIDINotification!")
        
        let notification = midiNotification.pointee
        print("MIDI Notify, messageId= \(notification.messageID)")
        print("MIDI Notify, messageSize= \(notification.messageSize)")
        
        switch notification.messageID {
        
        // Some aspect of the current MIDISetup has changed.  No data.  Should ignore this  message if messages 2-6 are handled.
        case .msgSetupChanged:
            print("MIDI setup changed")
            let ptr = UnsafeMutablePointer<MIDINotification>(midiNotification)
            let m = ptr.pointee
            print(m)
            print("id \(m.messageID)")
            print("size \(m.messageSize)")
                       break
            
            
        // A device, entity or endpoint was added. Structure is MIDIObjectAddRemoveNotification.
        case .msgObjectAdded:
            
            print("added")
            let ptr = UnsafeMutablePointer<MIDIObjectAddRemoveNotification>(midiNotification)
            let m = ptr.pointee
            print(m)
            print("id \(m.messageID)")
            print("size \(m.messageSize)")
            print("child \(m.child)")
            print("child type \(m.childType)")
            showMIDIObjectType(m.childType)
            print("parent \(m.parent)")
            print("parentType \(m.parentType)")
            showMIDIObjectType(m.parentType)

            break
            
        // A device, entity or endpoint was removed. Structure is MIDIObjectAddRemoveNotification.
        case .msgObjectRemoved:
            print("kMIDIMsgObjectRemoved")
            let ptr = UnsafeMutablePointer<MIDIObjectAddRemoveNotification>(midiNotification)
            let m = ptr.pointee
            print(m)
            print("id \(m.messageID)")
            print("size \(m.messageSize)")
            print("child \(m.child)")
            print("child type \(m.childType)")
            print("parent \(m.parent)")
            print("parentType \(m.parentType)")

            break
            
        // An object's property was changed. Structure is MIDIObjectPropertyChangeNotification.
        case .msgPropertyChanged:
            print("kMIDIMsgPropertyChanged")
            
            let ptr = UnsafeMutablePointer<MIDIObjectPropertyChangeNotification>(midiNotification)
            let m = ptr.pointee
            print(m)
            print("id \(m.messageID)")
            print("size \(m.messageSize)")
            print("object \(m.object)")
            print("objectType  \(m.objectType)")
            print("propertyName  \(m.propertyName)")
            print("propertyName  \(m.propertyName.takeUnretainedValue())")
            
            if m.propertyName.takeUnretainedValue() == "apple.midirtp.session" {
                print("connected")
            }
            
            break
            
        // 	A persistent MIDI Thru connection wasor destroyed.  No data.
        case .msgThruConnectionsChanged:
            print("MIDI thru connections changed.")
            break
            
        //A persistent MIDI Thru connection was created or destroyed.  No data.
        case .msgSerialPortOwnerChanged:
            print("MIDI serial port owner changed.")
            break
            
        case .msgIOError:
            print("MIDI I/O error.")
            
            let ptr = UnsafeMutablePointer<MIDIIOErrorNotification>(midiNotification)
            let m = ptr.pointee
            print(m)
            print("id \(m.messageID)")
            print("size \(m.messageSize)")
            print("driverDevice \(m.driverDevice)")
            print("errorCode \(m.errorCode)")
            
            break
        }
        
    }
    
    
    func showError(status:OSStatus) {
        
        switch status {
            
        case OSStatus(kMIDIInvalidClient):
            print("invalid client")
            break
        case OSStatus(kMIDIInvalidPort):
            print("invalid port")
            break
        case OSStatus(kMIDIWrongEndpointType):
            print("invalid endpoint type")
            break
        case OSStatus(kMIDINoConnection):
            print("no connection")
            break
        case OSStatus(kMIDIUnknownEndpoint):
            print("unknown endpoint")
            break
            
        case OSStatus(kMIDIUnknownProperty):
            print("unknown property")
            break
        case OSStatus(kMIDIWrongPropertyType):
            print("wrong property type")
            break
        case OSStatus(kMIDINoCurrentSetup):
            print("no current setup")
            break
        case OSStatus(kMIDIMessageSendErr):
            print("message send")
            break
        case OSStatus(kMIDIServerStartErr):
            print("server start")
            break
        case OSStatus(kMIDISetupFormatErr):
            print("setup format")
            break
        case OSStatus(kMIDIWrongThread):
            print("wrong thread")
            break
        case OSStatus(kMIDIObjectNotFound):
            print("object not found")
            break
            
        case OSStatus(kMIDIIDNotUnique):
            print("not unique")
            break
            
        case OSStatus(kMIDINotPermitted):
            print("not permitted")
            break
            
        default:
            print("dunno \(status)")
        }
    }
    
    
    func enableNetwork() {
        let session = MIDINetworkSession.default()
        session.isEnabled = true
        session.connectionPolicy = .anyone
        print("net session enabled \(MIDINetworkSession.default().isEnabled)")
    }
    
    func connectSourcesToInputPort() {
        let sourceCount = MIDIGetNumberOfSources()
        print("source count \(sourceCount)")
        
        for srcIndex in 0 ..< sourceCount {
            let midiEndPoint = MIDIGetSource(srcIndex)
            //            createThru(inputPort, dest: midiEndPoint)
            //
            //                        status = MIDIPortConnectSource(inputPort,
            //                            self.midiThru,
            //                            nil)
            
            let status = MIDIPortConnectSource(inputPort,
                                               midiEndPoint,
                                               nil)
            CheckError(status)
            if status == noErr {
                print("yay connected endpoint to inputPort!")
            } else {
                print("oh crap!")
            }
        }
    }
    
    //     func playSequence() {
    //        var sequence = MIDISequence()
    //        if let track2 = MIDITrack.trackFromString("c d e f g a b")?.transposeTrack(48) {
    //            track2.patch = .Vibes
    //            debugPrintln(track2)
    //            sequence.addTrack(track2)
    //        }
    //
    //        var destCount = MIDIGetNumberOfDestinations()
    //        for i in 0 ..< destCount {
    //            var endpoint = MIDIGetDestination(i)
    //
    //            //            if let thru = setupMIDIThru(nil, destEndpoint: endpoint) {
    //            //                sequence.play(thru)
    //            //            }
    //
    //            println("playing sequence on \(endpoint)")
    //            sequence.play(endpoint)
    //
    //            println("properties for destination \(i)")
    //            showProperties(endpoint)
    //
    //            //            var status = MIDISend(outputPort!, endpoint, packetList)
    //
    //        }
    //
    //
    //
    //
    //
    //    }
    
    func playWithMusicPlayer() {
        let sequence = createMusicSequence()
        self.musicPlayer = createMusicPlayer(sequence)
        playMusicPlayer()
    }
    
    func createMusicPlayer(_ musicSequence:MusicSequence) -> MusicPlayer {
        var musicPlayer: MusicPlayer?
        var status = noErr
        
        status = NewMusicPlayer(&musicPlayer)
        if status != noErr {
            print("bad status \(status) creating player")
        }
        
        status = MusicPlayerSetSequence(musicPlayer!, musicSequence)
        if status != noErr {
            print("setting sequence \(status)")
        }
        
        status = MusicPlayerPreroll(musicPlayer!)
        if status != noErr {
            print("prerolling player \(status)")
        }
        
        //        status = MusicSequenceSetMIDIEndpoint(musicSequence, self.destEndpointRef)
        status = MusicSequenceSetMIDIEndpoint(musicSequence, self.midiThru)
        
        if status != noErr {
            print("error setting sequence endpoint \(status)")
        }
        
        return musicPlayer!
    }
    
    func playMusicPlayer() {
        var status = noErr
        var playing = DarwinBoolean(false)
        
        if let player = self.musicPlayer {
            status = MusicPlayerIsPlaying(player, &playing)
            if playing != false {
                print("music player is playing. stopping")
                status = MusicPlayerStop(player)
                if status != noErr {
                    print("Error stopping \(status)")
                    return
                }
            } else {
                print("music player is not playing.")
            }
            
            status = MusicPlayerSetTime(player, 0)
            if status != noErr {
                print("setting time \(status)")
                return
            }
            
            status = MusicPlayerStart(player)
            if status != noErr {
                print("Error starting \(status)")
                return
            }
        }
    }
    
    
    func createMusicSequence() -> MusicSequence {
        
        var musicSequence:MusicSequence?
        var status = NewMusicSequence(&musicSequence)
        if status != noErr {
            print("\(#line) bad status \(status) creating sequence")
            CheckError(status)
        }
        
        // add a track
        var track: MusicTrack?
        status = MusicSequenceNewTrack(musicSequence!, &track)
        if status != noErr {
            print("error creating track \(status)")
            CheckError(status)
        }
        
        // bank select msb
        var chanmess = MIDIChannelMessage(status: 0xB0, data1: 0, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track!, 0, &chanmess)
        if status != noErr {
            print("creating bank select event \(status)")
            CheckError(status)
        }
        // bank select lsb
        chanmess = MIDIChannelMessage(status: 0xB0, data1: 32, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track!, 0, &chanmess)
        if status != noErr {
            print("creating bank select event \(status)")
            CheckError(status)
        }
        
        // program change. first data byte is the patch, the second data byte is unused for program change messages.
        chanmess = MIDIChannelMessage(status: 0xC0, data1: 0, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track!, 0, &chanmess)
        if status != noErr {
            print("creating program change event \(status)")
            CheckError(status)
        }
        
        // now make some notes and put them on the track
        var beat = MusicTimeStamp(0.0)
        for i:UInt8 in 60...72 {
            var mess = MIDINoteMessage(channel: 0,
                                       note: i,
                                       velocity: 64,
                                       releaseVelocity: 0,
                                       duration: 1.0 )
            status = MusicTrackNewMIDINoteEvent(track!, beat, &mess)
            if status != noErr {
                print("creating new midi note event \(status)")
                CheckError(status)
            }
            beat += 1
        }
        
        // associate the AUGraph with the sequence.
        status = MusicSequenceSetAUGraph(musicSequence!, self.processingGraph)
        CheckError(status)
        
        status = MusicSequenceSetMIDIEndpoint(musicSequence!, self.midiThru)
        CheckError(status)
        
        // Let's see it
        CAShow(UnsafeMutablePointer<MusicSequence>(musicSequence!))
        
        return musicSequence!
    }
    
    func augraphSetup() {

        var status = NewAUGraph(&self.processingGraph)
        CheckError(status)
        
        // create the sampler
        
        //https://developer.apple.com/library/prerelease/ios/documentation/AudioUnit/Reference/AudioComponentServicesReference/index.html#//apple_ref/swift/struct/AudioComponentDescription
        
        var samplerNode = AUNode()
        var cd = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_MusicDevice),
            componentSubType: OSType(kAudioUnitSubType_Sampler),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0,
            componentFlagsMask: 0)
        status = AUGraphAddNode(self.processingGraph!, &cd, &samplerNode)
        CheckError(status)
        
        // create the ionode
        var ioNode = AUNode()
        var ioUnitDescription = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_Output),
            componentSubType: OSType(kAudioUnitSubType_RemoteIO),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0,
            componentFlagsMask: 0)
        status = AUGraphAddNode(self.processingGraph!, &ioUnitDescription, &ioNode)
        CheckError(status)
        
        // now do the wiring. The graph needs to be open before you call AUGraphNodeInfo
        status = AUGraphOpen(self.processingGraph!)
        CheckError(status)
        
        status = AUGraphNodeInfo(self.processingGraph!, samplerNode, nil, &self.samplerUnit)
        CheckError(status)
        
        var ioUnit: AudioUnit? = nil
        status = AUGraphNodeInfo(self.processingGraph!, ioNode, nil, &ioUnit)
        CheckError(status)
        
        let ioUnitOutputElement = AudioUnitElement(0)
        let samplerOutputElement = AudioUnitElement(0)
        status = AUGraphConnectNodeInput(self.processingGraph!,
                                         samplerNode, samplerOutputElement, // srcnode, inSourceOutputNumber
            ioNode, ioUnitOutputElement) // destnode, inDestInputNumber
        CheckError(status)
    }
    
    
    func graphStart() {
        //https://developer.apple.com/library/prerelease/ios/documentation/AudioToolbox/Reference/AUGraphServicesReference/index.html#//apple_ref/c/func/AUGraphIsInitialized
        
        var status = noErr
        var outIsInitialized:DarwinBoolean = false
        status = AUGraphIsInitialized(self.processingGraph!, &outIsInitialized)
        print("isinit status is \(status)")
        print("bool is \(outIsInitialized)")
        if outIsInitialized == false {
            status = AUGraphInitialize(self.processingGraph!)
            CheckError(status)
        }
        
        var isRunning = DarwinBoolean(false)
        AUGraphIsRunning(self.processingGraph!, &isRunning)
        print("running bool is \(isRunning)")
        if isRunning == false {
            status = AUGraphStart(self.processingGraph!)
            CheckError(status)
        }
        
    }
    
    func playNoteOn(_ channel:UInt32, noteNum:UInt32, velocity:UInt32)    {
        let noteCommand = UInt32(0x90 | channel)
        let status = MusicDeviceMIDIEvent(self.samplerUnit!, noteCommand, noteNum, velocity, 0)
        CheckError(status)
    }
    
    func playNoteOff(_ channel:UInt32, noteNum:UInt32)    {
        let noteCommand = UInt32(0x80 | channel)
        let status = MusicDeviceMIDIEvent(self.samplerUnit!, noteCommand, noteNum, 0, 0)
        CheckError(status)
    }
    
    
    /// loads preset into self.samplerUnit
    func loadSF2Preset(_ preset:UInt8)  {
        
        // This is the MuseCore soundfont. Change it to the one you have.
        if let bankURL = Bundle.main().urlForResource("GeneralUser GS MuseScore v1.442", withExtension: "sf2") {
            var instdata = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(bankURL),
                                                   instrumentType: UInt8(kInstrumentType_DLSPreset),
                                                   bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                                   bankLSB: UInt8(kAUSampler_DefaultBankLSB),
                                                   presetID: preset)
            
            
            let status = AudioUnitSetProperty(
                self.samplerUnit!,
                AudioUnitPropertyID(kAUSamplerProperty_LoadInstrument),
                AudioUnitScope(kAudioUnitScope_Global),
                0,
                &instdata,
                UInt32(sizeof(AUSamplerInstrumentData)))
            CheckError(status)
        }
    }
    
    
    
    /**
     Not as detailed as Adamson's CheckError, but adequate.
     For other projects you can uncomment the Core MIDI constants.
     */
    func CheckError(_ error:OSStatus) {
        if error == noErr {return}
        
        switch(error) {
        case kMIDIInvalidClient :
            print( "kMIDIInvalidClient ")
            
        case kMIDIInvalidPort :
            print( "kMIDIInvalidPort ")
            
        case kMIDIWrongEndpointType :
            print( "kMIDIWrongEndpointType")
            
        case kMIDINoConnection :
            print( "kMIDINoConnection ")
            
        case kMIDIUnknownEndpoint :
            print( "kMIDIUnknownEndpoint ")
            
        case kMIDIUnknownProperty :
            print( "kMIDIUnknownProperty ")
            
        case kMIDIWrongPropertyType :
            print( "kMIDIWrongPropertyType ")
            
        case kMIDINoCurrentSetup :
            print( "kMIDINoCurrentSetup ")
            
        case kMIDIMessageSendErr :
            print( "kMIDIMessageSendErr ")
            
        case kMIDIServerStartErr :
            print( "kMIDIServerStartErr ")
            
        case kMIDISetupFormatErr :
            print( "kMIDISetupFormatErr ")
            
        case kMIDIWrongThread :
            print( "kMIDIWrongThread ")
            
        case kMIDIObjectNotFound :
            print( "kMIDIObjectNotFound ")
            
        case kMIDIIDNotUnique :
            print( "kMIDIIDNotUnique ")
            
        default: print( "huh? \(error) ")
        }
        
        
        switch(error) {
        //AUGraph.h
        case kAUGraphErr_NodeNotFound:
            print("Error:kAUGraphErr_NodeNotFound \n")
            
        case kAUGraphErr_OutputNodeErr:
            print( "Error:kAUGraphErr_OutputNodeErr \n")
            
        case kAUGraphErr_InvalidConnection:
            print("Error:kAUGraphErr_InvalidConnection \n")
            
        case kAUGraphErr_CannotDoInCurrentContext:
            print( "Error:kAUGraphErr_CannotDoInCurrentContext \n")
            
        case kAUGraphErr_InvalidAudioUnit:
            print( "Error:kAUGraphErr_InvalidAudioUnit \n")
            
            // core audio
            
        case kAudio_UnimplementedError:
            print("kAudio_UnimplementedError")
        case kAudio_FileNotFoundError:
            print("kAudio_FileNotFoundError")
        case kAudio_FilePermissionError:
            print("kAudio_FilePermissionError")
        case kAudio_TooManyFilesOpenError:
            print("kAudio_TooManyFilesOpenError")
        case kAudio_BadFilePathError:
            print("kAudio_BadFilePathError")
        case kAudio_ParamError:
            print("kAudio_ParamError")
        case kAudio_MemFullError:
            print("kAudio_MemFullError")
            
            
            // AudioToolbox
            
        case kAudioToolboxErr_InvalidSequenceType :
            print( " kAudioToolboxErr_InvalidSequenceType ")
            
        case kAudioToolboxErr_TrackIndexError :
            print( " kAudioToolboxErr_TrackIndexError ")
            
        case kAudioToolboxErr_TrackNotFound :
            print( " kAudioToolboxErr_TrackNotFound ")
            
        case kAudioToolboxErr_EndOfTrack :
            print( " kAudioToolboxErr_EndOfTrack ")
            
        case kAudioToolboxErr_StartOfTrack :
            print( " kAudioToolboxErr_StartOfTrack ")
            
        case kAudioToolboxErr_IllegalTrackDestination :
            print( " kAudioToolboxErr_IllegalTrackDestination")
            
        case kAudioToolboxErr_NoSequence :
            print( " kAudioToolboxErr_NoSequence ")
            
        case kAudioToolboxErr_InvalidEventType :
            print( " kAudioToolboxErr_InvalidEventType")
            
        case kAudioToolboxErr_InvalidPlayerState :
            print( " kAudioToolboxErr_InvalidPlayerState")
            
            // AudioUnit
            
            
        case kAudioUnitErr_InvalidProperty :
            print( " kAudioUnitErr_InvalidProperty")
            
        case kAudioUnitErr_InvalidParameter :
            print( " kAudioUnitErr_InvalidParameter")
            
        case kAudioUnitErr_InvalidElement :
            print( " kAudioUnitErr_InvalidElement")
            
        case kAudioUnitErr_NoConnection :
            print( " kAudioUnitErr_NoConnection")
            
        case kAudioUnitErr_FailedInitialization :
            print( " kAudioUnitErr_FailedInitialization")
            
        case kAudioUnitErr_TooManyFramesToProcess :
            print( " kAudioUnitErr_TooManyFramesToProcess")
            
        case kAudioUnitErr_InvalidFile :
            print( " kAudioUnitErr_InvalidFile")
            
        case kAudioUnitErr_FormatNotSupported :
            print( " kAudioUnitErr_FormatNotSupported")
            
        case kAudioUnitErr_Uninitialized :
            print( " kAudioUnitErr_Uninitialized")
            
        case kAudioUnitErr_InvalidScope :
            print( " kAudioUnitErr_InvalidScope")
            
        case kAudioUnitErr_PropertyNotWritable :
            print( " kAudioUnitErr_PropertyNotWritable")
            
        case kAudioUnitErr_InvalidPropertyValue :
            print( " kAudioUnitErr_InvalidPropertyValue")
            
        case kAudioUnitErr_PropertyNotInUse :
            print( " kAudioUnitErr_PropertyNotInUse")
            
        case kAudioUnitErr_Initialized :
            print( " kAudioUnitErr_Initialized")
            
        case kAudioUnitErr_InvalidOfflineRender :
            print( " kAudioUnitErr_InvalidOfflineRender")
            
        case kAudioUnitErr_Unauthorized :
            print( " kAudioUnitErr_Unauthorized")
            
        default:
            print("huh?")
        }
    }
}



