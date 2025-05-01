import SwiftUI
import UIKit

// MARK: - Custom Numeric Field with iOS-style Keyboard Toolbar
/// A UIViewRepresentable wrapper that creates a UITextField with a custom keyboard toolbar
/// for numeric input fields. Provides a professional iOS-style numeric input experience with
/// validation, a done button, and optional +/- toggle for negative numbers.
struct CustomNumericField: UIViewRepresentable {
    @Binding var text: String
    var commitAction: (String) -> Void
    var keyboardType: UIKeyboardType
    var minValue: Double
    var maxValue: Double
    var propertyName: String
    
    // Add a default initializer with validation parameters
    init(text: Binding<String>, commitAction: @escaping (String) -> Void, keyboardType: UIKeyboardType, 
         minValue: Double = 0, maxValue: Double = 100, propertyName: String = "Value") {
        self._text = text
        self.commitAction = commitAction
        self.keyboardType = keyboardType
        self.minValue = minValue
        self.maxValue = maxValue
        self.propertyName = propertyName
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.keyboardType = keyboardType
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        textField.delegate = context.coordinator
        
        // Create the keyboard accessory view
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolBar.barStyle = .black // Dark appearance to match iOS style
        
        // Create the input field
        let inputField = UITextField(frame: CGRect(x: 0, y: 0, width: 200, height: 36))
        inputField.textAlignment = .center
        inputField.keyboardType = keyboardType
        inputField.text = text
        inputField.backgroundColor = UIColor(white: 0.3, alpha: 1.0) // Medium gray background
        inputField.textColor = .white
        inputField.font = UIFont.systemFont(ofSize: 22)
        inputField.layer.cornerRadius = 8
        inputField.clipsToBounds = true
        inputField.borderStyle = .none
        inputField.delegate = context.coordinator
        
        // Make the accessory input field become first responder when tapped
        inputField.addTarget(context.coordinator, action: #selector(Coordinator.accessoryFieldTapped), for: .touchUpInside)
        
        // Add a target for the inputField text changes
        inputField.addTarget(context.coordinator, action: #selector(Coordinator.inputFieldDidChange(_:)), for: .editingChanged)
        
        // Create the warning label (hidden by default)
        let warningLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 24))
        warningLabel.font = UIFont.systemFont(ofSize: 12)
        warningLabel.textColor = UIColor.systemRed
        warningLabel.textAlignment = .center
        warningLabel.isHidden = true
        warningLabel.text = "Value must be between \(Int(minValue)) and \(Int(maxValue))"
        
        // Create the done button - using a custom done button to ensure it works
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        doneButton.setTitleColor(.systemBlue, for: .normal)
        doneButton.addTarget(context.coordinator, action: #selector(Coordinator.doneButtonTapped), for: .touchUpInside)
        let doneBarItem = UIBarButtonItem(customView: doneButton)
        
        // Create the +/- toggle button only if minimum value is negative
        // This allows entering negative values without having a minus key
        var toggleNegativeButton: UIButton?
        if minValue < 0 {
            let toggleButton = UIButton(type: .system)
            toggleButton.setTitle("±", for: .normal)
            toggleButton.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
            toggleButton.setTitleColor(.systemBlue, for: .normal)
            toggleButton.addTarget(context.coordinator, action: #selector(Coordinator.toggleNegativeButtonTapped), for: .touchUpInside)
            
            // Set a frame with more space
            toggleButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
            toggleButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
            
            // Store a reference to the toggle button
            toggleNegativeButton = toggleButton
            context.coordinator.toggleNegativeButton = toggleButton
        }
        
        // Add the input field as a bar button item
        let inputFieldItem = UIBarButtonItem(customView: inputField)
        
        // Flex spaces for layout
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // Create toolbar items array
        var toolbarItems: [UIBarButtonItem] = []
        
        // Add toggle negative button if needed
        if let toggleButton = toggleNegativeButton {
            let toggleItem = UIBarButtonItem(customView: toggleButton)
            toolbarItems = [toggleItem, flexSpace, inputFieldItem, flexSpace, doneBarItem]
        } else {
            toolbarItems = [flexSpace, inputFieldItem, flexSpace, doneBarItem]
        }
        
        // Main bar with input field and done button
        toolBar.setItems(toolbarItems, animated: false)
        
        // Create a much larger container to fill the gap completely
        let containerHeight: CGFloat = 60 // Make this much larger to cover the gap
        
        // Create a combined view for the toolbar with warning and keyboard background filler
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: containerHeight))
        
        // Fill the entire container with keyboard-matching background
        containerView.backgroundColor = UIColor(red: 0.23, green: 0.23, blue: 0.23, alpha: 1.0) // Match keyboard color
        
        toolBar.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        
        // Position warning label below the toolbar
        warningLabel.frame = CGRect(x: (UIScreen.main.bounds.width - 300) / 2, 
                                  y: toolBar.frame.maxY - 2,
                                  width: 300, 
                                  height: 24)
        
        // Create filler view to extend to the keyboard - now much taller
        let fillerView = UIView(frame: CGRect(x: 0, 
                                           y: warningLabel.frame.maxY, 
                                           width: UIScreen.main.bounds.width, 
                                           height: containerHeight - warningLabel.frame.maxY))
        fillerView.backgroundColor = containerView.backgroundColor
        
        containerView.addSubview(toolBar)
        containerView.addSubview(warningLabel)
        containerView.addSubview(fillerView)
        
        // Store references for the coordinator
        context.coordinator.inputField = inputField
        context.coordinator.mainTextField = textField
        context.coordinator.doneButton = doneButton
        context.coordinator.warningLabel = warningLabel
        context.coordinator.minValue = minValue
        context.coordinator.maxValue = maxValue
        context.coordinator.propertyName = propertyName
        
        // Set the custom view as the input accessory view
        textField.inputAccessoryView = containerView
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        context.coordinator.inputField?.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, commitAction: commitAction, minValue: minValue, maxValue: maxValue, propertyName: propertyName)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        var commitAction: (String) -> Void
        var inputField: UITextField?
        var mainTextField: UITextField?
        var doneButton: UIButton?
        var toggleNegativeButton: UIButton?
        var warningLabel: UILabel?
        var tempValue: String = ""
        var isDoneButtonPressed = false
        var minValue: Double
        var maxValue: Double
        var propertyName: String
        
        init(text: Binding<String>, commitAction: @escaping (String) -> Void, 
             minValue: Double, maxValue: Double, propertyName: String) {
            self._text = text
            self.commitAction = commitAction
            self.tempValue = text.wrappedValue
            self.minValue = minValue
            self.maxValue = maxValue
            self.propertyName = propertyName
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            // If Done was pressed, don't process this event
            if isDoneButtonPressed {
                textField.resignFirstResponder()
                return
            }
            
            // When main text field begins editing, update accessory field and move cursor to end
            if textField == mainTextField, let inputField = self.inputField {
                inputField.text = text
                tempValue = text
                
                // Hide any previous warning
                warningLabel?.isHidden = true
                
                // Position cursor at the end of the text
                let endPosition = inputField.endOfDocument
                inputField.selectedTextRange = inputField.textRange(from: endPosition, to: endPosition)
                
                // Make the accessory input field the first responder
                DispatchQueue.main.async {
                    inputField.becomeFirstResponder()
                }
            }
        }
        
        @objc func toggleNegativeButtonTapped() {
            // Get the current value from the input field
            guard let inputField = self.inputField else { return }
            
            // If the field is empty, add a negative sign
            if inputField.text?.isEmpty ?? true {
                inputField.text = "-"
                tempValue = "-"
                return
            }
            
            // Toggle the negative sign
            if inputField.text?.hasPrefix("-") ?? false {
                // Remove the negative sign
                inputField.text = String(inputField.text!.dropFirst())
                tempValue = inputField.text!
            } else {
                // Add a negative sign
                inputField.text = "-" + inputField.text!
                tempValue = inputField.text!
            }
            
            // Update cursor position to end
            let endPosition = inputField.endOfDocument
            inputField.selectedTextRange = inputField.textRange(from: endPosition, to: endPosition)
        }
        
        @objc func inputFieldDidChange(_ textField: UITextField) {
            // Track the input field's current value
            if let value = textField.text {
                tempValue = value
                // Hide warning when user types
                warningLabel?.isHidden = true
            }
        }
        
        @objc func accessoryFieldTapped() {
            // When accessory field is tapped, position cursor at end
            if let inputField = self.inputField {
                let endPosition = inputField.endOfDocument
                inputField.selectedTextRange = inputField.textRange(from: endPosition, to: endPosition)
            }
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            // Don't process this if it's part of the Done button dismissal
            if isDoneButtonPressed {
                return
            }
            
            if let value = textField.text {
                text = value
                commitAction(value)
            }
        }
        
        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            // Prevent the text field from being editable if we're in the process of dismissing
            return !isDoneButtonPressed
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
        
        @objc func doneButtonTapped() {
            // Validate the input value
            if let doubleValue = Double(tempValue) {
                if doubleValue < minValue || doubleValue > maxValue {
                    // Show warning if value is out of bounds
                    warningLabel?.text = "\(propertyName) must be between \(Int(minValue)) and \(Int(maxValue))"
                    warningLabel?.isHidden = false
                    
                    // Keep keyboard open for user to correct value
                    return
                }
                
                // Value is valid, proceed with dismissal
                // Set the flag to prevent re-activation
                isDoneButtonPressed = true
                
                // Use the tempValue that has been tracking the input field's changes
                text = tempValue
                commitAction(tempValue)
                
                // Update the main text field with the new value
                mainTextField?.text = tempValue
                
                // Ensure UI updates are completed before dismissing keyboard
                DispatchQueue.main.async { [weak self] in
                    // Properly dismiss the keyboard
                    self?.inputField?.resignFirstResponder()
                    self?.mainTextField?.resignFirstResponder()
                    
                    // Extra measure to ensure keyboard dismissal
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    
                    // Reset the flag after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.isDoneButtonPressed = false
                    }
                }
            } else {
                // Invalid numeric input
                warningLabel?.text = "Please enter a valid number"
                warningLabel?.isHidden = false
            }
        }
        
        @objc func cancelButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
} 