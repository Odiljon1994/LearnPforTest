//
//  LearnPforTest.swift
//  LearnPforTest
//
//  Created by Ergashev Odiljon on 2021/01/05.
//

import Foundation
import web3swift
public class EthWalletManager {
    public init() {
        
    }
    public func createWallet(password: String) -> String {
        
        guard let userDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
            let keystoreManager = KeystoreManager.managerForPath(userDirectory + "/keystore")
        else {
            fatalError("Couldn't create a KeystoreManager.")
        }
        
        let keystore = try? EthereumKeystoreV3(password: password)
        let newKeystoreJSON = try? JSONEncoder().encode(keystore!.keystoreParams)
        let backToString = String(data: newKeystoreJSON!, encoding: String.Encoding.utf8) as String? ?? ""
        let addrs = keystore?.addresses!.first!.address
        print("Address: " + addrs!)
        guard let address = EthereumAddress((keystore?.getAddress()!.address)!) else { return "" }
        let privateKey = try! keystore?.UNSAFE_getPrivateKeyData(password: password, account: address).toHexString()
        print(backToString)
       
        print("Your private key: " + privateKey!)
        
       // let data = Data(backToString.utf8)
        FileManager.default.createFile(atPath: "\(keystoreManager.path)/keystore.json", contents: newKeystoreJSON, attributes: nil)
        
        return (keystore?.getAddress()!.address)!
    }
    
    public func getKeyStore() -> EthereumKeystoreV3 {
        //First you need a `KeystoreManager` instance:
        guard let userDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
            let keystoreManager = KeystoreManager.managerForPath(userDirectory + "/keystore")
        else {
            fatalError("Couldn't create a KeystoreManager.")
        }
        
        if let address = keystoreManager.addresses?.first,
        let retrievedKeystore = keystoreManager.walletForAddress(address) as? EthereumKeystoreV3 {
            let newKeystoreJSON = try? JSONEncoder().encode(retrievedKeystore.keystoreParams)
            let backToString = String(data: newKeystoreJSON!, encoding: String.Encoding.utf8) as String? ?? ""
       
            return retrievedKeystore
        }
        let keystore = try? EthereumKeystoreV3(password: "password")
        return keystore!
    }
    
    public func importByKeystore(keystore: String) -> String {
        
        guard let userDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
            let keystoreManager = KeystoreManager.managerForPath(userDirectory + "/keystore")
        else {
            fatalError("Couldn't create a KeystoreManager.")
        }
       
        let keyStore = EthereumKeystoreV3.init(keystore)
        
        let newKeystoreJSON = try? JSONEncoder().encode(keyStore!.keystoreParams)
        FileManager.default.createFile(atPath: "\(keystoreManager.path)/keystore.json", contents: newKeystoreJSON, attributes: nil)
        
        
        return (keyStore?.getAddress()!.address)!
    }
    
    public func exportPrivateKey(walletAddress: String, password: String) -> String {
        let keystore = getKeyStore() as EthereumKeystoreV3
        
        if keystore.getAddress()?.address == walletAddress {
            let address = EthereumAddress(keystore.getAddress()!.address)
            
            let privateKey = try! keystore.UNSAFE_getPrivateKeyData(password: password, account: address!).toHexString()
            return privateKey
            
        } else {
            return "Provided wrong wallet address"
        }
    }
    
    public func exportKeystore(walletAddress: String) -> String {
        let keystore = getKeyStore() as EthereumKeystoreV3
        if keystore.getAddress()?.address == walletAddress {
            let newKeystoreJSON = try? JSONEncoder().encode(keystore.keystoreParams)
            let backToString = String(data: newKeystoreJSON!, encoding: String.Encoding.utf8) as String? ?? ""
            return backToString
        }
        return ""
    }
    
    public func sentEthereum(senderAddress: String, password: String, receiverAddress: String, amount: String, gasPrice: String) -> String {
        
        let privateKey = "5841f01519a61e703d366dae942f9a4bfc42a5acc9c38f4652e577d5eeed8173"
        let passKey = password

        let endpoint = "https://ropsten.infura.io/v3/a396c3461ac048a59f389c7778f06689"
        let infura = web3(provider: Web3HttpProvider(URL(string: endpoint)!)!)
        
        do{
            let formattedKey = privateKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let dataKey = Data.fromHex(formattedKey)!
                
            // @@@ use [passKey]
            let keystore = try EthereumKeystoreV3(privateKey: dataKey, password: passKey/*""*/)!
            
            let keyStore = getKeyStore() as EthereumKeystoreV3
                
//            let keyData = try JSONEncoder().encode(keystore.keystoreParams)
//            let address = keystore.addresses!.first!.address
            //  let wallet = Wallet(address: address, data: keyData, name: "", isHD: false)
            //  print(wallet.address)
                
            // @@@ attach [keystore] to the manager
         //   infura.addKeystoreManager( KeystoreManager( [keystore] ) )
            infura.addKeystoreManager( KeystoreManager( [keyStore] ) )
                
        }catch{
            print("Something wrong")
        }
  
        let value: String = amount // In Ether
        let walletAddress = EthereumAddress(senderAddress)! // Your wallet address
        let toAdres = EthereumAddress(receiverAddress)!

        let contract = infura.contract(Web3.Utils.coldWalletABI, at: toAdres, abiVersion: 2)!

        let amount = Web3.Utils.parseToBigUInt(value, units: .eth)
        var options = TransactionOptions.defaultOptions
        options.value = amount
        options.from = walletAddress
        options.gasPrice = .automatic
        options.gasLimit = .automatic

        let tx = contract.write("fallback"/*"transfer"*/, parameters: [AnyObject](), extraData: Data(), transactionOptions: options)

        do {
            // @@@ write transaction requires password, because it consumes gas
            let transaction = try tx?.send( password: passKey )

            print("output", transaction?.transaction.description as Any)
            return transaction!.hash
                    
        } catch(let err) {
            print("err", err)
        }

        return ""
    }
    
    public func sentERC20Token(senderAddress: String, password: String, contractAddress: String, tokenAmount: String, receiverAddress: String, gasPrice: String) -> String {

        let endpoint = "https://ropsten.infura.io/v3/a396c3461ac048a59f389c7778f06689"
        let infura = web3(provider: Web3HttpProvider(URL(string: endpoint)!)!)
        
        do{
            let keyStore = getKeyStore() as EthereumKeystoreV3
                        
            infura.addKeystoreManager( KeystoreManager( [keyStore] ) )
                
        }catch{
            print("Something wrong")
        }
        
        let value: String = tokenAmount // In Tokens

        let walletAddress = EthereumAddress(senderAddress)! // Your wallet address
        let toAddress = EthereumAddress(receiverAddress)!
        let erc20ContractAddress = EthereumAddress(contractAddress)!
        let contract = infura.contract(Web3.Utils.erc20ABI, at: erc20ContractAddress, abiVersion: 2)!
        let amount = Web3.Utils.parseToBigUInt(value, units: .eth)
        var options = TransactionOptions.defaultOptions
        options.from = walletAddress
        options.gasPrice = .automatic
        options.gasLimit = .automatic
        let method = "transfer"
        let tx = contract.write( method, parameters: [toAddress, amount] as [AnyObject], extraData: Data(), transactionOptions: options)!
        do {
            
            let transaction = try tx.send( password: password )

            print("output", transaction.transaction.description as Any)
            return transaction.hash
                    
        } catch(let err) {
            print("err", err)
        }

        return ""
    }
    
    public func importByPrivateKey(privateKey: String ) -> String {
        
        do{
            guard let userDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
                let keystoreManager = KeystoreManager.managerForPath(userDirectory + "/keystore")
            else {
                fatalError("Couldn't create a KeystoreManager.")
            }
            
            let formattedKey = privateKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let dataKey = Data.fromHex(formattedKey)!
                
            let keystore = try EthereumKeystoreV3(privateKey: dataKey)!
            
            let newKeystoreJSON = try? JSONEncoder().encode(keystore.keystoreParams)
            FileManager.default.createFile(atPath: "\(keystoreManager.path)/keystore.json", contents: newKeystoreJSON, attributes: nil)
            
            return keystore.getAddress()!.address
                
            }catch{
                print("Something wrong")
            }
        return "Please enter valid private key"
    }
    
    public func checkBalance(walletAddress: String) -> String {
        
        let endpoint = "https://ropsten.infura.io/v3/a396c3461ac048a59f389c7778f06689"
        let infura = web3(provider: Web3HttpProvider(URL(string: endpoint)!)!)
        let address = EthereumAddress(walletAddress)!
        let balance = try? infura.eth.getBalance(address: address)
        let convertToString = Web3.Utils.formatToEthereumUnits(balance!, toUnits: .eth, decimals: 3)
        
        return convertToString!
    }

    public func checkERC20Balance(walletAddress: String, contractAddress: String) -> String {
        
        let web3 = Web3.InfuraRopstenWeb3()
        let token = ERC20(web3: web3, provider: Web3.InfuraRopstenWeb3().provider, address: EthereumAddress(contractAddress)!)
        token.readProperties()
        print(token.decimals)
        print(token.symbol)
        print(token.name)
        let balance = try? token.getBalance(account: EthereumAddress(walletAddress)!)
        let convertToString = Web3.Utils.formatToEthereumUnits(balance!, toUnits: .eth, decimals: 3)
        print(convertToString)
      
        return (convertToString! + " " + token.symbol)
        
    }
}
