//
//  Messages.swift
//  BlahBlah
//
//  Created by Sayantan Chakraborty on 27/01/17.
//  Copyright © 2017 Sayantan Chakraborty. All rights reserved.
//

import Foundation
import FirebaseAuth

class Messages: NSObject{
    var SenderFrom: String?
    var SenderTo : String?
    var Text : String?
    var TimeStamp: Int?
    var ImageUrl: String?
    var MessageType: String?
    
    func chatPartnerId() -> String? {
        return SenderFrom == FIRAuth.auth()?.currentUser?.uid ? SenderTo : SenderFrom
    }
}
