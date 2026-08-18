import AppKit
import CoreImage
import Foundation
import Vision

enum ExtractionError: Error, CustomStringConvertible {
    case invalidArguments
    case cannotLoadImage(String)
    case cannotCreateCGImage(String)
    case noForegroundInstances
    case cannotRenderOutput(String)

    var description: String {
        switch self {
        case .invalidArguments:
            return "Usage: extract_foreground_instances.swift <input-image> <output-directory>"
        case .cannotLoadImage(let path):
            return "Cannot load image: \(path)"
        case .cannotCreateCGImage(let path):
            return "Cannot create CGImage from: \(path)"
        case .noForegroundInstances:
            return "Vision did not find any foreground instances."
        case .cannotRenderOutput(let path):
            return "Cannot render output: \(path)"
        }
    }
}

func writePixelBuffer(_ pixelBuffer: CVPixelBuffer, to url: URL, context: CIContext) throws {
    let image = CIImage(cvPixelBuffer: pixelBuffer)
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let png = context.pngRepresentation(
              of: image,
              format: .RGBA8,
              colorSpace: colorSpace,
              options: [:]
          ) else {
        throw ExtractionError.cannotRenderOutput(url.path)
    }
    try png.write(to: url)
}

do {
    guard CommandLine.arguments.count == 3 else {
        throw ExtractionError.invalidArguments
    }

    let inputPath = CommandLine.arguments[1]
    let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
    try FileManager.default.createDirectory(
        at: outputDirectory,
        withIntermediateDirectories: true
    )

    guard let sourceImage = NSImage(contentsOfFile: inputPath) else {
        throw ExtractionError.cannotLoadImage(inputPath)
    }
    guard let sourceCGImage = sourceImage.cgImage(
        forProposedRect: nil,
        context: nil,
        hints: nil
    ) else {
        throw ExtractionError.cannotCreateCGImage(inputPath)
    }

    let request = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(cgImage: sourceCGImage, options: [:])
    try handler.perform([request])

    guard let observation = request.results?.first,
          !observation.allInstances.isEmpty else {
        throw ExtractionError.noForegroundInstances
    }

    let context = CIContext(options: [.cacheIntermediates: false])
    let combined = try observation.generateMaskedImage(
        ofInstances: observation.allInstances,
        from: handler,
        croppedToInstancesExtent: false
    )
    try writePixelBuffer(
        combined,
        to: outputDirectory.appendingPathComponent("foreground-all.png"),
        context: context
    )

    for instance in observation.allInstances {
        let index = IndexSet(integer: instance)
        let masked = try observation.generateMaskedImage(
            ofInstances: index,
            from: handler,
            croppedToInstancesExtent: false
        )
        try writePixelBuffer(
            masked,
            to: outputDirectory.appendingPathComponent(
                String(format: "foreground-instance-%02d.png", instance)
            ),
            context: context
        )
    }

    print("instances=\(observation.allInstances.map(String.init).joined(separator: ","))")
    print("output=\(outputDirectory.path)")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
