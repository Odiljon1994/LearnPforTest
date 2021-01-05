//
//  ViewController.swift
//  LearnPforTest
//
//  Created by centerprime on 01/05/2021.
//  Copyright (c) 2021 centerprime. All rights reserved.
//

import UIKit
import LearnPforTest
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let log = LearnPforTesting()
        print(log.calculate(a: 2))
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

