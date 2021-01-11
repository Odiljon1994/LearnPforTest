//
//  LearnPforTest.swift
//  LearnPforTest
//
//  Created by Ergashev Odiljon on 2021/01/05.
//

import Foundation
import web3swift
import BigInt
public class EthWalletManager {
    var infuraWeb3: String = ""
    public init() {
    }
    
    public func addInfura(infura: String) {
        self.infuraWeb3 = infura
    }
    
    public func createWallet(password: String) -> String {
        guard let userDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
            let keystoreManager = KeystoreManager.managerForPath(userDirectory + "/keystore")
        else {
            fatalError("Couldn't create a KeystoreManager.")
        }
        let keystore = try? EthereumKeystoreV3(password: password, aesMode: "aes-128-ctr")
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
        
        var data: [String: Any] = [:]
        data = ["network": isMainNet() ? "MAINNET" : "TESTNET",
                "action_type": "WALLET_CREATE",
                "wallet_address": (keystore?.getAddress()!.address)!,
                "DEVICE_INFO": getDeviceInfo(),
                "status": "SUCCESS"]
        sendEventToLedger(data: data)
        
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
        
        var data: [String: Any] = [:]
        data = ["network": isMainNet() ? "MAINNET" : "TESTNET",
                "action_type": "WALLET_IMPORT_KEYSTORE",
                "wallet_address": (keyStore?.getAddress()!.address)!,
                "DEVICE_INFO": getDeviceInfo(),
                "status": "SUCCESS"]
        sendEventToLedger(data: data)
        
        return (keyStore?.getAddress()!.address)!
    }
    
    public func exportPrivateKey(walletAddress: String, password: String) -> String {
        let keystore = getKeyStore() as EthereumKeystoreV3
        
        if keystore.getAddress()?.address == walletAddress {
            let address = EthereumAddress(keystore.getAddress()!.address)
            let privateKey = try! keystore.UNSAFE_getPrivateKeyData(password: password, account: address!).toHexString()
            
            var data: [String: Any] = [:]
            data = ["network": isMainNet() ? "MAINNET" : "TESTNET",
                    "action_type": "WALLET_EXPORT_PRIVATE_KEY",
                    "wallet_address": walletAddress,
                    "DEVICE_INFO": getDeviceInfo(),
                    "status": "SUCCESS"]
            sendEventToLedger(data: data)
            
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
            
            var data: [String: Any] = [:]
            data = ["network": isMainNet() ? "MAINNET" : "TESTNET",
                    "action_type": "WALLET_EXPORT_KEYSTORE",
                    "wallet_address": walletAddress,
                    "DEVICE_INFO": getDeviceInfo(),
                    "status": "SUCCESS"]
            sendEventToLedger(data: data)
            
            return backToString
        }
        return ""
    }
    
    public func sentEthereum(senderAddress: String, password: String, receiverAddress: String, amount: String, gasLimit: String) -> String {
        
        let passKey = password
        let infura = web3(provider: Web3HttpProvider(URL(string: infuraWeb3)!)!)
        
        do{
            let keyStore = getKeyStore() as EthereumKeystoreV3
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
        options.gasLimit = .manual(BigUInt(gasLimit)!)

        let tx = contract.write("fallback"/*"transfer"*/, parameters: [AnyObject](), extraData: Data(), transactionOptions: options)

        do {
            // @@@ write transaction requires password, because it consumes gas
            let transaction = try tx?.send( password: passKey )

            print("output", transaction?.transaction.description as Any)
            
            var data: [String: Any] = [:]
            data = ["network": isMainNet() ? "MAINNET" : "TESTNET",
                    "action_type": "SEND_ETHER",
                    "from_wallet_address": senderAddress,
                    "to_wallet_address": receiverAddress,
                    "amount": value,
                    "tx_hash": transaction!.hash,
                    "gasLimit": options.gasLimit!,
                    "gasPrice": options.gasPrice!,
                    "fee": "21000",
                    "DEVICE_INFO": getDeviceInfo(),
                    "status": "SUCCESS"]
            sendEventToLedger(data: data)
            
            return transaction!.hash
                    
        } catch(let err) {
            print("err", err)
        }

        return ""
    }
    
    public func sentERC20Token(senderAddress: String, password: String, contractAddress: String, tokenAmount: String, receiverAddress: String, gasLimit: String) -> String {

        let infura = web3(provider: Web3HttpProvider(URL(string: infuraWeb3)!)!)
        
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
        options.gasLimit = .manual(BigUInt(gasLimit)!)
        let method = "transfer"
        
        let token = ERC20(web3: infura, provider: isMainNet() ? Web3.InfuraMainnetWeb3().provider : Web3.InfuraRopstenWeb3().provider, address: EthereumAddress(contractAddress)!)
        token.readProperties()
        
        let tx = contract.write( method, parameters: [toAddress, amount!] as [AnyObject], extraData: Data(), transactionOptions: options)!
        do {
            
            let transaction = try tx.send( password: password )
            print("output", transaction.transaction.description as Any)
            
            var data: [String: Any] = [:]
            data = ["network": isMainNet() ? "MAINNET" : "TESTNET",
                    "action_type": "SEND_TOKEN",
                    "from_wallet_address": senderAddress,
                    "to_wallet_address": receiverAddress,
                    "amount": value,
                    "tx_hash": transaction.hash,
                    "gasLimit": options.gasLimit!,
                    "gasPrice": options.gasPrice!,
                    "fee": "21000",
                    "token_smart_contract": contractAddress,
                    "token_name": token.name,
                    "token_symbol": token.symbol,
                    "DEVICE_INFO": getDeviceInfo(),
                    "status": "SUCCESS"]
            sendEventToLedger(data: data)
            
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
            
            var data: [String: Any] = [:]
            data = ["network": isMainNet() ? "MAINNET" : "TESTNET",
                    "action_type": "WALLET_IMPORT_PRIVATE_KEY",
                    "wallet_address": keystore.getAddress()!.address,
                    "DEVICE_INFO": getDeviceInfo(),
                    "status": "SUCCESS"]
            sendEventToLedger(data: data)
            
            return keystore.getAddress()!.address
                
            }catch{
                print("Something wrong")
            }
        return "Please enter valid private key"
    }
    
    public func checkBalance(walletAddress: String) -> String {
        
        let infura = web3(provider: Web3HttpProvider(URL(string: infuraWeb3)!)!)
        let address = EthereumAddress(walletAddress)!
        let balance = try? infura.eth.getBalance(address: address)
        let convertToString = Web3.Utils.formatToEthereumUnits(balance!, toUnits: .eth, decimals: 3)
        
        var data: [String: Any] = [:]
        data = ["network": isMainNet() ? "MAINNET" : "TESTNET",
                "action_type": "COIN_BALANCE",
                "wallet_address": walletAddress,
                "balance": convertToString!,
                "DEVICE_INFO": getDeviceInfo(),
                "status": "SUCCESS"]
        sendEventToLedger(data: data)
        
        return convertToString!
    }

    public func checkERC20Balance(walletAddress: String, contractAddress: String) -> String {
        
     //   let web3 = Web3.InfuraRopstenWeb3()
        let infura = web3(provider: Web3HttpProvider(URL(string: infuraWeb3)!)!)
        
        let token = ERC20(web3: infura, provider: isMainNet() ? Web3.InfuraMainnetWeb3().provider : Web3.InfuraRopstenWeb3().provider, address: EthereumAddress(contractAddress)!)
      //  let token = ERC20(web3: web3, provider: Web3.InfuraRopstenWeb3().provider, address: EthereumAddress(contractAddress)!)
        token.readProperties()
        print(token.decimals)
        print(token.symbol)
        print(token.name)
        let balance = try? token.getBalance(account: EthereumAddress(walletAddress)!)
        let convertToString = Web3.Utils.formatToEthereumUnits(balance!, toUnits: .eth, decimals: 3)
        print(convertToString!)
        
        var data: [String: Any] = [:]
        data = ["network": isMainNet() ? "MAINNET" : "TESTNET",
                "action_type": "TOKEN_BALANCE",
                "wallet_address": walletAddress,
                "token_symbol": token.symbol,
                "balance": convertToString!,
                "token_name": token.name,
                "token_smart_contract": contractAddress,
                "DEVICE_INFO": getDeviceInfo(),
                "status": "SUCCESS"]
        sendEventToLedger(data: data)
      
        return (convertToString! + " " + token.symbol)
        
    }
    
    public func getDeviceInfo() -> [String:String]{
        
        var deviceInfo: [String: String] = [:]
        let iosId = UIDevice.current.identifierForVendor!.uuidString
        let osName = "iOS"
        let modelName = UIDevice.current.name
        let serialNumber = "Not allowed"
        let manufacturer = "Apple"
        
        deviceInfo = ["ID": iosId,
                      "OS": osName,
                      "MODEL": modelName,
                      "SERIAL": serialNumber,
                      "MANUFACTURER": manufacturer]
        return deviceInfo
    }
    
    public func sendEventToLedger(data: [String: Any]) {
        
        
        
    }
    
    public func isMainNet() -> Bool {
        if infuraWeb3.contains("mainnet") {
            return true
        } else {
            return false
        }
    }
}
extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
