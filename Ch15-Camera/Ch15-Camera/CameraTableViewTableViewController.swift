//
//  CameraTableViewTableViewController.swift
//  Ch15-Camera
//
//  Created by Ben Smith on 28/01/17.
//  Copyright © 2017 Ben Smith. All rights reserved.
//

import UIKit

enum CameraDemo: Int {
    case PickerView = 0
    case AvCapture
}

class CameraTableViewTableViewController: UITableViewController {


    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CameraDemo")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CameraDemo", for: indexPath)
        
        switch indexPath.row {
        case CameraDemo.PickerView.rawValue:
            cell.textLabel?.text = "Camera Picker View Demo"
            break
        case CameraDemo.AvCapture.rawValue:
            cell.textLabel?.text = "Camera AVCaptureSession Demo"
            break
        default:
            break
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case CameraDemo.PickerView.rawValue:
            self.performSegue(withIdentifier: "pickerView", sender: self)
            break
        case CameraDemo.AvCapture.rawValue:
            self.performSegue(withIdentifier: "AvCapture", sender: self)
            break
        default:
            break
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
 
}
