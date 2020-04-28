//
//  ViewController.swift
//  ImageProcessingOpenCV
//
//  Created by Mariia Turchina on 23/05/2019.
//  Copyright © 2019 Mariia Turchina. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, OpenCVCamDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet weak var stopButton: UIButton!
    
    var startTime = CFAbsoluteTimeGetCurrent()
    
    var openCVWrapper: OpenCVWrapper!
    var centralManager: CBCentralManager!
    
    var lastTimeSet: Double = 0
    
    var botBlue: BluetoothBot!
    var botYellow: BluetoothBot!
    var botOrange: BluetoothBot!
    var botPink: BluetoothBot!
    var botPurple: BluetoothBot!
    var botGreen: BluetoothBot!
    
    var botGreenSander: BluetoothBot!
    //var botBlueSander: BluetoothBot!
    
    var bots : [BluetoothBot] = []
    
    let botUUID = CBUUID(string: "FFE0")
    let botUUIDChar = CBUUID(string: "FFE1")
    
    var botPositions : [String : BotPosition] = [ "green" : BotPosition(),
                                                  "purple"  : BotPosition(),
                                                  "pink" : BotPosition(),
                                                  "blue"  : BotPosition(),
                                                  "yellow"  : BotPosition(),
                                                  "orange"  : BotPosition(),
                                                  "noname" : BotPosition()  ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startButton.backgroundColor = UIColor(red:0.20, green:0.80, blue:0.20, alpha:1.0)
        startButton.layer.cornerRadius = 8
        stopButton.backgroundColor = UIColor(red:1.00, green:0.27, blue:0.00, alpha:1.0)
        stopButton.layer.cornerRadius = 8
        
        print("\(OpenCVWrapper.openCVVersionString())")
        
        openCVWrapper = OpenCVWrapper()
        openCVWrapper.setDelegate(self)
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        botYellow = BluetoothBot(MAC: "9831621E-AD2B-BC08-8CCA-EB7D6E83B81D", name: "yellow")
        botBlue = BluetoothBot(MAC: "6C6FD342-FD26-ACFE-65D7-26514E282746", name: "blue")
        botOrange = BluetoothBot(MAC: "16017A2B-B36E-B81C-EAB7-41319C092A0D", name: "orange")
        botPurple = BluetoothBot(MAC: "6C8A945E-AD27-1D10-5371-0CFB97C2C5A3", name: "purple")
        //botPurple = BluetoothBot(MAC: "951A35A7-9FF3-D478-2571-A146D5F50903", name: "purple")
        botGreen = BluetoothBot(MAC: "0E4B15D2-1182-E1F9-5E1A-C9D01D2BF795", name: "green")
        
        //botPurpleSander = BluetoothBot(MAC: "FA3731E6-A156-4DF2-D54E-50F22184FBD5", name: "purple")
        //botBlueSander = BluetoothBot(MAC: "AA21EB7E-CC1D-A3EF-ED04-BA84F92CAEF6", name: "blue")
        botGreenSander = BluetoothBot(MAC: "922585F2-76D7-BDFD-E338-53372E8AB0F4", name: "green")
       
        
        bots = [botYellow, botBlue, botOrange, botPurple, botGreen]
        //bots = [ botGreenSander]
        openCVWrapper.start()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
            print("BLUETOOTH IS NOT ENABLED")
        case .poweredOn:
            print("central.state is .poweredOn")
            // Code specifc UUID for bots. For now search for everyting
            centralManager.scanForPeripherals(withServices: [botUUID])
        @unknown default:
            print("Execution error")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        
        for bot in bots {
            if(peripheral.identifier.uuidString == bot.mac) {
                print("trying to connect to ", bot.name)
                bot.peripheral = peripheral;
                centralManager.connect(peripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        //
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
        for bot in bots {
            if(peripheral.identifier.uuidString == bot.mac) {
                print(bot.name, " is connected. Discovering characteristics")
            }
        }
        
        if(bots.allSatisfy{$0.connected}) {
            centralManager.stopScan()
            print("all devices connected")
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            print("Failed to connect to peripheral")
            print("FAILLLLL")
            
            
            for bot in bots {
                print(bot.name, "connected: ", bot.connected, bot.characteristic ?? "none")
                if(bot.peripheral != nil && !bot.connected) {
                    print("reconectig to the piece of shit: ", bot.name)
                    centralManager.connect(bot.peripheral!, options: nil)
                }
            }
 
            
            return
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        
        //We need to discover the all characteristic
        for service in services {
            peripheral.discoverCharacteristics([botUUIDChar], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Check for errors
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        // Super dirty; but works
        for bot in bots {
            if(peripheral.identifier.uuidString == bot.mac) {
                for characteristic in characteristics {
                    //looks for the right characteristic
                    print(bot.name, "is ready like a beast")
                    bot.characteristic = characteristic;
                }
            }
        }
    }
    
    func imageProcessed(_ image: UIImage) {
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
    
    func botUpdate(_ message: String) {
        let diffTime = CFAbsoluteTimeGetCurrent() - startTime
        
        if (diffTime >= 0.1){
            startTime += diffTime
            
            //print("elapsed time = ", diffTime, " seconds")
            
            if (message == "noinfo"){
                return
            }
            let lines = message.components(separatedBy: ";").filter { !$0.isEmpty }
            //print(lines)
            
            for (_, botInfo) in botPositions {
                botInfo.closest = false
            }
            
            var curretlyDetected : [String] = []
            
            for line in lines {
                var message_split = line.split{$0 == ":"}.map(String.init)
                let botname: String = message_split[0]
                curretlyDetected.append(botname)
                let intersectionDist : Int = Int(message_split[1]) ?? 10000
                let quadrant : Int = Int(message_split[2]) ?? -1
                
                botPositions[botname] = BotPosition(intersectionDist: intersectionDist, quadrant: quadrant)
                
                // idk what next lines are doing exactly
                // we need to calculate speed of each bot and then send each bot a message with its speed
                //print(botname, cmd!)
            }
            //print(curretlyDetected)
            
            var connectedBots = filterForConnectedBots(with: curretlyDetected)
            connectedBots = determineBotSpeed(connectedBots: connectedBots)
            
            //let a = "10"
            for bot in bots {
                if (connectedBots[bot.name] == nil){
                    continue
                }
                let botName = bot.name
                var messageSpeed = "\(connectedBots[botName]?.speed ?? 0)"
                messageSpeed += "#"
                
                bot.sendMessage(message: messageSpeed)
                
                print(botName, " --- speed: ", connectedBots[botName]?.speed ?? "no bot")
            }
            
        }
    }
    
    func filterForConnectedBots(with currDetected : [String]) -> [String : BotPosition] {
        var connectedBots : [String : BotPosition] = [:]
        for bot in bots {
            if (bot.connected && currDetected.contains(bot.name)){
                //if (currDetected.contains(bot.name)){
                let botName = bot.name
                let botInfo = botPositions[botName]
                connectedBots[botName] = botInfo
                print("connected :", botName)
            }
        }
        return connectedBots
    }
    
    
    var closestBot : BotPosition = BotPosition()
    
    func determineBotSpeed (connectedBots : [String : BotPosition]) -> [String : BotPosition] {
        let closestName = closestBotName(connectedBots: connectedBots)
        botPositions[closestName]?.closest = true
        botPositions[closestName]?.speed = 5
        closestBot = botPositions[closestName]!
        adjustSpeedFurtherBots(connectedBots: connectedBots)
        //adjustBotInDanger(connectedBots: connectedBots)
        return connectedBots
    }
    
    func adjustBotInDanger(connectedBots : [String : BotPosition]) {
        var minDist = 100000
        if (closestBot.quadrant == 2){
            for (_, botInfo) in connectedBots{
                if (botInfo.quadrant == 3 &&
                    (botInfo.intersectionDist <= minDist)){
                    minDist = botInfo.intersectionDist
                    botInfo.speed = 3
                }
            }
        } else if (closestBot.quadrant == 4){
            for (_, botInfo) in connectedBots{
                if (botInfo.quadrant == 1 &&
                    (botInfo.intersectionDist <= minDist)){
                    minDist = botInfo.intersectionDist
                    botInfo.speed = 3
                }
            }
        }
    }
    
    func adjustSpeedFurtherBots(connectedBots : [String : BotPosition]) {
        for (botName, botInfo) in connectedBots{
            let bBot = findBluetoothBot(with : botName)
            if (!botInfo.closest && bBot.connected){
                if (botInfo.quadrant % 2 == 1){
                    botInfo.speed = 2
                } else {
                    botInfo.speed = 1
                }
            }
        }
    }
    
    func findBluetoothBot(with name : String) -> BluetoothBot{
        for bot in bots{
            if (bot.name == name){
                return bot
            }
        }
        return bots[0]
    }
    
    func closestBotName (connectedBots : [String : BotPosition]) -> String{
        let noname = "noname"
        var minDist24 = 1000
        var minName24 = noname
        var minDist13 = -1000
        var minName13 = noname
        
        for (botName, botInfo) in connectedBots {
            let bBot = findBluetoothBot(with : botName)
            if (botInfo.quadrant == 2 || botInfo.quadrant == 4){
                if (botInfo.intersectionDist <= minDist24 &&
                    bBot.connected){
                    minDist24 = botInfo.intersectionDist
                    minName24 = botName
                }
            } else if (botInfo.quadrant == 1 || botInfo.quadrant == 3 &&
                bBot.connected) {
                if (botInfo.intersectionDist >= minDist13){
                    minDist13 = botInfo.intersectionDist
                    minName13 = botName
                }
            }
        }
        
        if (minName24 != noname){
            return minName24
        } else {
            return minName13
        }
    }
    
    @IBAction func start(_ button: UIButton) {
        //openCVWrapper.start()
    }
    
    @IBAction func stop(_ button: UIButton) {
        openCVWrapper.stop()
    }
}
