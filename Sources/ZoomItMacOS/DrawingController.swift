import SwiftUI
import Cocoa

class DrawingController: ObservableObject {
    @Published var currentTool: DrawingTool = .pen
    @Published var currentColor: Color = .red
    @Published var strokeWidth: CGFloat = 3.0
    @Published var drawingPaths: [DrawingPath] = []
    @Published var isDrawing = false
    
    @Published var currentPath: DrawingPath?
    
    enum DrawingTool {
        case pen
        case highlighter
        case line
        case rectangle
        case circle
        case arrow
        case eraser
    }
    
    struct DrawingPath: Identifiable {
        let id = UUID()
        var points: [CGPoint] = []
        let tool: DrawingTool
        let color: Color
        let strokeWidth: CGFloat
        let startPoint: CGPoint?
        let endPoint: CGPoint?
        
        init(tool: DrawingTool, color: Color, strokeWidth: CGFloat, startPoint: CGPoint? = nil) {
            self.tool = tool
            self.color = color
            self.strokeWidth = strokeWidth
            self.startPoint = startPoint
            self.endPoint = nil
        }
    }
    
    func startDrawing(at point: CGPoint) {
        isDrawing = true
        currentPath = DrawingPath(
            tool: currentTool,
            color: currentColor,
            strokeWidth: strokeWidth,
            startPoint: point
        )
        
        if currentTool == .pen || currentTool == .highlighter {
            currentPath?.points.append(point)
        }
    }
    
    func continueDrawing(to point: CGPoint) {
        guard isDrawing, var path = currentPath else { return }
        
        switch currentTool {
        case .pen, .highlighter:
            path.points.append(point)
        case .line, .rectangle, .circle, .arrow:
            // For shapes, we'll draw from start to current point
            break
        case .eraser:
            // Handle eraser functionality
            eraseAt(point: point)
        }
        
        currentPath = path
    }
    
    func endDrawing(at point: CGPoint) {
        guard isDrawing, var path = currentPath else { return }
        
        switch currentTool {
        case .pen, .highlighter:
            path.points.append(point)
        case .line, .rectangle, .circle, .arrow:
            // Set end point for shapes
            var finalPath = path
            finalPath.points = [path.startPoint ?? .zero, point]
            path = finalPath
        case .eraser:
            // Eraser doesn't create persistent paths
            break
        }
        
        drawingPaths.append(path)
        currentPath = nil
        isDrawing = false
    }
    
    private func eraseAt(point: CGPoint) {
        let eraseRadius: CGFloat = strokeWidth * 2
        
        drawingPaths.removeAll { path in
            return path.points.contains { pathPoint in
                let distance = sqrt(pow(pathPoint.x - point.x, 2) + pow(pathPoint.y - point.y, 2))
                return distance <= eraseRadius
            }
        }
    }
    
    func clearAll() {
        drawingPaths.removeAll()
        currentPath = nil
        isDrawing = false
    }
    
    func undo() {
        if !drawingPaths.isEmpty {
            drawingPaths.removeLast()
        }
    }
    
    func setTool(_ tool: DrawingTool) {
        currentTool = tool
        
        // Adjust default stroke width for different tools
        switch tool {
        case .pen:
            strokeWidth = 3.0
        case .highlighter:
            strokeWidth = 8.0
        case .line, .arrow:
            strokeWidth = 2.0
        case .rectangle, .circle:
            strokeWidth = 2.0
        case .eraser:
            strokeWidth = 10.0
        }
    }
}

struct DrawingOverlayView: View {
    @ObservedObject var drawingController: DrawingController
    @State private var currentPoint: CGPoint = .zero
    @State private var startPoint: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Transparent background that captures touches
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let point = value.location
                                
                                if !drawingController.isDrawing {
                                    startPoint = point
                                    drawingController.startDrawing(at: point)
                                } else {
                                    drawingController.continueDrawing(to: point)
                                }
                                currentPoint = point
                            }
                            .onEnded { value in
                                drawingController.endDrawing(at: value.location)
                            }
                    )
                
                // Render all drawing paths
                ForEach(drawingController.drawingPaths) { path in
                    DrawingPathView(path: path)
                }
                
                // Render current path being drawn
                if let currentPath = drawingController.currentPath {
                    DrawingPathView(path: currentPath, isActive: true, currentPoint: currentPoint, startPoint: startPoint)
                }
                
                // Drawing toolbar
                VStack {
                    HStack {
                        DrawingToolbar(drawingController: drawingController)
                        Spacer()
                    }
                    .padding()
                    Spacer()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ExitDrawingMode"))) { _ in
            // Handle exit signal
        }
    }
}

struct DrawingPathView: View {
    let path: DrawingController.DrawingPath
    var isActive: Bool = false
    var currentPoint: CGPoint = .zero
    var startPoint: CGPoint = .zero
    
    var body: some View {
        switch path.tool {
        case .pen, .highlighter:
            Path { p in
                if !path.points.isEmpty {
                    p.move(to: path.points[0])
                    for point in path.points.dropFirst() {
                        p.addLine(to: point)
                    }
                }
            }
            .stroke(
                path.color,
                style: StrokeStyle(
                    lineWidth: path.strokeWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .opacity(path.tool == .highlighter ? 0.6 : 1.0)
            
        case .line:
            if let start = path.startPoint {
                let end = isActive ? currentPoint : (path.points.last ?? start)
                Path { p in
                    p.move(to: start)
                    p.addLine(to: end)
                }
                .stroke(path.color, lineWidth: path.strokeWidth)
            }
            
        case .rectangle:
            if let start = path.startPoint {
                let end = isActive ? currentPoint : (path.points.last ?? start)
                let rect = CGRect(
                    x: min(start.x, end.x),
                    y: min(start.y, end.y),
                    width: abs(end.x - start.x),
                    height: abs(end.y - start.y)
                )
                
                Path { p in
                    p.addRect(rect)
                }
                .stroke(path.color, lineWidth: path.strokeWidth)
            }
            
        case .circle:
            if let start = path.startPoint {
                let end = isActive ? currentPoint : (path.points.last ?? start)
                let radius = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2))
                
                Path { p in
                    p.addEllipse(in: CGRect(
                        x: start.x - radius,
                        y: start.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    ))
                }
                .stroke(path.color, lineWidth: path.strokeWidth)
            }
            
        case .arrow:
            if let start = path.startPoint {
                let end = isActive ? currentPoint : (path.points.last ?? start)
                ArrowShape(from: start, to: end)
                    .stroke(path.color, lineWidth: path.strokeWidth)
            }
            
        case .eraser:
            // Eraser doesn't render, it removes content
            EmptyView()
        }
    }
}

struct ArrowShape: Shape {
    let from: CGPoint
    let to: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Draw line
        path.move(to: from)
        path.addLine(to: to)
        
        // Calculate arrow head
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLength: CGFloat = 15
        let arrowAngle: CGFloat = .pi / 6
        
        let arrowPoint1 = CGPoint(
            x: to.x - arrowLength * cos(angle - arrowAngle),
            y: to.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: to.x - arrowLength * cos(angle + arrowAngle),
            y: to.y - arrowLength * sin(angle + arrowAngle)
        )
        
        // Draw arrow head
        path.move(to: to)
        path.addLine(to: arrowPoint1)
        path.move(to: to)
        path.addLine(to: arrowPoint2)
        
        return path
    }
}

struct DrawingToolbar: View {
    @ObservedObject var drawingController: DrawingController
    
    var body: some View {
        HStack(spacing: 8) {
            // Tool buttons
            ToolButton(
                icon: "pencil",
                isSelected: drawingController.currentTool == .pen,
                action: { drawingController.setTool(.pen) }
            )
            
            ToolButton(
                icon: "highlighter",
                isSelected: drawingController.currentTool == .highlighter,
                action: { drawingController.setTool(.highlighter) }
            )
            
            ToolButton(
                icon: "line.diagonal",
                isSelected: drawingController.currentTool == .line,
                action: { drawingController.setTool(.line) }
            )
            
            ToolButton(
                icon: "rectangle",
                isSelected: drawingController.currentTool == .rectangle,
                action: { drawingController.setTool(.rectangle) }
            )
            
            ToolButton(
                icon: "circle",
                isSelected: drawingController.currentTool == .circle,
                action: { drawingController.setTool(.circle) }
            )
            
            ToolButton(
                icon: "arrow.up.right",
                isSelected: drawingController.currentTool == .arrow,
                action: { drawingController.setTool(.arrow) }
            )
            
            ToolButton(
                icon: "eraser",
                isSelected: drawingController.currentTool == .eraser,
                action: { drawingController.setTool(.eraser) }
            )
            
            Divider()
                .frame(height: 20)
            
            // Color picker
            ColorPicker("", selection: $drawingController.currentColor)
                .frame(width: 30, height: 30)
            
            Divider()
                .frame(height: 20)
            
            // Action buttons
            Button(action: drawingController.undo) {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(.bordered)
            
            Button(action: drawingController.clearAll) {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            
            Button("Done") {
                // Exit drawing mode
                NotificationCenter.default.post(name: NSNotification.Name("ExitDrawingMode"), object: nil)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ToolButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.bordered)
        .background(isSelected ? Color.accentColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
