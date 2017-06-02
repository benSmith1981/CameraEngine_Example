//
//  ViewController.swift
//  Ch15-Camera
//
//  Created by Ben Smith on 27/01/17.
//  Copyright © 2017 Ben Smith. All rights reserved.
//

import UIKit

class PickerViewController: UIViewController,
                            UINavigationControllerDelegate {

    @IBOutlet weak var imageName: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    let picker = UIImagePickerController()
    
    @IBAction func Library(_ sender: AnyObject) {
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func TakePc(_ sender: AnyObject) {
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.allowsEditing = false
            picker.sourceType = UIImagePickerControllerSourceType.camera
            picker.cameraCaptureMode = .photo
            picker.modalPresentationStyle = .fullScreen
            present(picker,animated: true,completion: nil)
        } else {
            picker.sourceType = .photoLibrary
        }
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        

        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.frame.width/2
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension PickerViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage //2
        imageView.contentMode = .scaleAspectFit //3
        imageView.image = chosenImage //4
        dismiss(animated:true, completion: nil) //5
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}

