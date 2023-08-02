//
//  PublicSwiftView.swift
//  StaticLibrary
//
//  Created by Fan Li Lin on 2023/8/2.
//

import Foundation
import SnapKit

public class PublicSwiftView: UIView {

    let sharedLabel = UILabel()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(sharedLabel)
        
        sharedLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        print("PublicSwiftView")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
