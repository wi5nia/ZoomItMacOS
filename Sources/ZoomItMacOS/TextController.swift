import SwiftUI
import Cocoa

class TextController: ObservableObject {
    @Published var textEntries: [TextEntry] = []
    @Published var currentFont: NSFont = NSFont.systemFont(ofSize: 24)
    @Published var currentColor: Color = .yellow
    @Published var isTyping = false
    @Published var currentText = ""
    
    @Published var currentEntry: TextEntry?
    private var typingLocation: CGPoint = .zero
    
    struct TextEntry: Identifiable {
        let id = UUID()
        var text: String
        var position: CGPoint
        var font: NSFont
        var color: Color
        var isEditing: Bool = false
        
        init(text: String, position: CGPoint, font: NSFont, color: Color) {
            self.text = text
            self.position = position
            self.font = font
            self.color = color
        }
    }
    
    func startTyping(at point: CGPoint) {
        typingLocation = point
        isTyping = true
        currentText = ""
        
        currentEntry = TextEntry(
            text: "",
            position: point,
            font: currentFont,
            color: currentColor
        )
    }
    
    func addCharacter(_ character: String) {
        guard isTyping else { return }
        
        currentText += character
        currentEntry?.text = currentText
    }
    
    func deleteCharacter() {
        guard isTyping, !currentText.isEmpty else { return }
        
        currentText.removeLast()
        currentEntry?.text = currentText
    }
    
    func finishTyping() {
        guard isTyping, let entry = currentEntry, !entry.text.isEmpty else {
            cancelTyping()
            return
        }
        
        textEntries.append(entry)
        currentEntry = nil
        isTyping = false
        currentText = ""
    }
    
    func cancelTyping() {
        currentEntry = nil
        isTyping = false
        currentText = ""
    }
    
    func removeText(entry: TextEntry) {
        textEntries.removeAll { $0.id == entry.id }
    }
    
    func clearAllText() {
        textEntries.removeAll()
        cancelTyping()
    }
    
    func updateFont(size: CGFloat) {
        currentFont = NSFont.systemFont(ofSize: size)
    }
    
    func updateFont(name: String, size: CGFloat) {
        if let font = NSFont(name: name, size: size) {
            currentFont = font
        }
    }
}

struct TextOverlayView: View {
    @ObservedObject var textController: TextController
    @State private var clickLocation: CGPoint = .zero
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Transparent background that captures clicks
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        if !textController.isTyping {
                            textController.startTyping(at: location)
                            isTextFieldFocused = true
                        } else {
                            textController.finishTyping()
                        }
                    }
                
                // Render all text entries
                ForEach(textController.textEntries) { entry in
                    TextEntryView(entry: entry, textController: textController)
                }
                
                // Current typing entry
                if let currentEntry = textController.currentEntry {
                    TextEntryView(entry: currentEntry, textController: textController, isEditing: true)
                }
                
                // Text input toolbar
                VStack {
                    HStack {
                        TextToolbar(textController: textController)
                        Spacer()
                    }
                    .padding()
                    Spacer()
                }
                
                // Invisible text field for keyboard input
                if textController.isTyping {
                    TextField("", text: $textController.currentText)
                        .opacity(0)
                        .focused($isTextFieldFocused)
                        .onChange(of: textController.currentText) { _ in
                            // Update current entry
                            textController.currentEntry?.text = textController.currentText
                        }
                        .onSubmit {
                            textController.finishTyping()
                        }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ExitTextMode"))) { _ in
            textController.finishTyping()
        }
    }
}

struct TextEntryView: View {
    let entry: TextController.TextEntry
    let textController: TextController
    var isEditing: Bool = false
    
    var body: some View {
        Text(entry.text + (isEditing ? "|" : ""))
            .font(Font(entry.font))
            .foregroundColor(entry.color)
            .background(
                // Add outline for better visibility
                Text(entry.text + (isEditing ? "|" : ""))
                    .font(Font(entry.font))
                    .foregroundColor(.black)
                    .offset(x: 1, y: 1)
                    .opacity(0.8)
            )
            .position(entry.position)
            .onTapGesture {
                if !isEditing {
                    textController.removeText(entry: entry)
                }
            }
    }
}

struct TextToolbar: View {
    @ObservedObject var textController: TextController
    @State private var selectedFontSize: CGFloat = 24
    @State private var selectedFontName = "System"
    
    private let fontSizes: [CGFloat] = [12, 16, 20, 24, 32, 48, 64, 72]
    private let fontNames = ["System", "Helvetica", "Times", "Courier", "Arial", "Georgia"]
    
    var body: some View {
        HStack(spacing: 8) {
            // Font name picker
            Picker("Font", selection: $selectedFontName) {
                ForEach(fontNames, id: \.self) { fontName in
                    Text(fontName).tag(fontName)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 100)
            .onChange(of: selectedFontName) { newValue in
                updateFont()
            }
            
            // Font size picker
            Picker("Size", selection: $selectedFontSize) {
                ForEach(fontSizes, id: \.self) { size in
                    Text("\(Int(size))").tag(size)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 60)
            .onChange(of: selectedFontSize) { newValue in
                updateFont()
            }
            
            Divider()
                .frame(height: 20)
            
            // Color picker
            ColorPicker("", selection: $textController.currentColor)
                .frame(width: 30, height: 30)
            
            Divider()
                .frame(height: 20)
            
            // Action buttons
            Button("Clear All") {
                textController.clearAllText()
            }
            .buttonStyle(.bordered)
            
            if textController.isTyping {
                Button("Finish") {
                    textController.finishTyping()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    textController.cancelTyping()
                }
                .buttonStyle(.bordered)
            }
            
            Button("Done") {
                textController.finishTyping()
                NotificationCenter.default.post(name: NSNotification.Name("ExitTextMode"), object: nil)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            selectedFontSize = textController.currentFont.pointSize
        }
    }
    
    private func updateFont() {
        if selectedFontName == "System" {
            textController.updateFont(size: selectedFontSize)
        } else {
            textController.updateFont(name: selectedFontName, size: selectedFontSize)
        }
    }
}

// MARK: - Demo Type functionality (inspired by original ZoomIt)

class DemoTypeController: ObservableObject {
    @Published var scripts: [DemoScript] = []
    @Published var isPlaying = false
    @Published var currentScript: DemoScript?
    @Published var typingSpeed: TimeInterval = 0.1
    
    private var typingTimer: Timer?
    private var currentCharacterIndex = 0
    
    struct DemoScript: Identifiable {
        let id = UUID()
        var name: String
        var content: String
        var position: CGPoint
        var font: NSFont
        var color: Color
        
        init(name: String, content: String, position: CGPoint = .zero, font: NSFont = NSFont.systemFont(ofSize: 24), color: Color = .yellow) {
            self.name = name
            self.content = content
            self.position = position
            self.font = font
            self.color = color
        }
    }
    
    func loadScript(from url: URL) throws {
        let content = try String(contentsOf: url)
        let script = DemoScript(
            name: url.lastPathComponent,
            content: content
        )
        scripts.append(script)
    }
    
    func playScript(_ script: DemoScript, at position: CGPoint) {
        guard !isPlaying else { return }
        
        currentScript = script
        currentCharacterIndex = 0
        isPlaying = true
        
        startTyping(at: position)
    }
    
    func stopPlaying() {
        typingTimer?.invalidate()
        typingTimer = nil
        isPlaying = false
        currentScript = nil
        currentCharacterIndex = 0
    }
    
    private func startTyping(at position: CGPoint) {
        guard currentScript != nil else { return }
        
        typingTimer = Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { [weak self] timer in
            self?.typeNextCharacter()
        }
    }
    
    private func typeNextCharacter() {
        guard let script = currentScript else {
            stopPlaying()
            return
        }
        
        if currentCharacterIndex >= script.content.count {
            stopPlaying()
            return
        }
        
        let index = script.content.index(script.content.startIndex, offsetBy: currentCharacterIndex)
        let character = String(script.content[index])
        
        // Here you would send the character to the text controller or display system
        // For now, we'll just print it
        print("Typing: \(character)")
        
        currentCharacterIndex += 1
    }
}
