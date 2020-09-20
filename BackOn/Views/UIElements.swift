//
//  UIElements.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 12/02/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import SwiftUI
import PhotosUI
import CropViewController

let defaultButtonDimensions = (width: CGFloat(155.52), height: CGFloat(48))

let customDateFormat: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

func defaultAlert(title: String, message: String) -> UIAlertController {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Got it!", style: .default))
    return alert
}

struct PhotoPicker: UIViewControllerRepresentable {
    let imageBinding: Binding<UIImage>
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = PHPickerFilter.images
        let controller = PHPickerViewController(configuration: config)
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate, CropViewControllerDelegate {
        private let parent: PhotoPicker
        init(_ parent: PhotoPicker) {
            self.parent = parent
            super.init()
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            results.first?.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
                guard error == nil else {return}
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.imageBinding.wrappedValue = image
                        let cropController = CropViewController(croppingStyle: .default, image: image)
                        cropController.delegate = self
                        cropController.aspectRatioPreset = .presetSquare
                        cropController.aspectRatioLockEnabled = true
                        cropController.resetAspectRatioEnabled = false
                        cropController.aspectRatioPickerButtonHidden = true
                        picker.present(cropController)
                    }
                }
            })
        }
        
        public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
            self.parent.imageBinding.wrappedValue = image
            cropViewController.dismiss(animated: true) {
                self.parent.isPresented = false
            }
        }
        public func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
            cropViewController.dismiss(animated: true) {
                self.parent.isPresented = false
            }
        }
    }
}

struct ElementPickerGUI: View {
    var pickerElements: [String]
    @Binding var selectedValue: Int
    
    var body: some View {
        Picker("Select your need", selection: self.$selectedValue) {
            ForEach(0 ..< self.pickerElements.count) {
                Text(self.pickerElements[$0])
                    .font(.headline)
                    .fontWeight(.medium)
            }
        }
        .labelsHidden()
        .frame(width: UIScreen.main.bounds.width, height: 250)
        .background(Color.primary.colorInvert())
    }
}

struct DatePickerGUI: View {
    @Binding var selectedDate: Date
    @Binding var showBusyWarning: Bool
    
    var body: some View {
        let dateBinding: Binding<Date> = Binding(
            get: {self.selectedDate},
            set: { newDate in
                self.selectedDate = newDate
                self.showBusyWarning = Calendar.controller.isBusy(when: newDate)
            }
        )
        return VStack (spacing: 0){
            DatePicker("", selection: dateBinding, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .frame(width: UIScreen.main.bounds.width)
            if showBusyWarning { Text("You seem busy, check the calendar").tint(.yellow).offset(y: -5) }
            Spacer()
        }.frame(width: UIScreen.main.bounds.width, height: 260).background(Color.primary.colorInvert())
    }
}

struct NoDiscoverablesAroundYou: View {
    var body: some View {
        VStack(alignment: .center){
            Spacer()
            Image(systemName: "mappin.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 150)
                .foregroundColor(Color(.systemGray))
            Group {
                if Discover.controller.canLoadAroundYouMap {
                    if let lastLocation = Geo.controller.lastLocation {
                        if lastLocation.horizontalAccuracy > Geo.controller.horizontalAccuracy {
                            Text("Locating...")
                        } else {
                            Text("It seems there's no one to help around you")
                        }
                    } else {
                        Text("Your location is currently unavailable")
                        Text("Enable localization to use the discover section")
                    }
                } else {
                    Text("Loading discoverables...")
                }
            }.font(.headline).tint(.gray)
            Spacer()
        }
    }
}

struct SizedDivider: View {
    let width: CGFloat
    let height: CGFloat
    
    init(height: CGFloat, width: CGFloat = UIScreen.main.bounds.width) {
        self.height = height
        self.width = width
    }
    var body: some View {
        Rectangle().frame(width: width, height: height).hidden()
    }
}

struct AlertView: View {
    @Binding var isPresented: Bool
    
    var body: some View{
        VStack {
            EmptyView()
        }.alert(isPresented: $isPresented) {
            Alert(title: Text("Oh no!"), message: Text("It seems that this request was already accepted by another user.\nThank you anyway for your help and support, we really apreciate it."), dismissButton: .default(Text("Got it!")))
        }
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text : String
    let onDelete: () -> Void

    class Coordinator : NSObject, UISearchBarDelegate {
        @Binding var text: String
        let onDelete: () -> Void
        init(_ text: Binding<String>, onDelete: @escaping () -> Void) {
            _text = text
            self.onDelete = onDelete
        }
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            text = ""
            searchBar.endEditing(true)
            onDelete()
        }
    }

    func makeCoordinator() -> Coordinator { return Coordinator($text, onDelete: onDelete) }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.searchBarStyle = .minimal
        searchBar.showsCancelButton = true
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }
}
