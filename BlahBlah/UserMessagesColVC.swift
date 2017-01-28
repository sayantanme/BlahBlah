//
//  UserMessagesColVC.swift
//  BlahBlah
//
//  Created by Sayantan Chakraborty on 29/01/17.
//  Copyright © 2017 Sayantan Chakraborty. All rights reserved.
//

import UIKit

class UserMessagesColVC: UICollectionViewCell {
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.textAlignment = NSTextAlignment.right
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(textView)
        //constraints x,y,w,h
        textView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
