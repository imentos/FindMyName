/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The Vision view controller, which recognizes and displays bounding boxes around text.
 */

import Foundation
import UIKit
import AVFoundation
import Vision
import CoreImage

class VisionViewController: ViewController {    
    var request: VNRecognizeTextRequest!
    // The temporal string tracker.
    let numberTracker = StringTracker()
    
    override func viewDidLoad() {
        // Set up the Vision request before letting ViewController set up the camera
        // so it exists when the first buffer is received.
        request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        request.regionOfInterest = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.2) // Adjust ROI as needed
        
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .light
    }
    
    // MARK: - Text recognition
    
    // The Vision recognition handler.
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        var numbers = [String]()
        var redBoxes = [CGRect]() // Shows all recognized text lines.
        var greenBoxes = [CGRect]() // Shows words that might be serials.
        
        guard let results = request.results as? [VNRecognizedTextObservation], let username = UserDefaults.standard.string(forKey: "userName") else {
            return
        }
        
        let maximumCandidates = 1
        
        for visionResult in results {
            guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }
            
            // Draw red boxes around any detected text and green boxes around
            // any detected phone numbers. The phone number may be a substring
            // of the visionResult. If it's a substring, draw a green box around
            // the number and a red box around the full string. If the number
            // covers the full result, only draw the green box.
            var numberIsSubstring = true
            
            if let result = candidate.string.extractName(name: username) {
                let (range, number) = result
                // The number might not cover full visionResult. Extract the bounding
                // box of the substring.
                if let box = try? candidate.boundingBox(for: range)?.boundingBox {
                    numbers.append(number)
                    greenBoxes.append(box)
                    numberIsSubstring = !(range.lowerBound == candidate.string.startIndex && range.upperBound == candidate.string.endIndex)
                }
            }
            if numberIsSubstring {
                redBoxes.append(visionResult.boundingBox)
            }
        }
        
        // Log any found numbers.
        numberTracker.logFrame(strings: numbers)
        show(boxGroups: [(color: .yellow, boxes: redBoxes), (color: .red, boxes: greenBoxes)])
        
        // Check if there are any temporally stable numbers.
        if let sureNumber = numberTracker.getStableString() {
            showString(string: sureNumber)
            numberTracker.reset(string: sureNumber)
        }
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
        // Preprocess the image to reduce noise
        if let preprocessedImage = preprocessImage(pixelBuffer: pixelBuffer) {
            let requestHandler = VNImageRequestHandler(ciImage: preprocessedImage, orientation: textOrientation, options: [:])
            do {
                try requestHandler.perform([request])
            } catch {
                print("Error performing Vision request: \(error)")
            }
        }
    }
    }

    func preprocessImage(pixelBuffer: CVPixelBuffer) -> CIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Convert to grayscale
        let grayscaleFilter = CIFilter(name: "CIColorControls")
        grayscaleFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        grayscaleFilter?.setValue(0.0, forKey: kCIInputSaturationKey) // Remove color
        grayscaleFilter?.setValue(1.0, forKey: kCIInputContrastKey)   // Increase contrast
        
        // Apply thresholding to remove noise
        if let grayscaleImage = grayscaleFilter?.outputImage {
            let thresholdFilter = CIFilter(name: "CIThreshold")
            thresholdFilter?.setValue(grayscaleImage, forKey: kCIInputImageKey)
            thresholdFilter?.setValue(0.5, forKey: "inputThreshold") // Adjust threshold value
            return thresholdFilter?.outputImage
        }
        
        return nil
    }
    
    // MARK: - Bounding box drawing
    
    // Draw a box on the screen, which must be done the main queue.
    var boxLayer = [CAShapeLayer]()
    func drawBox(rect: CGRect, color: CGColor, borderWidth: CGFloat = 1) {
        let layer = CAShapeLayer()
        layer.opacity = 0.5
        layer.borderColor = color
        layer.borderWidth = borderWidth
        layer.frame = rect
        boxLayer.append(layer)
        previewView.videoPreviewLayer.insertSublayer(layer, at: 1)
    }
    
    func drawLine(rect: CGRect, color: CGColor, borderWidth: CGFloat = 1) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: rect.origin.y + rect.size.height))
        path.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height))
                
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.strokeColor = color
        layer.lineWidth = borderWidth
        
        boxLayer.append(layer)
        previewView.videoPreviewLayer.insertSublayer(layer, at: 1)
    }
    
    // Remove all drawn boxes. Must be called on main queue.
    func removeBoxes() {
        for layer in boxLayer {
            layer.removeFromSuperlayer()
        }
        boxLayer.removeAll()
    }
    
    typealias ColoredBoxGroup = (color: UIColor, boxes: [CGRect])
    
    // Draws groups of colored boxes.
    func show(boxGroups: [ColoredBoxGroup]) {
        DispatchQueue.main.async {
            let layer = self.previewView.videoPreviewLayer
            self.removeBoxes()
            for boxGroup in boxGroups {
                let color = boxGroup.color
                for box in boxGroup.boxes {
                    let rect = layer.layerRectConverted(fromMetadataOutputRect: box.applying(self.visionToAVFTransform))
                    if color == UIColor.red {
                        self.drawBox(rect: rect, color: color.cgColor, borderWidth: 2)
                        self.drawLine(rect: rect, color: color.cgColor)
                    } else {
                        self.drawBox(rect: rect, color: color.cgColor)
                    }
                }
            }
        }
    }
}
