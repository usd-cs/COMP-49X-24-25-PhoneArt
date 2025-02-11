# PhoneArt - Interactive Art Creation App

## Project Description 

PhoneArt is an innovative iOS application that enables users to create mesmerizing circular art patterns through an intuitive touch interface. The app features a dynamic canvas where users can manipulate geometric shapes by adjusting properties such as rotation, scale, and layering to produce unique artistic compositions.

## Technologies Used

- **Swift & SwiftUI** - Modern declarative UI framework for building the native iOS interface
- **XCTest** - Comprehensive testing framework for unit and UI testing
- **Xcode** - Primary development environment with integrated debugging and testing tools
- **MVC Architecture** - Traditional Model-View-Controller pattern for organizing code, where Models handle data, Views display the interface, and Controllers manage the interaction between them

## Key Features

As of 12/10/2024, the following features are available:
- Interactive canvas for creating circular art patterns
- Real-time shape manipulation through touch gestures (drag, pinch, rotate)
- Properties panel for precise control over:
  - Rotation: the rotation we want to apply to each layer
  - Scale: the scale we want to apply to the whole canvas. This will be separate from the zoom gesture, which is to be implemented in the future
  - Layer count: number of shapes in the pattern, each layer will be rotated by the set amount
- Position reset functionality
- Responsive and fluid user interface

## Installation

1. Clone the repository
2. Open the project in Xcode (Version 15.0 or later recommended)
3. Build and run the application on iOS 16.0+ devices or simulator

## Usage

1. Launch the app to access the main canvas
2. The canvas will be centered on the screen, and the user will be able to drag the canvas around.
    - The blue button on the top right will allow the user to reset the canvas to the center
3. The properties panel will be on the bottom left, and will allow the user to adjust the rotation, scale, and layer count.
    - The canvas will appear as empty since the layer count is set to 0
4. The user can then adjust the available properties, and the canvas will update in real time. 
    - With the current implementation, I would recommend setting the scale to the minimum to see the full effect of the rotation and layer count.

## Testing

The project includes comprehensive test coverage:
- Unit tests for core functionality
- UI tests for user interactions

## Contributors

Developed by:
- Aditya Prakash
- Zachary Letcher
- Emmett de Bruin
- Noah Huang
