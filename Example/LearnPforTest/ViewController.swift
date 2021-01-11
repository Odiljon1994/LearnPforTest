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
        // Do any additional setup after loading the view, typically from a nib.
      //  print(EthWalletManager().createWallet(password: "12"))
      
        let etWalletManager = EthWalletManager()
        etWalletManager.addInfura(infura: "https://ropsten.infura.io/v3/a396c3461ac048a59f389c7778f06689")
//        print(etWalletManager.createWallet(password: "121212"))
        print(etWalletManager.checkBalance(walletAddress: "0xe7Ec23EF461c06D446CFfcAe5262Cf20C05295ec"))
        
     //   print(etWalletManager.checkBalance(walletAddress: "0xEaAFe714c9fA5a99e0c8fD9173585482d8Bdb799"))
      //  print(etWalletManager.checkERC20Balance(walletAddress: "0xEaAFe714c9fA5a99e0c8fD9173585482d8Bdb799", contractAddress: "0x68906c10c3917aa796c438ce49df8e084efae749"))
//        print(etWalletManager.sentERC20Token(senderAddress: "0xEaAFe714c9fA5a99e0c8fD9173585482d8Bdb799", password: "121212", contractAddress: "0x68906c10c3917aa796c438ce49df8e084efae749", tokenAmount: "1", receiverAddress: "0xc924a392619625e3c39148E0F9D86C3DB87caFEC", gasLimit: "50000"))
//        print(etWalletManager.sentEthereum(senderAddress: "0xEaAFe714c9fA5a99e0c8fD9173585482d8Bdb799", password: "121212", receiverAddress: "0xc924a392619625e3c39148E0F9D86C3DB87caFEC", amount: "0.09", gasLimit: "21000"))
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

