import SwiftUI

struct LicensesView: View {
    var body: some View {
        Form {
            Section {
                Text("本アプリの熟語・読み方データは、Electronic Dictionary Research and Development Group（EDRDG）が公開する JMdict/EDICT を基に作成しています。")
                Text("収録しているのは熟語とその読み方のみです。JMdictに含まれる英語の語義（訳語）は、アプリ内の表示には使用していません。")
                Link(destination: KanjiPolicyLinks.jmdictProject) {
                    Label("EDRDG（JMdict配布元）", systemImage: "link")
                }
                Link(destination: KanjiPolicyLinks.ccBySa30) {
                    Label("ライセンス：CC BY-SA 3.0", systemImage: "link")
                }
            } header: {
                Text("辞書データの出典")
            } footer: {
                Text("JMdict/EDICT は Creative Commons 表示-継承 3.0 ライセンス（CC BY-SA 3.0）のもとで提供されています。")
            }
        }
        .navigationTitle("ライセンス・第三者表記")
    }
}
