/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The Vision view controller, which recognizes and displays bounding boxes around text.
 */

import Foundation
import UIKit
import AVFoundation
import Vision

class VisionViewController: ViewController {
    var request: VNRecognizeTextRequest!
    let numberTracker = StringTracker()
    
    // Add a spinner for loading indication
    var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the spinner
        spinner = UIActivityIndicatorView(style: .large)
        spinner.center = view.center
        spinner.color = .label
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        
        overrideUserInterfaceStyle = .light
        
        // Set up the Vision request
        request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        
        DispatchQueue.main.async {
            self.spinner.startAnimating()
        }
    }
    
    // MARK: - Text recognition
    
    // The Vision recognition handler.
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        var numbers = [String]()
        var yellowBoxes = [CGRect]() // Shows all recognized text lines.
        var redBoxes = [CGRect]() // Shows words that might be serials.
        
        guard let results = request.results as? [VNRecognizedTextObservation], let username = UserDefaults.standard.string(forKey: "userName") else {
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
            return
        }
        
        let maximumCandidates = 1
        
        for visionResult in results {
            guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }
            
            var numberIsSubstring = true
            
            if let result = candidate.string.extractName(name: username) {
                let (range, number) = result
                if let box = try? candidate.boundingBox(for: range)?.boundingBox {
                    numbers.append(number)
                    redBoxes.append(box)
                    numberIsSubstring = !(range.lowerBound == candidate.string.startIndex && range.upperBound == candidate.string.endIndex)
                }
            }
            if numberIsSubstring {
                yellowBoxes.append(visionResult.boundingBox)
            }
        }
        
        numberTracker.logFrame(strings: numbers)
        show(boxGroups: [(color: .yellow, boxes: yellowBoxes), (color: .red, boxes: redBoxes)])
        
        if let sureNumber = numberTracker.getStableString() {
            showString(string: sureNumber)
            numberTracker.reset(string: sureNumber)
        }
        
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
        }
    }

    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            // Configure for running in real time.
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.regionOfInterest = regionOfInterest
            request.preferBackgroundProcessing = true
            
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: textOrientation, options: [:])
            do {
                try requestHandler.perform([request])
            } catch {
                print(error)
            }
        }
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
