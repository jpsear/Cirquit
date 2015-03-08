//
//  FirebaseFactory.swift
//  AVFoundation Recorder
//
//  Created by Jon Lord on 01/03/2015.
//  Copyright (c) 2015 Gene De Lisa. All rights reserved.
//

import Foundation

var myRootRef = Firebase(url:"https://glowing-torch-5061.firebaseio.com")



func saveData() {
    
    myRootRef.runTransactionBlock({
        (currentData:FMutableData!) in
        var value = currentData.value as? Int
        if (value == nil) {
            value = 0
        }
        currentData.value = value! + 1
        return FTransactionResult.successWithValue(currentData)
    })
    
}


func retrieveData() {
    
    // Attach a closure to read the data at our posts reference
    myRootRef.observeEventType(.Value,
        withBlock: {
            snapshot in
            println(snapshot.value)
        },
        withCancelBlock: {
            error in
            println(error.description)
    })

}