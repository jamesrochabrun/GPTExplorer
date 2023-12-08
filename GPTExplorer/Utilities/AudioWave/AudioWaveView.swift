//
//  AudioWaveView.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/6/23.
//

import SwiftUI

final class AudioWave: ObservableObject {
   
   struct Curve: Equatable {
      
      var power: Double
      var A: Double
      var k: Double
      var t: Double
      
      static func random(withPower power: Double) -> Curve {
         
         return Curve(
            power: power,
            A: Double.random(in: 0.1...1.0),
            k: Double.random(in: 0.6...0.9),
            t: Double.random(in: -1.0...4.0)
         )
      }
   }
   
   struct Wave: Equatable {
      
      var power: Double
      var curves: [Curve]
      var useCurves: Int
      
      static func random(withPower power: Double) -> Wave {
         let numCurves = Int.random(in: 2 ... 4)
         return Wave(
            power: power,
            curves: (0..<4).map { _ in
               return Curve.random(withPower: power)
            },
            useCurves: numCurves
         )
      }
   }
   
   var waves: [Wave]
   
   init(numWaves: Int, power: Double) {
      waves = [Wave]()
      for _ in 0..<numWaves {
         waves.append(.random(withPower: power))
      }
   }
}

// This part is temporary because you cannot create an
// array of animatable data

extension AudioWave.Wave: Animatable {
   
   typealias AnimatableData = AnimatablePair<
      AnimatablePair<
         AnimatablePair<
            AnimatablePair<Double, Double>,
            AnimatablePair<Double, Double>
         >,
         AnimatablePair<
            AnimatablePair<Double, Double>,
            AnimatablePair<Double, Double>
         >
      >,
      AnimatablePair<
         AnimatablePair<
            AnimatablePair<Double, Double>,
            AnimatablePair<Double, Double>
         >,
         AnimatablePair<
            AnimatablePair<Double, Double>,
            AnimatablePair<
               AnimatablePair<Double, Double>,
               AnimatablePair<Double, Double>
            >
         >
      >
   >
   
   var animatableData: AnimatableData {
      
      get {
         .init(
            .init(
               .init(
                  .init(curves[0].A, curves[0].power),
                  .init(curves[0].k, curves[0].t)),
               .init(
                  .init(curves[1].A, curves[1].power),
                  .init(curves[1].k, curves[1].t))),
            .init(
               .init(
                  .init(curves[2].A, curves[2].power),
                  .init(curves[2].k, curves[2].t)),
               .init(
                  .init(curves[3].A, curves[3].power),
                  .init(
                     .init(curves[3].k, curves[3].t),
                     .init(power, .zero)))))
      }
      
      set {
         curves[0].A = newValue.first.first.first.first
         curves[0].power = newValue.first.first.first.second
         curves[0].k = newValue.first.first.second.first
         curves[0].t = newValue.first.first.second.second
         
         curves[1].A = newValue.first.second.first.first
         curves[1].power = newValue.first.second.first.second
         curves[1].k = newValue.first.second.second.first
         curves[1].t = newValue.first.second.second.second
         
         curves[2].A = newValue.second.first.first.first
         curves[2].power = newValue.second.first.first.second
         curves[2].k = newValue.second.first.second.first
         curves[2].t = newValue.second.first.second.second
         
         curves[3].A = newValue.second.second.first.first
         curves[3].power = newValue.second.second.first.second
         curves[3].k = newValue.second.second.second.first.first
         curves[3].t = newValue.second.second.second.first.second
         
         power = newValue.second.second.second.second.first
      }
   }
}


struct AudioWaveView: View {
   
   var audioWave: AudioWave!
   var _colors: [Color]!
   var _supportLineColor: Color!
   var _power: Double!
   
   @Environment (\.colorScheme) var colorScheme
   @State private var animated: Bool = false
   init() {
      
      self._power = 0.0
      self._colors =  colorScheme == .light ? [ThemeColor.brandSecondaryColor] :
         [
         .primary
//         ThemeColor.brandColor,
//         ThemeColor.brandSecondaryColor
//         // Red
//         Color(red: (173 / 255), green: (57 / 255), blue: (76 / 255)),
//         // Green
//         Color(red: (48 / 255), green: (220 / 255), blue: (155 / 255)),
//         // Blue
//         Color(red: (25 / 255), green: (122 / 255), blue: (255 / 255))
      ]
      self._supportLineColor = Color(.white)
      // Initialize model
      self.audioWave = AudioWave(numWaves: self._colors.count, power: self._power)
   }
   
   func colors(colors: [Color]) -> Self {
      var this = self;
      if (colors.count != this._colors.count) {
         this.audioWave = AudioWave(numWaves: colors.count, power: this._power)
      }
      this._colors = colors
      return this
   }
   
   func power(power: Double) -> Self {
      var this = self;
      this.audioWave = AudioWave(numWaves: self._colors.count, power: power)
      return this
   }
   
   func supportLineColor(color: Color) -> Self {
      var this = self;
      this._supportLineColor = color
      return this
      
   }
   
   var body: some View {
      GeometryReader { geometry in
         ZStack {
            SupportLine(color: self._supportLineColor)
            ForEach(0..<self._colors.count, id: \.self) { i in
               WaveView(wave: self.audioWave.waves[i], color: self._colors[i])
            }
         }
         .blendMode(.lighten)
         .drawingGroup()
      }
   }
   
}

struct SupportLine: View {
   
   var color: Color!
   var body: some View {
      GeometryReader { geometry in
         Path { path in
            let centerY = geometry.size.height / 2.0
            path.move(to: CGPoint(x: 0, y: centerY))
            path.addLines([
               CGPoint(x: 0, y: centerY),
               CGPoint(x: geometry.size.width, y: centerY)
            ])
         }
         .stroke(self.color, lineWidth: 2)
         .opacity(0.5)
      }
   }
}

private struct WaveGeometry {
   
   var wave: AudioWave.Wave
   var points: [CGPoint]
   var origin: CGPoint
   
   init(_ wave: AudioWave.Wave, in rect: CGRect) {
      
      self.wave = wave
      self.points = [CGPoint]()
      self.origin = CGPoint(x: 0, y: rect.midY)
      
      let xPoints = Array(stride(from: -rect.midX, to: rect.midX, by: 1.0))
      
      var coordinates = [[Double]](repeating: [0.0, 0.0], count: xPoints.count)
      
      for i in 0..<self.wave.useCurves {
         let A = self.wave.curves[i].A * Double(rect.midY) * self.wave.power
         var j = 0
         for graphX in xPoints {
            let graphScaledX = graphX / (rect.midX / 9.0)
            let x = rect.midX + graphX
            let y = self.attn(x: Double(graphScaledX), A: A, k: self.wave.curves[i].k, t: self.wave.curves[i].t) + Double(self.origin.y)
            coordinates[j] = [Double(x), max(coordinates[j][1], y)]
            j += 1
         }
      }
      
      // Create inverse points
      coordinates += coordinates.map({ (coord) -> [Double] in
         return [coord[0], ((coord[1] - Double(rect.midY)) * -1) + Double(rect.midY)]
      })
      
      for coord in coordinates {
         self.points.append(CGPoint(x: coord[0], y: coord[1]))
      }
      
   }
   
   private func sine(x: Double, A: Double, k: Double, t: Double) -> Double {
       A * sin((k * x) - t)
   }
   
   private func g(x: Double, t: Double, K: Double, k: Double) -> Double {
       pow(K / (K + pow((k * x) - t, 2)), K)
   }
   
   private func attn(x: Double, A: Double, k: Double, t: Double) -> Double {
       abs(sine(x: x, A: A, k: k, t: t) * g(x: x, t: t - (Double.pi / 2), K: 4, k: k))
   }
}

struct WaveShape: Shape {
   
   var wave: AudioWave.Wave
   
   func path(in rect: CGRect) -> Path {
      
      let geometry = WaveGeometry(wave, in: rect)
      var path = Path()
      path.move(to: geometry.origin)
      path.addLines(geometry.points)
      return path
   }
   
   var animatableData: AudioWave.Wave.AnimatableData {
      get {
         return wave.animatableData
      }
      set {
         wave.animatableData = newValue
      }
   }
}

struct WaveView: View {
   
   var wave: AudioWave.Wave
   var color: Color
   
   var body: some View {
      WaveShape(wave: wave)
         .fill(color)
   }
}
