import SwiftUI
import AVKit
import PhotosUI
import UniformTypeIdentifiers
import MobileVLCKit

let violet = Color(red: 0.71, green: 0.48, blue: 1.0)
let violetDeep = Color(red: 0.23, green: 0.14, blue: 0.40)

@main
struct TimePlayerApp: App {
    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    var body: some Scene {
        WindowGroup { RootView().preferredColorScheme(.dark) }
    }
}

func fmt(_ s: Double) -> String {
    let n = Int(max(0, s.isFinite ? s : 0))
    return String(format: "%d:%02d:%02d", n / 3600, n % 3600 / 60, n % 60)
}

// MARK: - Buzlu cam
struct Frost: ViewModifier {
    var radius: CGFloat
    func body(content: Content) -> some View {
        content.background(
            ZStack {
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient(colors: [violet.opacity(0.30), violetDeep.opacity(0.30)],
                                         startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.08)],
                                                 startPoint: .top, endPoint: .bottom), lineWidth: 1)
            }
        )
    }
}
extension View {
    func frost(_ r: CGFloat) -> some View { modifier(Frost(radius: r)) }
}

// MARK: - Logo
struct Logo: View {
    var size: CGFloat
    var body: some View {
        ZStack {
            LinearGradient(colors: [violetDeep, Color(red: 0.03, green: 0.02, blue: 0.05)],
                           startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [.white.opacity(0.22), .clear], startPoint: .top, endPoint: .center)
            ForEach(0..<60, id: \.self) { i in
                Capsule()
                    .fill(i < 15 ? Color(red: 0.75, green: 0.55, blue: 1.0) : Color.white.opacity(0.3))
                    .frame(width: size * 0.012, height: size * 0.07)
                    .offset(y: -size * 0.33)
                    .rotationEffect(.degrees(Double(i) * 6))
            }
            Circle().fill(Color.white.opacity(0.12))
                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
                .frame(width: size * 0.4)
            Image(systemName: "play.fill")
                .font(.system(size: size * 0.2)).foregroundStyle(.white)
                .offset(x: size * 0.015)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
            .stroke(Color.white.opacity(0.14), lineWidth: 1))
        .shadow(color: violet.opacity(0.35), radius: 24, y: 12)
    }
}

// MARK: - Fotoğraflar'dan video alma
struct Movie: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { m in
            SentTransferredFile(m.url)
        } importing: { received in
            let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let dest = dir.appendingPathComponent(received.file.lastPathComponent)
            try FileManager.default.copyItem(at: received.file, to: dest)
            return Movie(url: dest)
        }
    }
}

// MARK: - Ana ekran
struct RootView: View {
    @State private var url: URL?
    @State private var item: PhotosPickerItem?
    @State private var importing = false
    @State private var loading = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let url {
                PlayerScreen(url: url) { self.url = nil }.id(url)
            } else {
                home
            }
        }
        .fileImporter(isPresented: $importing,
                      allowedContentTypes: [.movie, .video, .audiovisualContent, .data]) { r in
            if case .success(let u) = r {
                _ = u.startAccessingSecurityScopedResource()
                url = u
            }
        }
        .onChange(of: item) { newItem in
            guard let newItem else { return }
            loading = true
            Task {
                if let m = try? await newItem.loadTransferable(type: Movie.self) { url = m.url }
                loading = false
                item = nil
            }
        }
    }

    var home: some View {
        ZStack {
            Color.black
            Circle().fill(violet.opacity(0.45)).frame(width: 360).blur(radius: 90).offset(x: -120, y: -300)
            Circle().fill(Color(red: 0.37, green: 0.18, blue: 0.82).opacity(0.4))
                .frame(width: 320).blur(radius: 90).offset(x: 150, y: -40)
            Circle().fill(Color(red: 0.75, green: 0.35, blue: 1).opacity(0.3))
                .frame(width: 300).blur(radius: 90).offset(x: -80, y: 340)
            VStack(spacing: 0) {
                Spacer()
                Logo(size: 120)
                Text("TimePlayer").font(.system(size: 34, weight: .bold))
                    .tracking(-0.6).padding(.top, 22).padding(.bottom, 6)
                Text("Her videoyu aç, saniyesine kadar sar.\nHiçbir şey internete yüklenmez.")
                    .font(.system(size: 15)).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
                if loading {
                    ProgressView().padding(.bottom, 40)
                } else {
                    PhotosPicker(selection: $item, matching: .videos) {
                        Text("Fotoğraflardan seç").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(Capsule().fill(Color.white))
                    }
                    Button { importing = true } label: {
                        Text("Dosyalardan seç").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .frost(26)
                    }.padding(.top, 10)
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 10)
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottom) { Color.clear.frame(height: 0) }
    }
}

// MARK: - Küçük resimler
final class ThumbStore: ObservableObject {
    @Published var images: [Int: UIImage] = [:]
    private let gen: AVAssetImageGenerator
    private var loading = Set<Int>()

    init(asset: AVAsset) {
        gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 240, height: 135)
        gen.requestedTimeToleranceBefore = .positiveInfinity
        gen.requestedTimeToleranceAfter = .positiveInfinity
    }

    func load(_ i: Int) {
        guard images[i] == nil, !loading.contains(i) else { return }
        loading.insert(i)
        Task {
            let t = CMTime(seconds: Double(i) * 10, preferredTimescale: 600)
            if let r = try? await gen.image(at: t) {
                let img = UIImage(cgImage: r.image)
                await MainActor.run { self.images[i] = img }
            }
        }
    }
}

// MARK: - Oynatıcı modeli (VLC motoru)
final class PlayerModel: NSObject, ObservableObject, VLCMediaPlayerDelegate {
    let player = VLCMediaPlayer()
    let thumbs: ThumbStore
    let name: String
    @Published var time = 0.0
    @Published var duration = 0.0
    @Published var isPlaying = false
    @Published var fast = false
    @Published var scrubbing = false
    private var wasPlaying = false
    private var started = false
    private var lastSeek = Date.distantPast
    private var ignoreUntil = Date.distantPast

    init(url: URL) {
        thumbs = ThumbStore(asset: AVURLAsset(url: url))
        name = url.lastPathComponent
        super.init()
        player.media = VLCMedia(url: url)
        player.delegate = self
    }

    deinit {
        player.delegate = nil
        player.stop()
    }

    func attach(_ view: UIView) {
        player.drawable = view
        if !started {
            started = true
            player.play()
            isPlaying = true
        }
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let len = Double(self.player.media?.length.intValue ?? 0) / 1000
            if len > 0 && len != self.duration { self.duration = len }
            guard !self.scrubbing, Date() > self.ignoreUntil else { return }
            self.time = Swift.max(0, Double(self.player.time.intValue) / 1000)
        }
    }

    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch self.player.state {
            case .playing: self.isPlaying = true
            case .paused, .stopped, .ended, .error: self.isPlaying = false
            default: break
            }
        }
    }

    func play() {
        if duration > 0 && time >= duration - 0.3 {
            player.stop()
            time = 0
        }
        player.play()
        player.rate = fast ? 2 : 1
        isPlaying = true
    }

    func toggle() {
        if isPlaying { player.pause(); isPlaying = false } else { play() }
    }

    func setFast(_ on: Bool) {
        guard on != fast else { return }
        fast = on
        player.rate = on ? 2 : 1
        if on && !isPlaying { play() }
    }

    func jump(_ s: Double) {
        let top = duration > 0 ? duration : .greatestFiniteMagnitude
        time = Swift.min(Swift.max(0, time + s), top)
        ignoreUntil = Date().addingTimeInterval(0.4)
        seek(time, force: true)
    }

    func beginScrub() {
        wasPlaying = isPlaying
        if isPlaying { player.pause(); isPlaying = false }
        scrubbing = true
    }

    func scrub(_ d: Double) {
        let top = duration > 0 ? duration : .greatestFiniteMagnitude
        time = Swift.min(Swift.max(0, time + d), top)
        seek(time, force: false)
    }

    func endScrub() {
        seek(time, force: true)
        ignoreUntil = Date().addingTimeInterval(0.4)
        scrubbing = false
        if wasPlaying { play() }
    }

    private func seek(_ s: Double, force: Bool) {
        guard force || Date().timeIntervalSince(lastSeek) > 0.05 else { return }
        lastSeek = Date()
        player.time = VLCTime(int: Int32(s * 1000))
    }
}

// MARK: - Video katmanı
struct VideoLayer: UIViewRepresentable {
    let model: PlayerModel
    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .black
        DispatchQueue.main.async { model.attach(v) }
        return v
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct Press: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Film şeridi
struct ThumbView: View {
    @ObservedObject var store: ThumbStore
    let index: Int
    var body: some View {
        ZStack {
            Color(white: 0.1)
            if let img = store.images[index] {
                Image(uiImage: img).resizable().scaledToFill()
            }
        }
        .clipped()
        .overlay(Rectangle().fill(Color.black).frame(width: 1), alignment: .trailing)
        .onAppear { store.load(index) }
    }
}

struct Filmstrip: View {
    @ObservedObject var m: PlayerModel
    @State private var lastX: CGFloat = 0
    @State private var hint = ""
    let pps = 9.95
    let sec = 10.0

    var fade: LinearGradient {
        LinearGradient(stops: [
            .init(color: .clear, location: 0),
            .init(color: .black, location: 0.1),
            .init(color: .black, location: 0.9),
            .init(color: .clear, location: 1)
        ], startPoint: .leading, endPoint: .trailing)
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let w = geo.size.width
                let half = w / 2 / pps
                let last = max(0, Int((max(m.duration, 0.1) - 0.05) / sec))
                let a = min(last, max(0, Int(floor((m.time - half) / sec))))
                let b = min(last, max(a, Int(floor((m.time + half) / sec))))
                ZStack(alignment: .leading) {
                    ZStack(alignment: .leading) {
                        Color.black.opacity(0.5)
                        ForEach(a...b, id: \.self) { i in
                            ThumbView(store: m.thumbs, index: i)
                                .frame(width: sec * pps, height: 56)
                                .offset(x: w / 2 + (Double(i) * sec - m.time) * pps)
                        }
                    }.mask(fade)
                    RoundedRectangle(cornerRadius: 2).fill(Color.white)
                        .frame(width: 4, height: 56)
                        .shadow(color: .black.opacity(0.5), radius: 4)
                        .offset(x: w / 2 - 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1).allowsHitTesting(false))
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            if !m.scrubbing { m.beginScrub(); lastX = 0 }
                            let up = max(0, -v.translation.height)
                            let f = up > 110 ? 0.1 : (up > 40 ? 0.35 : 1.0)
                            hint = f == 1 ? "" : (f == 0.35 ? "Hassas sarma: ⅓ hız" : "Çok hassas sarma: 1/10 hız")
                            let dx = v.translation.width - lastX
                            lastX = v.translation.width
                            m.scrub(-Double(dx) * f / pps)
                        }
                        .onEnded { _ in hint = ""; m.endScrub() }
                )
            }.frame(height: 56)
            Text(hint).font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white).frame(height: 22)
        }
    }
}

// MARK: - Oynatıcı ekranı
struct PlayerScreen: View {
    @StateObject private var m: PlayerModel
    let onClose: () -> Void
    @State private var showUI = true
    @State private var flash: String?
    @State private var flashID = 0

    init(url: URL, onClose: @escaping () -> Void) {
        _m = StateObject(wrappedValue: PlayerModel(url: url))
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            stage
            VStack(spacing: 0) {
                topBar.padding(14)
                Spacer()
                if showUI {
                    controls
                        .padding(.horizontal, 10).padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.easeOut(duration: 0.28), value: showUI)
    }

    var stage: some View {
        ZStack {
            VideoLayer(model: m).ignoresSafeArea()
            if let f = flash {
                Text(f).font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .frost(22)
                    .transition(.opacity)
            }
        }
        .background(Color.black)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { m.jump(5); say("+5 sn") }
        .onTapGesture { showUI.toggle() }
        .onLongPressGesture(minimumDuration: 0.35, maximumDistance: 60, perform: {
            m.setFast(true)
        }, onPressingChanged: { pressing in
            if !pressing { m.setFast(false) }
        })
    }

    var topBar: some View {
        ZStack {
            Text(m.name).font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75)).lineLimit(1)
                .padding(.horizontal, 90)
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white).frame(width: 34, height: 34)
                        .frost(17)
                }
                Spacer()
                if m.fast {
                    Text("2×").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 11).padding(.vertical, 6)
                        .background(Capsule().fill(Color.white))
                }
            }
        }
    }

    var controls: some View {
        VStack(spacing: 0) {
            HStack {
                Text(fmt(m.time)).fontWeight(.semibold)
                Spacer()
                Text(fmt(m.duration)).foregroundStyle(.secondary)
            }
            .font(.system(size: 13).monospacedDigit())
            .padding(.horizontal, 24).padding(.bottom, 10)
            Filmstrip(m: m).padding(.horizontal, 16)
            HStack(spacing: 4) {
                ForEach([-60, -30, -5], id: \.self) { skip($0) }
                Button { m.toggle() } label: {
                    Image(systemName: m.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24)).foregroundStyle(.black)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.white))
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(Press()).padding(.horizontal, 6)
                ForEach([5, 30, 60], id: \.self) { skip($0) }
            }
            .padding(.top, 2)
        }
        .padding(.top, 16).padding(.bottom, 14)
        .frost(34)
    }

    func skip(_ s: Int) -> some View {
        Button {
            m.jump(Double(s))
            say(s > 0 ? "+\(s) sn" : "−\(-s) sn")
        } label: {
            Text(s > 0 ? "+\(s)" : "−\(-s)")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(violet.opacity(0.22)))
                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
        }
        .buttonStyle(Press())
    }

    func say(_ s: String) {
        flash = s
        flashID += 1
        let id = flashID
        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            if id == flashID { flash = nil }
        }
    }
}
