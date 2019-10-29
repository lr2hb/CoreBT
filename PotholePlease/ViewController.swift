//
//  ViewController.swift
//  PotholePlease
//
//  Created by Liam Robb on 10/29/19.
//  Copyright © 2019 Liam Robb. All rights reserved.
//

import UIKit
import CoreBluetooth

let heartRateServiceCBUUID = CBUUID(string: "0x780A")//"780A" scale // 00ff bledevice

let scaleCharacteristicCBUUID = CBUUID(string: "0x8AA2") // 8AA2

class ViewController: UIViewController {

    @IBOutlet weak var heartRateLabel: UILabel!
    var centralManager: CBCentralManager!
    var heartratePeripheral: CBPeripheral!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        centralManager = CBCentralManager(delegate: self, queue: nil)

        // Make the digits monospaces to avoid shifting when the numbers change
        heartRateLabel.font = UIFont.monospacedDigitSystemFont(ofSize: heartRateLabel.font!.pointSize, weight: .regular)
    }
    func onHeartRateReceived(_ heartRate: Int) {
      heartRateLabel.text = String(heartRate) + " g"
      print("BPM: \(heartRate)")
    }


}

extension ViewController: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
      switch central.state{
        
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
      case .poweredOn:
        print("central.state is .poweredOn")
        // next line change if you want to connect to other shit. ESP_A2DP_SRC name, service
        // uuid might change but for now its 0x00ff, can just change it above, but shud rename
        centralManager.scanForPeripherals(withServices: [heartRateServiceCBUUID] )
        
      }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
      
      
      print(peripheral)
      
      heartratePeripheral = peripheral
      
      heartratePeripheral.delegate = self
      
      centralManager.stopScan()
      centralManager.connect(heartratePeripheral)
    
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
      
      print("connected!")
      
      heartratePeripheral.discoverServices(nil) //
      
    }
}

extension ViewController: CBPeripheralDelegate{

      func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        
        
        
        for service in services {
          print(service)
          
          peripheral.discoverCharacteristics(nil, for: service)
          //print(service.characteristics ?? "characteristics are nil")
        }
      }
      
      func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
          print(characteristic) // commented out for .read stuff, we may nt need
    //      if characteristic.properties.contains(.read) {
    //        print("\(characteristic.uuid): properties contains .read")
    //        peripheral.readValue(for: characteristic)
    //
    //      }
          if characteristic.properties.contains(.notify) {
            print("\(characteristic.uuid): properties contains .notify")
            peripheral.setNotifyValue(true, for: characteristic) // this spits out the 8 BYTES
          }
        }
      }
      
      func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
          case scaleCharacteristicCBUUID:  // this is where we set the output
            let bpm = heartRate(from: characteristic)// call funtion to habdle raw data
            // probs rename bpm and heartrate
            onHeartRateReceived(bpm) // calling class function
          default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
      }
    
    
      // handling scale data
      private func heartRate(from characteristic: CBCharacteristic) -> Int {
        
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        let a = (Int(byteArray[3] << 16)) + (Int(byteArray[2]) << 8) + Int(byteArray[1])
        return a
      }
    
    
    // this func was for handling heartrate data (possibly useful)
    
    //  let firstBitValue = byteArray[0] & 0x01
    //    if firstBitValue == 0 {
    //      // Heart Rate Value Format is in the 2nd byte
    //      return Int(byteArray[1])
    //    } else {
    //      // Heart Rate Value Format is in the 2nd and 3rd bytes
    //      return (Int(byteArray[1]) << 8) + Int(byteArray[2])
    //    }
    //  }
      
}

