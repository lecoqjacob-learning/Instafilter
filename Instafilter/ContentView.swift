//
//  ContentView.swift
//  Instafilter
//
//  Created by Jacob LeCoq on 2/24/21.
//

import CoreImage
import CoreImage.CIFilterBuiltins

import SwiftUI

extension String {
    func camelCaseToWords() -> String {
        return unicodeScalars.reduce("") {
            if CharacterSet.uppercaseLetters.contains($1) {
                return ($0 + " " + String($1))
            } else {
                return $0 + String($1)
            }
        }.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ContentView: View {
    @State private var showingFilterSheet = false
    @State private var showingImagePicker = false
    @State private var showingError = false
    
    @State private var showingIntensitySlider = true
    @State private var showingRadiusSlider = false
    @State private var showingScaleSlider = false
    
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 0.5
    @State private var filterScale = 0.5
    
    @State private var image: Image?
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?

    let context = CIContext()
    
    var body: some View {
        let intensity = Binding<Double>(
            get: {
                self.filterIntensity
            },
            set: {
                self.filterIntensity = $0
                self.applyProcessing()
            }
        )
        
        let radius = Binding<Double>(
            get: {
                self.filterRadius
            },
            set: {
                self.filterRadius = $0
                self.applyProcessing()
            }
        )
        
        let scale = Binding<Double>(
            get: {
                self.filterScale
            },
            set: {
                self.filterScale = $0
                self.applyProcessing()
            }
        )
        
        return NavigationView {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color.secondary)

                    if image != nil {
                        image?
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("Tap to select a picture")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                .onTapGesture {
                    self.showingImagePicker = true
                }

                VStack {
                    if self.showingIntensitySlider {
                        HStack {
                            Text("Intensity")
                            Slider(value: intensity)
                        }
                    }
                                    
                    if self.showingRadiusSlider {
                        HStack {
                            Text("Radius")
                            Slider(value: radius)
                        }
                    }
                                    
                    if self.showingScaleSlider {
                        HStack {
                            Text("Scale")
                            Slider(value: scale)
                        }
                    }
                }
                .padding()

                HStack {
                    Button("\(filterName(currentFilter))") {
                        self.showingFilterSheet = true
                    }

                    Spacer()

                    Button("Save") {
                        guard let processedImage = self.processedImage else {
                            self.showingError.toggle()
                            return
                        }

                        let imageSaver = ImageSaver()
                        
                        imageSaver.successHandler = {
                            print("Success!")
                        }

                        imageSaver.errorHandler = {
                            print("Oops: \($0.localizedDescription)")
                        }
                        
                        imageSaver.writeToPhotoAlbum(image: processedImage)
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationBarTitle("Instafilter")
        }
        .actionSheet(isPresented: $showingFilterSheet) {
            ActionSheet(title: Text("Select a filter"), buttons: [
                .default(Text("Crystallize")) { self.setFilter(CIFilter.crystallize()) },
                .default(Text("Edges")) { self.setFilter(CIFilter.edges()) },
                .default(Text("Gaussian Blur")) { self.setFilter(CIFilter.gaussianBlur()) },
                .default(Text("Pixellate")) { self.setFilter(CIFilter.pixellate()) },
                .default(Text("Sepia Tone")) { self.setFilter(CIFilter.sepiaTone()) },
                .default(Text("Unsharp Mask")) { self.setFilter(CIFilter.unsharpMask()) },
                .default(Text("Vignette")) { self.setFilter(CIFilter.vignette()) },
                .cancel()
            ])
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: self.$inputImage)
        }
        .alert(isPresented: $showingError) {
            Alert(title: Text("No Image Selected"))
        }
    }
    
    private func filterName(_ filter: CIFilter) -> String {
        let replacementString = filter.name.replacingOccurrences(of: "CI", with: "", options: .regularExpression, range: nil)
        
        return replacementString.camelCaseToWords()
    }
    
    private func updateSliders(for filter: CIFilter) {
        let inputKeys = filter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) { showingIntensitySlider = true }
        else { showingIntensitySlider = false}
        
        if inputKeys.contains(kCIInputRadiusKey) { showingRadiusSlider = true }
        else { showingRadiusSlider = false }
        
        if inputKeys.contains(kCIInputScaleKey) { showingScaleSlider = true }
        else { showingScaleSlider = false }
    }
    
    private func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        
        updateSliders(for: filter)
        
        loadImage()
    }
    
    private func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadius * 200, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterScale * 10, forKey: kCIInputScaleKey) }
        
        guard let outputImage = currentFilter.outputImage else { return }

        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        
        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
