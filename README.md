# PhoneArt - Interactive Art Creation App

Create mesmerizing circular art patterns with an intuitive touch interface.

## 📖 Table of Contents
- [Project Description](#project-description)
- [Technologies Used](#technologies-used)
- [Key Features](#key-features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Testing](#testing)
- [Project Status](#project-status)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Project Description

The MathArt App is an iOS mobile application inspired by the MathArt Playground website (https://mathart.us/ng-playground/). This app seeks to simplify the process of creating visually stimulating images by enabling users to manipulate shapes, colors, and transformations through mathematical functions. Beyond merely providing tools for artistic expression, the app aims to fill an educational gap by making the intersection of art and math more accessible and engaging. By fostering creativity and learning, the MathArt App addresses the challenge of introducing mathematical principles in a visually intuitive and user-friendly manner.

## Technologies Used

- **Swift & SwiftUI** - Modern declarative UI framework for building the native iOS interface
- **Firebase** - Backend service for artwork storage and sharing
- **XCTest** - Comprehensive testing framework for unit and UI testing
- **Xcode** - Primary development environment with integrated debugging and testing tools
- **MVC Architecture** - Traditional Model-View-Controller pattern for organizing code, where Models handle data, Views display the interface, and Controllers manage the interaction between them

## Key Features

As of 5/15/2025, the following features are available:
- Interactive canvas for creating circular art patterns
- Real-time shape manipulation through touch gestures (drag, pinch, rotate)
- Properties panel for precise control over:
  - Rotation: the rotation applied to each layer
  - Scale: the scale applied to the whole canvas
  - Layer count: number of shapes in the pattern
  - Skew: horizontal and vertical skew transformations
  - Spread: distance between layers
  - Horizontal/Vertical positioning
  - Primitive count: number of shapes per layer
  - Shape selection with various primitive options
  - Stroke width and color customization
  - Shape transparency control
- Color panel with:
  - Custom color presets
  - Background color selection
  - Rainbow color options with hue and saturation adjustments
- Gallery for saving, loading, and renaming artworks
- Artwork sharing and import functionality with unique artwork IDs
- Thumbnail previews of saved artworks
- Randomize feature to generate unique patterns
- Position reset functionality
- Responsive and fluid user interface

## Requirements

- iPhone: Requires iOS 18.1 or later
- iPad: Requires iPadOS 18.1 or later
- Xcode 16.1 or later
- Internet connection for Firebase features (sharing, saving)

## Installation 

*(For Development)*
1. Clone the repository
2. Open the project in Xcode (Version 16.1 or later recommended)
3. Build and run the application on either the iPhone/iPad simulator, or on your own device(s).

## Usage

1. Launch the app to access the main canvas
2. Create artwork using the intuitive touch interface:
   - Drag to move the canvas
   - Pinch to zoom in/out
   - Use the blue 're-center' button in the top right to reset position and rotation
3. Access control panels from the bottom toolbar:
   - Properties panel: Adjust rotation, scale, layers, skew, spread, and more
   - Shapes panel: Select different shape types for your artwork
   - Colors panel: Customize colors, backgrounds, and rainbow effects
4. The canvas updates in real-time as you make adjustments
6. Share artwork with others using the unique artwork ID system
7. Import artwork shared by others by entering their artwork ID

## Testing

The project includes comprehensive test coverage:
- Unit tests for core functionality
- UI tests for user interactions

Run tests using:
```bash
./run-tests.sh
```
OR run the tests via Xcode!

## Project Status

Currently deployed on the AppStore. App is on version 1.2!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Developed by:
- Aditya Prakash
- Zachary Letcher
- Emmett de Bruin
- Noah Huang