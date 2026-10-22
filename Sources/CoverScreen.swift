import SwiftUI

struct OrbitMark: View {
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width,proxy.size.height)
            ZStack {
                Circle().fill(OrbitTheme.cyan.opacity(0.06)).frame(width:side*0.8)
                Circle().stroke(OrbitTheme.line,lineWidth:1).frame(width:side*0.8)
                Circle().stroke(OrbitTheme.line.opacity(0.6),style:StrokeStyle(lineWidth:1,dash:[2,9])).frame(width:side*0.98)
                Ellipse().stroke(OrbitTheme.cyan.opacity(0.7),lineWidth:1.2).frame(width:side*0.94,height:side*0.38).rotationEffect(.degrees(-30))
                Ellipse().stroke(OrbitTheme.cyan.opacity(0.2),lineWidth:0.8).frame(width:side*0.94,height:side*0.38).rotationEffect(.degrees(30))
                Circle().fill(OrbitTheme.cyan).frame(width:8,height:8).offset(x:side*0.34,y:-side*0.23).shadow(color:OrbitTheme.cyan.opacity(0.5),radius:12)
                Image(systemName:"chart.xyaxis.line").font(.system(size:side*0.25,weight:.ultraLight)).foregroundStyle(OrbitTheme.cyan)
            }.frame(width:proxy.size.width,height:proxy.size.height)
        }.aspectRatio(1,contentMode:.fit).accessibilityHidden(true)
    }
}
struct CoverScreen: View {
    let enter: () -> Void
    var body: some View {
        ZStack {
            OrbitTheme.background.ignoresSafeArea()
            RadialGradient(colors:[Color(red:0.09,green:0.2,blue:0.27),.clear],center:.init(x:0.7,y:0.3),startRadius:0,endRadius:400).ignoresSafeArea()
            VStack(alignment:.leading,spacing:0) {
                HStack { Text("ORBIT").font(.system(size:14,weight:.medium,design:.monospaced)).tracking(5); Spacer();Text("PERSONAL / 01").font(.system(size:9,design:.monospaced)).foregroundStyle(OrbitTheme.muted) }
                Spacer(minLength:28)
                OrbitMark().frame(maxWidth:340).frame(maxWidth:.infinity)
                Spacer(minLength:30)
                Text("交易观测站").font(.system(size:34,weight:.light)).tracking(2)
                Text("把判断，落到证据。").font(.title3.weight(.light)).foregroundStyle(OrbitTheme.muted).padding(.top,14)
                HStack(spacing:16) { Text("研究");Text("·");Text("验证");Text("·");Text("决策") }.font(.caption).tracking(3).foregroundStyle(OrbitTheme.cyan).padding(.top,22)
                Spacer(minLength:36)
                Button(action:enter) { HStack { Text("进入工作台"); Spacer();Image(systemName:"arrow.right") }.font(.subheadline.weight(.semibold)).padding(19).foregroundStyle(OrbitTheme.background).background(OrbitTheme.cyan,in:RoundedRectangle(cornerRadius:14)) }
                Text("个人研究辅助 · 交易由本人决定").font(.system(size:10)).foregroundStyle(OrbitTheme.muted).frame(maxWidth:.infinity).padding(.top,18)
            }.padding(28)
        }
    }
}
