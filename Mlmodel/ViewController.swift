//
//  ViewController.swift
//  Mlmodel
//
//  Created by vinayaka s yattinahalli on 18/05/20.
//  Copyright © 2020 vinayaka s yattinahalli. All rights reserved.
//
import UIKit
import Photos
import Vision

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var model: SqueezeNet!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        model = SqueezeNet()
    }
    
    func showPhotosNotAllowedPopup() {
        let alert = UIAlertController(title: nil, message: "We need access to your photos library to complete this step. To do this go to Settings -> CoreMLDemo and allow photos library access.", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Not now", style: .default, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { (_) in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }
        })
        alert.addAction(dismissAction)
        alert.addAction(settingsAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func showCameraNotAllowedPopup() {
        let alert = UIAlertController(title: nil, message: "We need access to your camera to complete this step. To do this go to Settings -> CoreMLDemo and allow camera access.", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Not now", style: .default, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { (_) in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }
        })
        alert.addAction(dismissAction)
        alert.addAction(settingsAction)
        present(alert, animated: true, completion: nil)
    }

    @IBAction func takePictureAction(_ sender: Any) {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (response) in
                if response {
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = UIImagePickerController.SourceType.camera
                    imagePicker.cameraFlashMode = .off
                    imagePicker.navigationController?.navigationBar.isTranslucent = false
                    imagePicker.navigationBar.barTintColor = self.navigationController?.navigationBar.barTintColor
                    DispatchQueue.main.async {
                        self.present(imagePicker, animated: true, completion: nil)
                    }
                }
            }
        case .authorized:
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.cameraFlashMode = .off
            imagePicker.navigationController?.navigationBar.isTranslucent = false
            imagePicker.navigationBar.barTintColor = self.navigationController?.navigationBar.barTintColor
            self.present(imagePicker, animated: true, completion: nil)
        default:
            showCameraNotAllowedPopup()
        }
    }
    
    @IBAction func uploadPhotoAction(_ sender: Any) {
        let photosStatus = PHPhotoLibrary.authorizationStatus()
        switch photosStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                if status == .authorized {
                    DispatchQueue.main.async {
                        let imagePicker = UIImagePickerController()
                                           imagePicker.delegate = self
                                           imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
                                           imagePicker.navigationController?.navigationBar.isTranslucent = false
                                           imagePicker.navigationBar.barTintColor = self.navigationController?.navigationBar.barTintColor
                        self.present(imagePicker, animated: true, completion: nil)
                    }
                }
            }
        case .authorized:
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            imagePicker.navigationBar.tintColor = UIColor.white
            imagePicker.navigationBar.barTintColor = self.navigationController?.navigationBar.barTintColor
            let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            imagePicker.navigationBar.titleTextAttributes = attributes
            imagePicker.navigationItem.rightBarButtonItem?.setTitleTextAttributes(attributes, for: .normal)
            self.present(imagePicker, animated: true, completion: nil)
        default:
            showPhotosNotAllowedPopup()
        }

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        picker.dismiss(animated: true, completion: nil)
        
        let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage
        do {
            let vnModel = try VNCoreMLModel(for: model.model)
            let request = VNCoreMLRequest(model: vnModel) { (request, error) in
                // Checks if the data is in the correct format and assigns it to results
                guard let results = request.results as? [VNClassificationObservation] else {
                    self.showErrorMessage("There are no results for this image")
                    return
                }
                // Assigns the first result (if it exists) to firstObject
                guard let firstObject = results.first else {
                    self.showErrorMessage("There are no results for this image")
                    return
                }
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let resultController = storyboard.instantiateViewController(withIdentifier: "ShowResultsViewController") as! ShowResultsViewController
                resultController.image = image
                resultController.prediction = firstObject.identifier
                self.navigationController?.pushViewController(resultController, animated: true)
            }
            let imageData = image.jpegData(compressionQuality: 0.5)
            try VNImageRequestHandler(data: imageData!, options: [:]).perform([request])
        } catch {
            self.showErrorMessage("There are no results for this image")
            print(error)
        }
    }
    
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

    func imageBuffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer!), width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }

}

fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
