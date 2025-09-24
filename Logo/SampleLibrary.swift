import SwiftUI

struct LogoSample: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let script: String
    let accent: Color
}

enum SampleCategory: CaseIterable {
    case featured
    case fractals
    case patterns
    case multiTurtle
    case colorBursts
    case functions

    var title: String {
        switch self {
        case .featured: return "精选"
        case .fractals: return "分形"
        case .patterns: return "图案"
        case .multiTurtle: return "多乌龟"
        case .colorBursts: return "色彩"
        case .functions: return "函数"
        }
    }

    var samples: [LogoSample] {
        SampleLibrary.samplesByCategory[self] ?? []
    }
}

private struct RGBColor {
    let r: Int
    let g: Int
    let b: Int

    var swiftUIColor: Color {
        Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

struct SampleLibrary {
    static let samplesByCategory: [SampleCategory: [LogoSample]] = {
        var catalog: [SampleCategory: [LogoSample]] = [:]
        catalog[.featured] = buildFeatured()
        catalog[.fractals] = buildFractals()
        catalog[.patterns] = buildPatterns()
        catalog[.multiTurtle] = buildMultiTurtles()
        catalog[.colorBursts] = buildColorBursts()
        catalog[.functions] = buildFunctions()
        return catalog
    }()
}

private extension SampleLibrary {
    static func buildFeatured() -> [LogoSample] {
        return [
            LogoSample(
                title: "蓝色正方形",
                subtitle: "基础 Logo 图形",
                script: """
                CLEAR
                COLOR 45 130 220
                REPEAT 4 [
                    FORWARD 140
                    RIGHT 90
                ]
                """,
                accent: Color(red: Double(45) / 255, green: Double(130) / 255, blue: Double(220) / 255)
            ),
            LogoSample(
                title: "金色星形",
                subtitle: "五角星旋转",
                script: """
                CLEAR
                COLOR 255 215 0
                REPEAT 5 [
                    FORWARD 160
                    RIGHT 144
                ]
                """,
                accent: Color(red: 1.0, green: Double(215) / 255, blue: 0)
            ),
            LogoSample(
                title: "落日螺旋",
                subtitle: "暖色渐变螺旋",
                script: """
                CLEAR
                MAKE "STEP 6
                MAKE "ANGLE 25
                REPEAT 40 [
                    COLOR 255 140 0
                    FORWARD :STEP
                    RIGHT :ANGLE
                    MAKE "STEP SUM :STEP 2
                    COLOR 255 69 0
                    FORWARD :STEP
                    RIGHT :ANGLE
                    MAKE "ANGLE SUM :ANGLE 0.6
                ]
                """,
                accent: Color(red: 1.0, green: Double(140) / 255, blue: 0)
            ),
            LogoSample(
                title: "花瓣放射",
                subtitle: "彩虹花瓣组合",
                script: """
                CLEAR
                REPEAT 12 [
                    COLOR 148 0 211
                    FORWARD 120
                    BACK 120
                    RIGHT 15
                    COLOR 75 0 130
                    FORWARD 120
                    BACK 120
                    RIGHT 15
                    COLOR 0 0 255
                    FORWARD 120
                    BACK 120
                    RIGHT 15
                    COLOR 0 255 0
                    FORWARD 120
                    BACK 120
                    RIGHT 15
                    COLOR 255 255 0
                    FORWARD 120
                    BACK 120
                    RIGHT 15
                    COLOR 255 127 80
                    FORWARD 120
                    BACK 120
                    RIGHT 15
                ]
                """,
                accent: Color(red: 1.0, green: Double(127) / 255, blue: Double(80) / 255)
            ),
            LogoSample(
                title: "双螺旋",
                subtitle: "对称双臂螺旋",
                script: """
                CLEAR
                MAKE "STEP 5
                REPEAT 48 [
                    COLOR 65 105 225
                    FORWARD :STEP
                    RIGHT 12
                    MAKE "STEP SUM :STEP 1.2
                    COLOR 238 130 238
                    FORWARD :STEP
                    LEFT 24
                ]
                """,
                accent: Color(red: Double(65) / 255, green: Double(105) / 255, blue: Double(225) / 255)
            ),
            LogoSample(
                title: "内嵌方格",
                subtitle: "中心对称方格",
                script: """
                CLEAR
                MAKE "SIZE 160
                REPEAT 8 [
                    COLOR 0 191 255
                    REPEAT 4 [
                        FORWARD :SIZE
                        RIGHT 90
                    ]
                    MAKE "SIZE DIFFERENCE :SIZE 20
                    RIGHT 45
                ]
                """,
                accent: Color(red: 0, green: Double(191) / 255, blue: 1.0)
            ),
            LogoSample(
                title: "阳光风车",
                subtitle: "偏转正方形",
                script: """
                CLEAR
                COLOR 255 160 122
                REPEAT 18 [
                    REPEAT 4 [
                        FORWARD 120
                        RIGHT 90
                    ]
                    RIGHT 20
                ]
                """,
                accent: Color(red: 1.0, green: Double(160) / 255, blue: Double(122) / 255)
            ),
            LogoSample(
                title: "多彩风铃",
                subtitle: "弧形风铃阵列",
                script: """
                CLEAR
                MAKE "BASE 30
                REPEAT 8 [
                    COLOR 255 105 180
                    FORWARD 20
                    RIGHT 20
                    COLOR 255 182 193
                    FORWARD 20
                    RIGHT 20
                    COLOR 255 228 225
                    FORWARD 20
                    RIGHT 20
                    LEFT 60
                    COLOR 0 206 209
                    FORWARD 40
                    BACK 40
                    RIGHT 30
                ]
                """,
                accent: Color(red: 1.0, green: Double(105) / 255, blue: Double(180) / 255)
            ),
            LogoSample(
                title: "星形旋转扇",
                subtitle: "渐变角星扇页",
                script: """
                CLEAR
                REPEAT 24 [
                    COLOR 255 99 71
                    FORWARD 110
                    BACK 110
                    RIGHT 15
                    COLOR 46 139 87
                    FORWARD 90
                    BACK 90
                    RIGHT 15
                ]
                """,
                accent: Color(red: Double(46) / 255, green: Double(139) / 255, blue: Double(87) / 255)
            ),
            LogoSample(
                title: "光环流线",
                subtitle: "环绕曲线",
                script: """
                CLEAR
                MAKE "STEP 2
                REPEAT 120 [
                    COLOR 0 191 255
                    FORWARD :STEP
                    RIGHT 6
                    COLOR 186 85 211
                    FORWARD :STEP
                    LEFT 12
                    MAKE "STEP SUM :STEP 0.4
                ]
                """,
                accent: Color(red: Double(186) / 255, green: Double(85) / 255, blue: Double(211) / 255)
            ),
            LogoSample(
                title: "螺旋花窗",
                subtitle: "十字交叠",
                script: """
                CLEAR
                COLOR 255 20 147
                REPEAT 12 [
                    REPEAT 4 [
                        FORWARD 90
                        RIGHT 90
                    ]
                    RIGHT 30
                    COLOR 30 144 255
                    REPEAT 4 [
                        FORWARD 60
                        RIGHT 90
                    ]
                    RIGHT 30
                ]
                """,
                accent: Color(red: 1.0, green: Double(20) / 255, blue: Double(147) / 255)
            ),
            LogoSample(
                title: "光束花轮",
                subtitle: "径向光束",
                script: """
                CLEAR
                REPEAT 36 [
                    COLOR 255 215 0
                    FORWARD 130
                    BACK 130
                    RIGHT 10
                    COLOR 72 209 204
                    FORWARD 90
                    BACK 90
                    RIGHT 10
                ]
                """,
                accent: Color(red: Double(72) / 255, green: Double(209) / 255, blue: Double(204) / 255)
            ),
            LogoSample(
                title: "多彩羽翼",
                subtitle: "左右对称羽毛",
                script: """
                CLEAR
                MAKE "STEP 8
                REPEAT 45 [
                    COLOR 255 99 71
                    FORWARD :STEP
                    RIGHT 8
                    COLOR 60 179 113
                    FORWARD :STEP
                    LEFT 16
                    MAKE "STEP SUM :STEP 0.5
                ]
                """,
                accent: Color(red: Double(60) / 255, green: Double(179) / 255, blue: Double(113) / 255)
            )
        ]
    }

    static func buildFractals() -> [LogoSample] {
        var samples: [LogoSample] = []
        let kochDepths = [2, 3, 4]
        for (index, depth) in kochDepths.enumerated() {
            let color = rgb(for: index + 10)
            samples.append(
                LogoSample(
                    title: "Koch 雪花 d=\(depth)",
                    subtitle: "经典科赫曲线",
                    script: kochSnowflake(length: 180 - depth * 20, depth: depth, color: color),
                    accent: color.swiftUIColor
                )
            )
        }

        let sierpinskiDepths = [2, 3, 4]
        for (offset, depth) in sierpinskiDepths.enumerated() {
            let color = rgb(for: offset + 20)
            samples.append(
                LogoSample(
                    title: "谢尔宾斯基 d=\(depth)",
                    subtitle: "等边三角分形",
                    script: sierpinskiTriangle(length: 220 / (depth + 1), depth: depth, color: color),
                    accent: color.swiftUIColor
                )
            )
        }

        let treeDepths = [4, 5, 6]
        for (offset, depth) in treeDepths.enumerated() {
            let color = rgb(for: offset + 30)
            samples.append(
                LogoSample(
                    title: "分形树 d=\(depth)",
                    subtitle: "递归树枝",
                    script: fractalTree(length: 110, depth: depth, color: color),
                    accent: color.swiftUIColor
                )
            )
        }

        let hilbertOrders = [2, 3, 4]
        for (offset, order) in hilbertOrders.enumerated() {
            let color = rgb(for: offset + 40)
            samples.append(
                LogoSample(
                    title: "Hilbert 曲线 o=\(order)",
                    subtitle: "空间填充曲线",
                    script: hilbertCurve(length: 18, order: order, color: color),
                    accent: color.swiftUIColor
                )
            )
        }

        let dragonDepths = [8, 9, 10]
        for (offset, depth) in dragonDepths.enumerated() {
            let color = rgb(for: offset + 50)
            samples.append(
                LogoSample(
                    title: "龙形曲线 d=\(depth)",
                    subtitle: "Heighway Dragon",
                    script: dragonCurve(step: 12, depth: depth, color: color),
                    accent: color.swiftUIColor
                )
            )
        }

        return samples
    }

    static func buildPatterns() -> [LogoSample] {
        var samples: [LogoSample] = []
        let baseConfigs: [(Int, Int, Int)] = [
            (6, 80, 30),
            (8, 70, 22),
            (9, 90, 18),
            (10, 90, 14),
            (12, 65, 20),
            (14, 60, 16)
        ]
        var counter = 0
        for config in baseConfigs {
            for variant in 0..<3 {
                let color1 = rgb(for: counter + 60)
                let color2 = rgb(for: counter + 130)
                samples.append(
                    LogoSample(
                        title: "图案 #\(counter + 1)",
                        subtitle: "多边花环",
                        script: patternScript(sides: config.0 + variant, step: config.1 + variant * 8, rotation: config.2 + variant * 2, primary: color1, secondary: color2),
                        accent: color1.swiftUIColor
                    )
                )
                counter += 1
            }
        }
        return samples
    }

    static func buildMultiTurtles() -> [LogoSample] {
        var samples: [LogoSample] = []
        for index in 0..<15 {
            let colors = [rgb(for: 90 + index * 3), rgb(for: 91 + index * 3), rgb(for: 92 + index * 3)]
            samples.append(
                LogoSample(
                    title: "多龟协奏 #\(index + 1)",
                    subtitle: "多乌龟协作绘制",
                    script: multiTurtleScript(index: index, colors: colors),
                    accent: colors.first?.swiftUIColor ?? .orange
                )
            )
        }
        return samples
    }

    static func buildColorBursts() -> [LogoSample] {
        var samples: [LogoSample] = []
        for index in 0..<20 {
            let palette = (0..<5).map { rgb(for: 150 + index * 5 + $0) }
            samples.append(
                LogoSample(
                    title: "色彩爆发 #\(index + 1)",
                    subtitle: "动态色彩扇形",
                    script: colorBurstScript(index: index, palette: palette),
                    accent: palette.first?.swiftUIColor ?? .pink
                )
            )
        }
        return samples
    }

    static func buildFunctions() -> [LogoSample] {
        var samples: [LogoSample] = []
        let lengths = [40, 60, 80, 100]
        var counter = 0
        for len in lengths {
            for sides in [5, 6, 7, 8, 9] {
                let accent = rgb(for: 210 + counter)
                samples.append(
                    LogoSample(
                        title: "函数多边形 #\(counter + 1)",
                        subtitle: "参数化图形",
                        script: functionPolygonScript(length: len, sides: sides, color: accent),
                        accent: accent.swiftUIColor
                    )
                )
                counter += 1
            }
        }
        return samples
    }

    static func rgb(for index: Int) -> RGBColor {
        let r = ((index * 47) % 192) + 64
        let g = ((index * 67 + 30) % 192) + 64
        let b = ((index * 89 + 90) % 192) + 64
        return RGBColor(r: r, g: g, b: b)
    }

    static func kochSnowflake(length: Int, depth: Int, color: RGBColor) -> String {
        """
        CLEAR
        COLOR \(color.r) \(color.g) \(color.b)
        TO KOCH :LEN :DEPTH
            IFELSE EQUAL :DEPTH 0 [
                FORWARD :LEN
            ] [
                MAKE "STEP QUOTIENT :LEN 3
                KOCH :STEP DIFFERENCE :DEPTH 1
                LEFT 60
                KOCH :STEP DIFFERENCE :DEPTH 1
                RIGHT 120
                KOCH :STEP DIFFERENCE :DEPTH 1
                LEFT 60
                KOCH :STEP DIFFERENCE :DEPTH 1
            ]
        END
        PENUP
        SETXY -120 70
        PENDOWN
        REPEAT 3 [
            KOCH \(length) \(depth)
            RIGHT 120
        ]
        """
    }

    static func sierpinskiTriangle(length: Int, depth: Int, color: RGBColor) -> String {
        """
        CLEAR
        COLOR \(color.r) \(color.g) \(color.b)
        TO TRIANGLE :LEN :DEPTH
            IFELSE EQUAL :DEPTH 0 [
                REPEAT 3 [
                    FORWARD :LEN
                    RIGHT 120
                ]
            ] [
                MAKE "STEP QUOTIENT :LEN 2
                TRIANGLE :STEP DIFFERENCE :DEPTH 1
                FORWARD :STEP
                TRIANGLE :STEP DIFFERENCE :DEPTH 1
                BACK :STEP
                RIGHT 60
                FORWARD :STEP
                LEFT 60
                TRIANGLE :STEP DIFFERENCE :DEPTH 1
                LEFT 60
                BACK :STEP
                RIGHT 60
            ]
        END
        PENUP
        SETXY -110 -80
        PENDOWN
        TRIANGLE \(length) \(depth)
        """
    }

    static func fractalTree(length: Int, depth: Int, color: RGBColor) -> String {
        """
        CLEAR
        COLOR \(color.r) \(color.g) \(color.b)
        TO TREE :LEN :DEPTH
            IFELSE LESS :DEPTH 1 [
                FORWARD :LEN
                BACK :LEN
            ] [
                FORWARD :LEN
                RIGHT 25
                TREE PRODUCT :LEN 0.72 DIFFERENCE :DEPTH 1
                LEFT 50
                TREE PRODUCT :LEN 0.72 DIFFERENCE :DEPTH 1
                RIGHT 25
                BACK :LEN
            ]
        END
        PENUP
        SETXY 0 -140
        SETHEADING 90
        PENDOWN
        TREE \(length) \(depth)
        """
    }

    static func hilbertCurve(length: Int, order: Int, color: RGBColor) -> String {
        """
        CLEAR
        COLOR \(color.r) \(color.g) \(color.b)
        TO HLEFT :LEVEL :LEN
            IFELSE EQUAL :LEVEL 0 [ ] [
                LEFT 90
                HRIGHT DIFFERENCE :LEVEL 1 :LEN
                FORWARD :LEN
                LEFT 90
                HLEFT DIFFERENCE :LEVEL 1 :LEN
                FORWARD :LEN
                HLEFT DIFFERENCE :LEVEL 1 :LEN
                LEFT 90
                FORWARD :LEN
                HRIGHT DIFFERENCE :LEVEL 1 :LEN
                LEFT 90
            ]
        END
        TO HRIGHT :LEVEL :LEN
            IFELSE EQUAL :LEVEL 0 [ ] [
                RIGHT 90
                HLEFT DIFFERENCE :LEVEL 1 :LEN
                FORWARD :LEN
                RIGHT 90
                HRIGHT DIFFERENCE :LEVEL 1 :LEN
                FORWARD :LEN
                HRIGHT DIFFERENCE :LEVEL 1 :LEN
                RIGHT 90
                FORWARD :LEN
                HLEFT DIFFERENCE :LEVEL 1 :LEN
                RIGHT 90
            ]
        END
        PENUP
        SETXY -140 -140
        PENDOWN
        HLEFT \(order) \(length)
        """
    }

    static func dragonCurve(step: Int, depth: Int, color: RGBColor) -> String {
        """
        CLEAR
        COLOR \(color.r) \(color.g) \(color.b)
        TO DRAGON :STEP :DEPTH
            IFELSE EQUAL :DEPTH 0 [
                FORWARD :STEP
            ] [
                DRAGON :STEP DIFFERENCE :DEPTH 1
                RIGHT 90
                NOODLE :STEP DIFFERENCE :DEPTH 1
            ]
        END
        TO NOODLE :STEP :DEPTH
            IFELSE EQUAL :DEPTH 0 [
                FORWARD :STEP
            ] [
                DRAGON :STEP DIFFERENCE :DEPTH 1
                LEFT 90
                NOODLE :STEP DIFFERENCE :DEPTH 1
            ]
        END
        PENUP
        SETXY -80 -40
        PENDOWN
        DRAGON \(step) \(depth)
        """
    }

    static func patternScript(sides: Int, step: Int, rotation: Int, primary: RGBColor, secondary: RGBColor) -> String {
        """
        CLEAR
        REPEAT \(sides) [
            COLOR \(primary.r) \(primary.g) \(primary.b)
            REPEAT \(sides) [
                FORWARD \(step)
                RIGHT \(360 / sides)
            ]
            RIGHT \(rotation)
            COLOR \(secondary.r) \(secondary.g) \(secondary.b)
            REPEAT \(sides) [
                FORWARD \(step / 2)
                RIGHT \(360 / sides)
            ]
            RIGHT \(rotation)
        ]
        """
    }

    static func multiTurtleScript(index: Int, colors: [RGBColor]) -> String {
        let offsets = [(-140, -140), (140, -140), (0, 140)]
        var lines: [String] = ["CLEAR"]
        let turtles = ["A", "B", "C"]
        for (idx, turtle) in turtles.enumerated() {
            let color = colors[min(idx, colors.count - 1)]
            let offset = offsets[idx]
            lines.append("TURTLE \(turtle)")
            lines.append("PENUP")
            lines.append("SETXY \(offset.0) \(offset.1)")
            lines.append("SETHEADING \(idx * 120)")
            lines.append("PENDOWN")
            lines.append("COLOR \(color.r) \(color.g) \(color.b)")
            lines.append("REPEAT \(24 + index % 12) [")
            lines.append("    FORWARD \(40 + idx * 10)")
            lines.append("    RIGHT \(10 + idx * 5)")
            lines.append("    FORWARD \(20 + index * 2)")
            lines.append("    LEFT \(20 + idx * 7)")
            lines.append("]")
        }
        lines.append("TURTLE MAIN")
        lines.append("PENUP")
        lines.append("SETXY 0 0")
        lines.append("PENDOWN")
        return lines.joined(separator: "\n")
    }

    static func colorBurstScript(index: Int, palette: [RGBColor]) -> String {
        var lines: [String] = ["CLEAR", "PENUP", "SETXY 0 0", "PENDOWN", "RIGHT \(index * 9)", "MAKE \"STEP 4"]
        lines.append("REPEAT \(36 + (index % 12)) [")
        for color in palette {
            lines.append("    COLOR \(color.r) \(color.g) \(color.b)")
            lines.append("    FORWARD :STEP")
            lines.append("    RIGHT \(10 + index % 6)")
            lines.append("    MAKE \"STEP SUM :STEP 0.3")
        }
        lines.append("]")
        return lines.joined(separator: "\n")
    }

    static func functionPolygonScript(length: Int, sides: Int, color: RGBColor) -> String {
        """
        CLEAR
        TO POLYGON :SIDES :SIZE
            IFELSE LESS :SIDES 3 [ ] [
                MAKE "TURN QUOTIENT 360 :SIDES
                REPEAT :SIDES [
                    FORWARD :SIZE
                    RIGHT :TURN
                ]
            ]
        END
        COLOR \(color.r) \(color.g) \(color.b)
        POLYGON \(sides) \(length)
        RIGHT 15
        COLOR \(color.r) \(max(0, color.g - 40)) \(min(255, color.b + 40))
        POLYGON \(sides + 1) \(length - 10)
        """
    }
}
