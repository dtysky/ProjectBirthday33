#!/usr/bin/env swift

import AVFoundation
import AudioToolbox
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("usage: render_midi.swift INPUT.mid OUTPUT.wav\n", stderr)
    exit(2)
}

let midiURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let soundBankURL = URL(
    fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls"
)

let engine = AVAudioEngine()
let sampler = AVAudioUnitSampler()
let reverb = AVAudioUnitReverb()
reverb.loadFactoryPreset(.mediumRoom)
reverb.wetDryMix = 9

engine.attach(sampler)
engine.attach(reverb)
engine.connect(sampler, to: reverb, format: nil)
engine.connect(reverb, to: engine.mainMixerNode, format: nil)

try sampler.loadSoundBankInstrument(
    at: soundBankURL,
    program: 0,
    bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
    bankLSB: UInt8(kAUSampler_DefaultBankLSB)
)

let sequencer = AVAudioSequencer(audioEngine: engine)
try sequencer.load(from: midiURL, options: [])
sequencer.prepareToPlay()

guard let renderFormat = AVAudioFormat(
    commonFormat: .pcmFormatFloat32,
    sampleRate: 44_100,
    channels: 2,
    interleaved: false
) else {
    throw NSError(domain: "render_midi", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot create render format"])
}

let maximumFrameCount: AVAudioFrameCount = 4096
try engine.enableManualRenderingMode(
    .offline,
    format: renderFormat,
    maximumFrameCount: maximumFrameCount
)
engine.prepare()
try engine.start()

sequencer.currentPositionInBeats = 0
try sequencer.start()

let sequenceLength = sequencer.tracks.map(\.lengthInSeconds).max() ?? 0
let renderLength = sequenceLength + 4.0
let totalFrames = AVAudioFramePosition(renderLength * renderFormat.sampleRate)
let outputFile = try AVAudioFile(forWriting: outputURL, settings: renderFormat.settings)
guard let buffer = AVAudioPCMBuffer(
    pcmFormat: engine.manualRenderingFormat,
    frameCapacity: maximumFrameCount
) else {
    throw NSError(domain: "render_midi", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot allocate render buffer"])
}

while engine.manualRenderingSampleTime < totalFrames {
    let remaining = totalFrames - engine.manualRenderingSampleTime
    let frames = min(AVAudioFrameCount(remaining), maximumFrameCount)
    let status = try engine.renderOffline(frames, to: buffer)
    switch status {
    case .success:
        try outputFile.write(from: buffer)
    case .insufficientDataFromInputNode, .cannotDoInCurrentContext:
        continue
    case .error:
        throw NSError(domain: "render_midi", code: 3, userInfo: [NSLocalizedDescriptionKey: "Offline render failed"])
    @unknown default:
        throw NSError(domain: "render_midi", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown render status"])
    }
}

sequencer.stop()
engine.stop()
print(String(format: "rendered %@ (%.2f seconds)", outputURL.path, renderLength))
